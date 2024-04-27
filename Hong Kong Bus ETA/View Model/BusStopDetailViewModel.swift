//
//  BusStopDetailViewModel.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 22/1/2024.
//

import Combine
import Foundation
import UIKit

protocol BusStopDetailViewModelDelegate: AnyObject {

  func busStopDetailViewModel(
    _ viewModel: BusStopDetailViewModel, didRequestBusRouteDetail route: (any BusRouteModel)?)
  func busStopDetailViewModelDidRequestReturnToETAList(
    _ viewModel: BusStopDetailViewModel)

}

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
  var showBookmarkReminder = false

  @Published
  var busFare: BusFareModel? = nil

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

    showBookmarkReminder = userDefaults.object(forKey: showBookmarkReminderKey) as? Bool ?? true

    setupPublisher()

    fetchETA()

    fetchBusStopDetailIfNeeded()
  }

  func fetchBusStopDetailIfNeeded() {

    if busStopDetail != nil { return }

    switch BusCompany(rawValue: busStopETA.company) {
    case .CTB:
      self.apiManager.call(api: .CTBBusStopDetail(stopId: busStopETA.stopId)).receive(
        on: DispatchQueue.main
      )
      .map { data in
        if let data {
          let response = try? JSONDecoder().decode(
            APIResponseModel<CTBBusStopDetailModel>.self, from: data)
          return response?.data
        } else {
          return nil
        }
      }
      .replaceError(with: nil)
      .eraseToAnyPublisher()
      .assign(to: &$busStopDetail)

    case .KMB:
      self.apiManager.call(api: .KMBBusStopDetail(stopId: busStopETA.stopId)).receive(
        on: DispatchQueue.main
      )
      .map { data in
        if let data {
          let response = try? JSONDecoder().decode(
            APIResponseModel<KMBBusStopDetailModel>.self, from: data)
          return response?.data
        } else {
          return nil
        }
      }
      .replaceError(with: nil)
      .eraseToAnyPublisher()
      .assign(to: &$busStopDetail)

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
        self?.fetchETA()
      }
    }.store(in: &cancellable)

    Timer.publish(every: 30, on: .main, in: .default).autoconnect().sink { [weak self] _ in
      self?.fetchETA()
    }.store(in: &cancellable)

    switch BusCompany(rawValue: busStopETA.company) {
    case .CTB:
      busRoutesDataProvider.ctbRouteDict.sink { [weak self] cache in

        guard let self, let cache else { return }

        let key = busRoutesDataProvider.getCacheKey(
          company: .CTB, route: self.busStopETA.route, serviceType: nil,
          isInbound: self.busStopETA.isInbound)

        if let route = cache[key] {
          self.busRoute = route
        }

      }.store(in: &cancellable)
    case .KMB:
      busRoutesDataProvider.kmbRouteDict.sink { [weak self] cache in

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

    busRoutesDataProvider.busFareDict.map { [weak self] dict -> BusFareModel? in

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

  }

  func fetchETA() {

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

    apiManager.call(api: .CTBArrivalEstimation(stopId: stopId, route: route)).sink {
      [weak self] completion in

      switch completion {
      case .failure(let error):
        self?.busETAList = []
      default:
        break
      }
      self?.lastUpdatedTimestamp = Date()

    } receiveValue: { [weak self] data in

      if let self, let data,
        let response = try? JSONDecoder().decode(APIResponseModel<[BusETAModel]>.self, from: data)
      {

        self.busETAList = response.data.sorted(by: { a, b in

          (a.etaTimestamp?.timeIntervalSince1970 ?? 0)
            < (b.etaTimestamp?.timeIntervalSince1970 ?? 0)
        })
      }

    }.store(in: &cancellable)

  }

  func fetchKMBETA(stopId: String, route: String, serviceType: String?) {

    apiManager.call(
      api: .KMBArrivalEstimation(stopId: stopId, route: route, serviceType: serviceType ?? "")
    ).sink { [weak self] completion in

      switch completion {
      case .failure(let error):
        self?.busETAList = []
      default:
        break
      }
      self?.lastUpdatedTimestamp = Date()

    } receiveValue: { [weak self] data in

      if let self, let data,
        let response = try? JSONDecoder().decode(APIResponseModel<[BusETAModel]>.self, from: data)
      {
        self.busETAList = response.data.sorted(by: { a, b in

          (a.etaTimestamp?.timeIntervalSince1970 ?? 0)
            < (b.etaTimestamp?.timeIntervalSince1970 ?? 0)
        })
      }

    }.store(in: &cancellable)

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

      busETAStorage.delete(data: busStopETA)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] success in
          if success {
            self?.isSaved = false

          }
        }.store(in: &cancellable)

    } else {
      busETAStorage.insert(data: busStopETA)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] success in

          guard let self else { return }

          if success {
            self.isSaved = true
            self.delegate?.busStopDetailViewModelDidRequestReturnToETAList(self)
            self.userDefaults.setValue(false, forKey: self.showBookmarkReminderKey)
          }
        }.store(in: &cancellable)

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
}
