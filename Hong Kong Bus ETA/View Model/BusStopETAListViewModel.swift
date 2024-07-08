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

  @Published
  var showRatingReminder = false

  let busETAStorage: BusETAStorageType

  let userDefaults: UserDefaultsType

  let storeReviewController: SKStoreReviewControllerInjectableType

  weak var delegate: BusStopETAListViewModelDelegate?

  private var cancellable = Set<AnyCancellable>()

  private let etaSortingKey = "etaSorting"

  private let showRatingReminderKey = "showRatingReminder"

  private let appLaunchCountKey = "appLaunchCount"

  private var bookmarkedBusStopETARowViewModelDict: [BusStopETA: BookmarkedBusStopETARowViewModel] =
    [:]

  private let showETAListKey = "showETAListTip"

  init(
    busETAStorage: BusETAStorageType = BusETAStorage.shared,
    userDefaults: UserDefaultsType = UserDefaults.standard,
    storeReviewController: SKStoreReviewControllerInjectableType =
      SKStoreReviewControllerInjectable()
  ) {
    self.busETAStorage = busETAStorage
    self.userDefaults = userDefaults
    self.storeReviewController = storeReviewController

    busETAStorage.fetch()

    if let sortingPref = userDefaults.object(forKey: etaSortingKey) as? Int {
      self.sorting = Sorting(rawValue: sortingPref) ?? .addDateLatest
    }

    let appOpenCount = userDefaults.object(forKey: appLaunchCountKey) as? Int ?? 0

    if appOpenCount > 2 {
      self.showRatingReminder = userDefaults.object(forKey: showRatingReminderKey) as? Bool ?? true
    }

    userDefaults.setValue(appOpenCount + 1, forKey: appLaunchCountKey)

    let showETAListTip = userDefaults.object(forKey: showETAListKey) as? Bool ?? true
    ETAListTip.showETAListTip = showETAListTip

    if showETAListTip {
      self.userDefaults.setValue(false, forKey: showETAListKey)
    }

    setupPublisher()
  }

  private func setupPublisher() {

    busETAStorage.cache.combineLatest($sorting).sink { _, sorting in

      self.bookmarkedBusStopETARowViewModelDict.removeAll()

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
    guard let vm = bookmarkedBusStopETARowViewModelDict[busStopETA] else {

      let vm = BookmarkedBusStopETARowViewModel(busStopETA: busStopETA)

      vm.delegate = self

      bookmarkedBusStopETARowViewModelDict[busStopETA] = vm

      return vm
    }

    return vm

  }

  func fetchAllETAs() {

    for vm in bookmarkedBusStopETARowViewModelDict.values {
      vm.fetchETA()
    }

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

  func onRatingButtonClicked() {

    storeReviewController.requestReview()

    userDefaults.setValue(false, forKey: showRatingReminderKey)

    showRatingReminder = false
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
