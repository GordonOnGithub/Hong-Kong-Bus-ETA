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

enum Sorting: Int {
  case routeNumber = 0
  case routeNumberInverse = 1
  case addDateEarliest = 2
  case addDateLatest = 3
}

class BusStopETAListViewModel: ObservableObject {

  @Published
  var busStopETAList: [BusStopETA] = []

  @Published
  var sorting: Sorting = .addDateLatest

  let busETAStorage: BusETAStorageType

  let userDefaults: UserDefaultsType

  weak var delegate: BusStopETAListViewModelDelegate?

  private var cancellable = Set<AnyCancellable>()

  private let etaSortingKey = "etaSorting"

  init(
    busETAStorage: BusETAStorageType = BusETAStorage.shared,
    userDefaults: UserDefaultsType = UserDefaults.standard
  ) {
    self.busETAStorage = busETAStorage
    self.userDefaults = userDefaults

    busETAStorage.fetch()

    if let sortingPref = userDefaults.object(forKey: etaSortingKey) as? Int {
      self.sorting = Sorting(rawValue: sortingPref) ?? .addDateLatest
    }

    setupPublisher()
  }

  private func setupPublisher() {

    busETAStorage.cache.combineLatest($sorting).sink { _, sorting in

      self.busETAStorage.cache.map { cache in

        cache.values.sorted { a, b in

          switch sorting {
          case .routeNumber:
            return a.route > b.route

          case .routeNumberInverse:
            return a.route < b.route

          case .addDateEarliest:
            return a.addDate.timeIntervalSince1970 < b.addDate.timeIntervalSince1970

          case .addDateLatest:
            return a.addDate.timeIntervalSince1970 > b.addDate.timeIntervalSince1970

          }

        }

      }
      .receive(on: DispatchQueue.main)
      .assign(to: &self.$busStopETAList)

    }.store(in: &cancellable)

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

  func changeSorting(sorting: Sorting) {

    self.sorting = sorting

    userDefaults.setValue(sorting.rawValue, forKey: etaSortingKey)

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
