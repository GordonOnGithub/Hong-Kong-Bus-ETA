//
//  BusRoutesViewModel.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 21/1/2024.
//

import Combine
import Foundation

protocol BusRoutesViewModelDelegate: AnyObject {

  func busRoutesViewModel(_ viewModel: BusRoutesViewModel, didSelectRoute route: any BusRouteModel)

}

enum BusRoutesListSource {

  case ctb
  case kmb

  var title: String {
    switch self {
    case .ctb:
      return "CTB"
    case .kmb:
      return "KMB"
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

class BusRoutesViewModel: ObservableObject {

  var apiManager: APIManagerType

  @Published
  var filter: String = ""

  @Published
  var routeList: [any BusRouteModel]?

  @Published
  var displayedList: [any BusRouteModel]? = nil

  let busRoutesListSource: BusRoutesListSource

  weak var delegate: BusRoutesViewModelDelegate?

  private var cancellable = Set<AnyCancellable>()

  init(
    apiManager: APIManagerType = APIManager.shared,
    busRoutesListSource: BusRoutesListSource
  ) {
    self.apiManager = apiManager
    self.busRoutesListSource = busRoutesListSource

    setupPublisher()

    busRoutesListSource.fetchData()
  }

  func setupPublisher() {

    self.busRoutesListSource.getRoutesListPublisher().map({ routeList in

      routeList

    }).assign(to: &$routeList)

    $filter.debounce(for: 0.3, scheduler: DispatchQueue.main)
      .combineLatest($routeList).sink { filter, routeList in

        let filterList = filter.lowercased().split(separator: " ").map { s in
          String(s)
        }

        if filterList.count > 0 {
          self.displayedList = routeList?.filterByKeywords(filterList)
        } else {
          self.displayedList = routeList
        }

      }.store(in: &cancellable)

  }

  func onRouteSelected(_ route: any BusRouteModel) {

    delegate?.busRoutesViewModel(self, didSelectRoute: route)
  }

}
