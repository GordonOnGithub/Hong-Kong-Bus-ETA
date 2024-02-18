//
//  RootCoordinator.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 21/1/2024.
//

import Combine
import Foundation
import SwiftUI

enum RootCoordinatorSheetRoute: Identifiable {
  case busStopDetail(
    route: String, company: BusCompany, stopId: String, serviceType: String?, isInbound: Bool,
    detail: (any BusStopDetailModel)?)

  var id: String {

    switch self {
    case .busStopDetail:
      return "busStopDetail"
    }
  }

}

enum RootCoordinatorNavigationPath: Identifiable, Hashable {

  case routeDetail(route: any BusRouteModel)

  var id: String {

    switch self {
    case .routeDetail:
      return "routeDetail"
    }
  }

  func hash(into hasher: inout Hasher) {
    switch self {
    case .routeDetail(let route):
      hasher.combine(route.id)
      hasher.combine(self.id)
    }
  }

  static func == (lhs: RootCoordinatorNavigationPath, rhs: RootCoordinatorNavigationPath) -> Bool {
    switch (lhs, rhs) {
    case (.routeDetail(let routeA), .routeDetail(let routeB)):
      return routeA.id == routeB.id
    }
  }
}

enum Tab: String, Hashable {
  case ETA = "eta"
  case CTB = "ct"
  case KMB = "kmb"
  case info = "info"
}

class RootCoordinator: ObservableObject {

  @Published
  var tab: Tab = .ETA

  @Published
  var path = NavigationPath()

  @Published
  var sheetRoute: RootCoordinatorSheetRoute?

  @Published
  var showNetworkUnavailableWarning = false

  private weak var busStopETAListViewModel: BusStopETAListViewModel?
  private weak var ctbBusRoutesViewModel: BusRoutesViewModel?
  private weak var kmbBusRoutesViewModel: BusRoutesViewModel?

  private var cancellable: Set<AnyCancellable> = Set()

  init(apiManager: APIManagerType = APIManager.shared) {

    apiManager.isReachable.map({ isReachable in
      return !isReachable
    }).assign(to: &$showNetworkUnavailableWarning)
  }

  func buildCTBRouteListViewModel() -> BusRoutesViewModel {

    guard let ctbBusRoutesViewModel else {

      let vm = BusRoutesViewModel(busRoutesListSource: .ctb)
      vm.delegate = self
      ctbBusRoutesViewModel = vm
      return vm
    }

    return ctbBusRoutesViewModel
  }

  func buildKMBRouteListViewModel() -> BusRoutesViewModel {

    guard let kmbBusRoutesViewModel else {

      let vm = BusRoutesViewModel(busRoutesListSource: .kmb)
      vm.delegate = self
      kmbBusRoutesViewModel = vm
      return vm
    }

    return kmbBusRoutesViewModel
  }

  func buildRouteDetailView(route: any BusRouteModel) -> some View {

    let vm = BusRouteDetailViewModel(route: route)
    vm.delegate = self
    return BusRouteDetailView(viewModel: vm)

  }

  func buildETAListViewModel() -> BusStopETAListViewModel {

    guard let busStopETAListViewModel else {
      let vm = BusStopETAListViewModel()
      vm.delegate = self
      busStopETAListViewModel = vm
      return vm
    }

    return busStopETAListViewModel
  }

  func buildBusStopDetailView(
    route: String, company: BusCompany, stopId: String, serviceType: String?, isInbound: Bool,
    detail: (any BusStopDetailModel)?
  ) -> some View {

    let storage = BusETAStorage.shared

    let vm = BusStopDetailViewModel(
      busStopETA: BusStopETA(
        stopId: stopId, route: route, company: company.rawValue, serviceType: serviceType,
        isInbound: isInbound))

    vm.delegate = self

    vm.busStopDetail = detail

    return BusStopDetailView(viewModel: vm)

  }

}

extension RootCoordinator: BusRoutesViewModelDelegate {
  func busRoutesViewModel(_ viewModel: BusRoutesViewModel, didSelectRoute route: any BusRouteModel)
  {
    path.append(RootCoordinatorNavigationPath.routeDetail(route: route))
  }

}

extension RootCoordinator: BusRouteDetailViewModelDelegate {
  func busRouteDetailViewModel(
    _ viewModel: BusRouteDetailViewModel, didRequestDisplayBusStop busStop: any BusStopModel,
    isInbound: Bool, withDetails details: any BusStopDetailModel
  ) {

    guard let routeCode = busStop.route, let stopId = busStop.stopId else { return }

    var serviceType: String? = ""

    if let busStop = busStop as? KMBBusStopModel {
      serviceType = busStop.serviceType
    }

    sheetRoute = .busStopDetail(
      route: routeCode, company: busStop.company, stopId: stopId, serviceType: serviceType,
      isInbound: isInbound, detail: details)
  }

}

extension RootCoordinator: BusStopETAListViewModelDelegate {

  func busStopETAListViewModelModel(
    _ viewModel: BusStopETAListViewModel, didRequestDisplayBusStopDetailForRoute route: String,
    company: BusCompany, stopId: String, serviceType: String?, isInbound: Bool,
    detail: (any BusStopDetailModel)?
  ) {

    sheetRoute = .busStopDetail(
      route: route, company: company, stopId: stopId, serviceType: serviceType,
      isInbound: isInbound, detail: detail)

  }

  func busStopETAListViewModelModel(
    _ viewModel: BusStopETAListViewModel, didRequestDisplayBusRoutes company: BusCompany
  ) {

    switch company {
    case .CTB:
      tab = .CTB
    case .KMB:
      tab = .KMB
    }
  }

}

extension RootCoordinator: BusStopDetailViewModelDelegate {
  func busStopDetailViewModelDidRequestReturnToETAList(_ viewModel: BusStopDetailViewModel) {
    sheetRoute = nil

    while path.count > 0 {
      path.removeLast()
    }

    tab = .ETA
  }

  func busStopDetailViewModel(
    _ viewModel: BusStopDetailViewModel, didRequestBusRouteDetail route: (any BusRouteModel)?
  ) {

    sheetRoute = .none

    if path.count == 0, let route {
      path.append(RootCoordinatorNavigationPath.routeDetail(route: route))

    }

  }

}
