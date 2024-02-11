//
//  BusStopETAListViewModel.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 26/1/2024.
//

import Combine
import Foundation

protocol BusStopETAListViewModelDelegate: AnyObject {

  func busStopETAListViewModelModel(
    _ viewModel: BusStopETAListViewModel, didRequestDisplayBusStopDetailForRoute route: String,
    company: BusCompany, stopId: String, serviceType: String?, isInbound: Bool,
    detail: (any BusStopDetailModel)?)

  func busStopETAListViewModelModel(
    _ viewModel: BusStopETAListViewModel, didRequestDisplayBusRoutes company: BusCompany)
}

class BusStopETAListViewModel: ObservableObject {

  @Published
  var busStopETAList: [BusStopETA] = []

  let busETAStorage: BusETAStorageType

  weak var delegate: BusStopETAListViewModelDelegate?

  private var cancellable = Set<AnyCancellable>()

  init(busETAStorage: BusETAStorageType = BusETAStorage.shared) {
    self.busETAStorage = busETAStorage

    busETAStorage.fetch()

    setupPublisher()
  }

  private func setupPublisher() {

    busETAStorage.cache.map { cache in

      cache.values.sorted { a, b in
        a.route > b.route
      }

    }
    .receive(on: DispatchQueue.main)
    .assign(to: &$busStopETAList)

  }

  func buildBookmarkedBusStopETARowViewModel(busStopETA: BusStopETA)
    -> BookmarkedBusStopETARowViewModel
  {

    let vm = BookmarkedBusStopETARowViewModel(busStopETA: busStopETA)

    vm.delegate = self

    return vm

  }

  func onSearchCTBRoutesButtonClicked() {
    delegate?.busStopETAListViewModelModel(self, didRequestDisplayBusRoutes: .CTB)
  }

  func onSearchKMBRoutesButtonClicked() {
    delegate?.busStopETAListViewModelModel(self, didRequestDisplayBusRoutes: .KMB)
  }
}

extension BusStopETAListViewModel: BookmarkedBusStopETARowViewModelDelegate {
  func bookmarkedBusStopETARowViewModel(
    _ viewModel: BookmarkedBusStopETARowViewModel,
    didRequestDisplayBusStopDetailForRoute route: String, company: BusCompany, stopId: String,
    serviceType: String?, isInbound: Bool, detail: (any BusStopDetailModel)?
  ) {

    delegate?.busStopETAListViewModelModel(
      self, didRequestDisplayBusStopDetailForRoute: route, company: company, stopId: stopId,
      serviceType: serviceType, isInbound: isInbound, detail: detail)

  }

}
