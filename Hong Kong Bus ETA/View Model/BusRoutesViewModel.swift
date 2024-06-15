//
//  BusRoutesViewModel.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 21/1/2024.
//

import Combine
import Foundation

@MainActor
protocol BusRoutesViewModelDelegate: AnyObject {

  func busRoutesViewModel(_ viewModel: BusRoutesViewModel, didSelectRoute route: any BusRouteModel)

  func busRoutesViewModel(_ viewModel: BusRoutesViewModel, didUpdateSearchCount count: Int?)

  func busRoutesViewModelDidResetFilter(_ viewModel: BusRoutesViewModel)
}

enum BusRoutesListSource {

  case ctb
  case kmb

  var title: String {
    switch self {
    case .ctb:
      return String(localized: "ctb")
    case .kmb:
      return String(localized: "kmb")
    }
  }

  func getRoutesListPublisher(
    busRouteProvider: BusRoutesDataProviderType = BusRoutesDataProvider.shared
  ) -> AnyPublisher<[any BusRouteModel]?, Never> {

    switch self {
    case .ctb:

      return busRouteProvider.ctbRouteDict.map { dict in
        return dict?.values.map({ value in
          value
        }).sorted(by: { a, b in
          (a.route ?? "") < (b.route ?? "")
        })
      }.eraseToAnyPublisher()

    case .kmb:
      return busRouteProvider.kmbRouteDict.map { dict in
        return dict?.values.map({ value in
          value
        }).sorted(by: { a, b in
          (a.route ?? "") < (b.route ?? "")
        })
      }.eraseToAnyPublisher()
    }

  }

  func fetchData(busRoutesDataProvider: BusRoutesDataProviderType = BusRoutesDataProvider.shared) {
    switch self {
    case .ctb:
      busRoutesDataProvider.fetchCTBRoutes()
    case .kmb:
      busRoutesDataProvider.fetchKMBRoutes()
    }

  }

}

@MainActor
class BusRoutesViewModel: ObservableObject {

  var apiManager: APIManagerType

  @Published
  var filter: String = ""

  @Published
  var routeList: [any BusRouteModel]?

  @Published
  var displayedList: [any BusRouteModel]? = nil

  @Published
  var hasError: Bool = false

  let busRoutesListSource: BusRoutesListSource

  private var lastEnterBackgroundTime: Date?

  weak var delegate: BusRoutesViewModelDelegate?

  private var cancellable = Set<AnyCancellable>()

  init(
    apiManager: APIManagerType = APIManager.shared,
    busRoutesListSource: BusRoutesListSource
  ) {
    self.apiManager = apiManager
    self.busRoutesListSource = busRoutesListSource

    setupPublisher()

  }

  func setupPublisher() {

    $filter.debounce(for: 0.3, scheduler: DispatchQueue.main)
      .combineLatest($routeList).sink { [weak self] filter, routeList in

        guard let self else { return }

        let filterList = filter.lowercased().split(separator: " ").map { s in
          String(s)
        }

        if filterList.count > 0 {
          self.displayedList = routeList?.filterByKeywords(filterList)
        } else {
          self.displayedList = routeList
        }

        if filter.isEmpty {
          delegate?.busRoutesViewModel(self, didUpdateSearchCount: nil)
        } else {
          delegate?.busRoutesViewModel(self, didUpdateSearchCount: displayedList?.count ?? nil)
        }

      }.store(in: &cancellable)

    apiManager.isReachable.dropFirst().sink { [weak self] reachable in
      if let self, reachable, self.routeList?.isEmpty ?? false {
        self.fetch()
      }
    }.store(in: &cancellable)

    self.busRoutesListSource.getRoutesListPublisher().receive(on: DispatchQueue.main).map({
      routeList in

      routeList

    }).assign(to: &$routeList)
  }

  func fetch() {
    routeList = nil
    busRoutesListSource.fetchData()
  }

  func resetFilter() {
    filter = ""
    displayedList = routeList
    delegate?.busRoutesViewModelDidResetFilter(self)
  }

  func onRouteSelected(_ route: any BusRouteModel) {

    delegate?.busRoutesViewModel(self, didSelectRoute: route)
  }

  func onEnterBackground() {
    lastEnterBackgroundTime = Date()
  }

  func onReturnToForeground() {
    if let lastEnterBackgroundTime,
      Date().timeIntervalSince1970 - lastEnterBackgroundTime.timeIntervalSince1970 > 86400
    {
      fetch()
    }

  }
}
