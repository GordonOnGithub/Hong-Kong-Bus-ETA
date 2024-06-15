//
//  BusStopDetailViewModel.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 22/1/2024.
//

import Combine
import Foundation
@preconcurrency import MapKit
import UIKit

@MainActor
protocol BusStopDetailViewModelDelegate: AnyObject {

  func busStopDetailViewModel(
    _ viewModel: BusStopDetailViewModel, didRequestBusRouteDetail route: (any BusRouteModel)?)
  func busStopDetailViewModelDidRequestReturnToETAList(
    _ viewModel: BusStopDetailViewModel)

}

@MainActor
class BusStopDetailViewModel: ObservableObject {

  @Published
  var busStopDetail: (any BusStopDetailModel)?

  @Published
  var busRoute: (any BusRouteModel)?

  let busStopETA: BusStopETA

  let apiManager: APIManagerType

  @Published
  var busETAList: [BusETAModel]? = nil

  @Published
  var lastUpdatedTimestamp: Date?

  @Published
  var isSaved: Bool = false

  @Published
  var showNetworkUnavailableWarning = false

  @Published
  var busFare: BusRouteSummaryModel? = nil

  @Published
  var lookAroundScene: MKLookAroundScene? = nil

  @Published
  var showMap = true

  @Published
  var encounteredError = false

  weak var delegate: (any BusStopDetailViewModelDelegate)?

  let busETAStorage: BusETAStorageType

  let busRoutesDataProvider: BusRoutesDataProviderType

  let application: UIApplicationType

  let userDefaults: UserDefaultsType

  private let showBookmarkReminderKey = "showBookmarkReminder"

  private var cancellable = Set<AnyCancellable>()

  init(
    busStopETA: BusStopETA, apiManager: APIManagerType = APIManager.shared,
    busETAStorage: BusETAStorageType = BusETAStorage.shared,
    busRoutesDataProvider: BusRoutesDataProviderType = BusRoutesDataProvider.shared,
    application: UIApplicationType = UIApplication.shared,
    userDefaults: UserDefaultsType = UserDefaults.standard
  ) {

    self.busStopETA = busStopETA
    self.busETAStorage = busETAStorage
    self.apiManager = apiManager
    self.busRoutesDataProvider = busRoutesDataProvider
    self.application = application
    self.userDefaults = userDefaults

    isSaved = busETAStorage.cache.value[self.busStopETA.id] != nil

    let showBookmarkReminder = userDefaults.object(forKey: showBookmarkReminderKey) as? Bool ?? true

    BookmarkTip.showBookmarkTip = showBookmarkReminder

    if showBookmarkReminder {
      self.userDefaults.setValue(false, forKey: showBookmarkReminderKey)
    }

    setupPublisher()

    fetchETA()

    fetchBusStopDetailIfNeeded()
  }

  func getMapScenePreview() {

    guard let busStopDetail, let latitude = Double(busStopDetail.position?.0 ?? ""),
      let longitude = Double(busStopDetail.position?.1 ?? "")
    else {

      return
    }

    Task {

      let sceneRequest = MKLookAroundSceneRequest(
        coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))

      lookAroundScene = try? await sceneRequest.scene
    }
  }

  func fetchBusStopDetailIfNeeded() {

    if busStopDetail != nil { return }

    encounteredError = false

    switch BusCompany(rawValue: busStopETA.company) {
    case .CTB:
      Task {
        do {
          guard
            let data = try await apiManager.call(api: .CTBBusStopDetail(stopId: busStopETA.stopId)),
            let response = try? JSONDecoder().decode(
              APIResponseModel<CTBBusStopDetailModel>.self, from: data)
          else {
            busStopDetail = nil
            return
          }

          busStopDetail = response.data

        } catch {

          busStopDetail = nil
          encounteredError = true
        }
      }

    case .KMB:

      Task {
        do {
          guard
            let data = try await apiManager.call(api: .KMBBusStopDetail(stopId: busStopETA.stopId)),
            let response = try? JSONDecoder().decode(
              APIResponseModel<KMBBusStopDetailModel>.self, from: data)
          else {
            busStopDetail = nil
            return
          }

          busStopDetail = response.data

        } catch {

          busStopDetail = nil
          encounteredError = true
        }
      }

    case .none:
      break
    }
  }

  private func setupPublisher() {

    apiManager.isReachable.map({ isReachable in
      return !isReachable
    }).assign(to: &$showNetworkUnavailableWarning)

    apiManager.isReachable.dropFirst().sink { [weak self] reachable in
      if reachable {
        self?.fetchBusStopDetailIfNeeded()
        self?.fetchETA()
      }
    }.store(in: &cancellable)

    Timer.publish(every: 30, on: .main, in: .default).autoconnect().sink { [weak self] _ in
      self?.fetchETA()
    }.store(in: &cancellable)

    switch BusCompany(rawValue: busStopETA.company) {
    case .CTB:
      busRoutesDataProvider.ctbRouteDict
        .receive(on: DispatchQueue.main)
        .sink { [weak self] cache in

          guard let self, let cache else { return }

          let key = busRoutesDataProvider.getCacheKey(
            company: .CTB, route: self.busStopETA.route, serviceType: nil,
            isInbound: self.busStopETA.isInbound)

          if let route = cache[key] {
            self.busRoute = route
          }

        }.store(in: &cancellable)
    case .KMB:
      busRoutesDataProvider.kmbRouteDict
        .receive(on: DispatchQueue.main)
        .sink { [weak self] cache in

          guard let self, let cache else { return }

          let key = busRoutesDataProvider.getCacheKey(
            company: .KMB, route: self.busStopETA.route, serviceType: self.busStopETA.serviceType,
            isInbound: self.busStopETA.isInbound)

          if let route = cache[key] {
            self.busRoute = route
          }

        }.store(in: &cancellable)
    default:
      break
    }

    busRoutesDataProvider.busRouteSummaryDict.receive(on: DispatchQueue.main).map {
      [weak self] dict -> BusRouteSummaryModel? in

      guard let dict, let route = self?.busRoute, let companyCode = route.company?.rawValue,
        let routeNumber = route.route
      else { return nil }

      let key = "\(companyCode)_\(routeNumber)"

      if let busFare = dict[key] {
        return busFare
      }

      for value in dict.values {

        if value.companyCode.contains(companyCode), value.routeNumber == routeNumber {
          return value
        }

      }

      return nil

    }.assign(to: &$busFare)

    $busStopDetail.sink { [weak self] detail in
      if detail != nil {
        self?.getMapScenePreview()
      }
    }.store(in: &cancellable)
  }

  func fetchETA() {

    encounteredError = false

    switch BusCompany(rawValue: busStopETA.company) {
    case .CTB:
      fetchCTBETA(stopId: busStopETA.stopId, route: busStopETA.route)

    case .KMB:
      fetchKMBETA(
        stopId: busStopETA.stopId, route: busStopETA.route, serviceType: busStopETA.serviceType)

    case .none:
      break
    }

  }

  func fetchCTBETA(stopId: String, route: String) {

    Task {
      do {
        guard
          let data = try await apiManager.call(
            api: .CTBArrivalEstimation(stopId: stopId, route: route)),
          let response = try? JSONDecoder().decode(APIResponseModel<[BusETAModel]>.self, from: data)
        else {
          if busETAList == nil {
            busETAList = []
          }
          lastUpdatedTimestamp = Date()

          return
        }

        busETAList = response.data.sorted(by: { a, b in

          (a.etaTimestamp?.timeIntervalSince1970 ?? 0)
            < (b.etaTimestamp?.timeIntervalSince1970 ?? 0)
        })
        lastUpdatedTimestamp = Date()

      } catch {
        if busETAList == nil {
          busETAList = []
        }
        encounteredError = true
        lastUpdatedTimestamp = Date()
      }
    }

  }

  func fetchKMBETA(stopId: String, route: String, serviceType: String?) {

    Task {
      do {
        guard
          let data = try await apiManager.call(
            api: .KMBArrivalEstimation(stopId: stopId, route: route, serviceType: serviceType ?? "")
          ),
          let response = try? JSONDecoder().decode(APIResponseModel<[BusETAModel]>.self, from: data)
        else {
          if busETAList == nil {
            busETAList = []
          }
          lastUpdatedTimestamp = Date()
          return
        }

        busETAList = response.data.sorted(by: { a, b in

          (a.etaTimestamp?.timeIntervalSince1970 ?? 0)
            < (b.etaTimestamp?.timeIntervalSince1970 ?? 0)
        })
        lastUpdatedTimestamp = Date()

      } catch {
        if busETAList == nil {
          busETAList = []
        }
        encounteredError = true
        lastUpdatedTimestamp = Date()
      }
    }

  }

  func getRouteName() -> String {

    return
      (busStopETA.company == "KMB"
      ? BusCompany.KMB.localizedName() : BusCompany.CTB.localizedName()) + " " + busStopETA.route
  }

  func getBusStopName() -> String {

    return busStopDetail?.localizedName() ?? ""
  }

  func onSaveButtonClicked() {
    if isSaved {

      do {
        try busETAStorage.delete(data: busStopETA)
        self.isSaved = false
      } catch {
        print(error)
      }

    } else {
      do {
        try busETAStorage.insert(data: busStopETA)
        self.isSaved = true
        self.delegate?.busStopDetailViewModelDidRequestReturnToETAList(self)
      } catch {
        print(error)
      }

    }
  }

  func getDestinationDescription() -> String {
    return String(localized: "to") + (busRoute?.destination() ?? "")
  }

  func openMapApp() {

    guard let busStopDetail,
      let latitude = Double(busStopDetail.position?.0 ?? ""),
      let longitude = Double(busStopDetail.position?.1 ?? "")
    else { return }

    if let url = URL(string: "comgooglemaps://?saddr=&daddr=\(latitude),\(longitude)"),
      application.canOpenURL(url)
    {
      application.openURL(url)
    } else if let url = URL(string: "maps://?saddr=&daddr=\(latitude),\(longitude)"),
      application.canOpenURL(url)
    {
      application.openURL(url)
    }

  }

  func showBusRouteDetail() {
    delegate?.busStopDetailViewModel(self, didRequestBusRouteDetail: self.busRoute)
  }

  func fetchAllData() {
    encounteredError = false
    busETAList = nil
    fetchBusStopDetailIfNeeded()
    fetchETA()
  }
}
