//
//  RoutesTabViewModel.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 15/6/2024.
//

import Combine
import Foundation

protocol RoutesTabViewModelDelegate: AnyObject {

  func routesTabViewModel(_ viewModel: RoutesTabViewModel, didSelectRoute route: any BusRouteModel)

}

class RoutesTabViewModel: ObservableObject {

  @Published
  var selectedTab: SelectedRouteTab = SelectedRouteTab.ctb

  @Published
  var filter: String = ""

  @Published
  var searchResult: [BusRoutesListSource: Int] = [:]

  let userDefaults: UserDefaultsType

  weak var delegate: RoutesTabViewModelDelegate?

  lazy var ctbRouteListViewModel: BusRoutesViewModel = {

    let vm = BusRoutesViewModel(busRoutesListSource: .ctb)
    vm.delegate = self

    return vm

  }()

  lazy var kmbRouteListViewModel: BusRoutesViewModel = {

    let vm = BusRoutesViewModel(busRoutesListSource: .kmb)
    vm.delegate = self
    return vm

  }()

  private var cancellable = Set<AnyCancellable>()

  init(userDefaults: UserDefaultsType = UserDefaults.standard) {

    self.userDefaults = userDefaults

    $filter.sink { [weak self] filter in

      guard let self else { return }

      self.ctbRouteListViewModel.filter = filter
      self.kmbRouteListViewModel.filter = filter

    }.store(in: &cancellable)

  }

}

extension RoutesTabViewModel: BusRoutesViewModelDelegate {
  func busRoutesViewModelDidResetFilter(_ viewModel: BusRoutesViewModel) {
    filter = ""
  }

  func busRoutesViewModel(_ viewModel: BusRoutesViewModel, didUpdateSearchCount count: Int?) {
    searchResult[viewModel.busRoutesListSource] = count

  }

  func busRoutesViewModel(_ viewModel: BusRoutesViewModel, didSelectRoute route: any BusRouteModel)
  {
    delegate?.routesTabViewModel(self, didSelectRoute: route)
  }

}
