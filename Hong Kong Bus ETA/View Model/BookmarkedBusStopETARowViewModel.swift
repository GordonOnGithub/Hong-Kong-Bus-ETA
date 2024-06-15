//
//  BookmarkedBusStopETARowViewModel.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 26/1/2024.
//

import Combine
import Foundation

@MainActor
protocol BookmarkedBusStopETARowViewModelDelegate: AnyObject {

  func bookmarkedBusStopETARowViewModel(
    _ viewModel: BookmarkedBusStopETARowViewModel,
    didRequestDisplayBusStopDetailForRoute route: String, company: BusCompany, stopId: String,
    serviceType: String?, isInbound: Bool, detail: (any BusStopDetailModel)?)
}
@MainActor
class BookmarkedBusStopETARowViewModel: ObservableObject {

  @Published
  var busStopDetail: (any BusStopDetailModel)?

  @Published
  var busRoute: (any BusRouteModel)?

  @Published
  var busETAList: [BusETAModel]? = nil

  let busStopETA: BusStopETA

  let apiManager: APIManagerType

  let busRoutesDataProvider: BusRoutesDataProviderType

  weak var delegate: BookmarkedBusStopETARowViewModelDelegate?

  private var cancellable = Set<AnyCancellable>()

  @Published
  var isFetchingETA = false

  init(
    busStopETA: BusStopETA, apiManager: APIManagerType = APIManager.shared,
    busRoutesDataProvider: BusRoutesDataProviderType = BusRoutesDataProvider.shared
  ) {

    self.busStopETA = busStopETA
    self.apiManager = apiManager
    self.busRoutesDataProvider = busRoutesDataProvider

    fetchBusStopDetailIfNeeded()

    fetchETA()

    setupPublisher()
  }

  func fetchBusStopDetailIfNeeded() {

    if busStopDetail != nil { return }

    switch BusCompany(rawValue: busStopETA.company) {
    case .CTB:

      Task {
        do {
          guard
            let data = try await self.apiManager.call(
              api: .CTBBusStopDetail(stopId: busStopETA.stopId)),
            let response = try? JSONDecoder().decode(
              APIResponseModel<CTBBusStopDetailModel>.self, from: data)
          else {

            busStopDetail = nil

            return
          }

          busStopDetail = response.data

        } catch {
          busStopDetail = nil
        }
      }

    case .KMB:

      Task {
        do {
          guard
            let data = try await self.apiManager.call(
              api: .KMBBusStopDetail(stopId: busStopETA.stopId)),
            let response = try? JSONDecoder().decode(
              APIResponseModel<KMBBusStopDetailModel>.self, from: data)
          else {

            busStopDetail = nil
            return
          }

          busStopDetail = response.data

        } catch {
          busStopDetail = nil
        }
      }

    case .none:
      break
    }
  }

  private func setupPublisher() {
    Timer.publish(every: 30, on: .main, in: .default).autoconnect().sink { [weak self] _ in
      self?.fetchETA()
    }.store(in: &cancellable)

    switch BusCompany(rawValue: busStopETA.company) {
    case .CTB:
      busRoutesDataProvider.ctbRouteDict.receive(on: DispatchQueue.main).sink { [weak self] cache in

        guard let self, let cache else { return }

        let key = busRoutesDataProvider.getCacheKey(
          company: .CTB, route: self.busStopETA.route, serviceType: nil,
          isInbound: self.busStopETA.isInbound)

        if let route = cache[key] {
          self.busRoute = route
        }

      }.store(in: &cancellable)
    case .KMB:
      busRoutesDataProvider.kmbRouteDict.receive(on: DispatchQueue.main).sink { [weak self] cache in

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

    apiManager.isReachable.dropFirst().sink { [weak self] reachable in
      if reachable {
        self?.fetchETA()
        self?.fetchBusStopDetailIfNeeded()
      }
    }.store(in: &cancellable)
  }
  func fetchETA() {

    if isFetchingETA {
      return
    }

    isFetchingETA = true

    busETAList = nil

    switch BusCompany(rawValue: busStopETA.company) {
    case .CTB:
      fetchCTBETA(stopId: busStopETA.stopId, route: busStopETA.route)

    case .KMB:
      fetchKMBETA(
        stopId: busStopETA.stopId, route: busStopETA.route, serviceType: busStopETA.serviceType)

    case .none:
      isFetchingETA = false
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

          isFetchingETA = false
          if busETAList == nil {
            busETAList = []
          }
          return
        }

        busETAList = response.data.sorted(by: { a, b in

          (a.etaTimestamp?.timeIntervalSince1970 ?? 0)
            < (b.etaTimestamp?.timeIntervalSince1970 ?? 0)
        })
        isFetchingETA = false

      } catch {
        isFetchingETA = false
        if busETAList == nil {
          busETAList = []
        }
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

          isFetchingETA = false
          if busETAList == nil {
            busETAList = []
          }

          return
        }

        busETAList = response.data.sorted(by: { a, b in

          (a.etaTimestamp?.timeIntervalSince1970 ?? 0)
            < (b.etaTimestamp?.timeIntervalSince1970 ?? 0)
        })
        isFetchingETA = false

      } catch {
        isFetchingETA = false
        if busETAList == nil {
          busETAList = []
        }
      }
    }

  }

  func getBusStopName() -> String {

    return busStopDetail?.localizedName() ?? ""

  }

  func getDestinationDescription() -> String {
    return String(localized: "to") + (busRoute?.destination() ?? "")
  }

  func onRowClicked() {
    if let busRoute, let delegate, let company = BusCompany(rawValue: busStopETA.company) {

      delegate.bookmarkedBusStopETARowViewModel(
        self, didRequestDisplayBusStopDetailForRoute: busStopETA.route, company: company,
        stopId: busStopETA.stopId, serviceType: busStopETA.serviceType,
        isInbound: busStopETA.isInbound, detail: self.busStopDetail)
    }

  }
}
