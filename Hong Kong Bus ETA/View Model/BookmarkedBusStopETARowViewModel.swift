//
//  BookmarkedBusStopETARowViewModel.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 26/1/2024.
//

import Combine
import Foundation

protocol BookmarkedBusStopETARowViewModelDelegate: AnyObject {

  func bookmarkedBusStopETARowViewModel(
    _ viewModel: BookmarkedBusStopETARowViewModel,
    didRequestDisplayBusStopDetailForRoute route: String, company: BusCompany, stopId: String,
    serviceType: String?, isInbound: Bool, detail: (any BusStopDetailModel)?)
}

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

    apiManager.isReachable.dropFirst().sink { [weak self] reachable in
      if reachable {
        self?.fetchETA()
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

    apiManager.call(api: .CTBArrivalEstimation(stopId: stopId, route: route)).sink {
      [weak self] completion in

      switch completion {
      case .failure(let error):
        self?.busETAList = []
      default:
        break
      }

      self?.isFetchingETA = false

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

      self?.isFetchingETA = false

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
