//
//  RootCoordinator.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 21/1/2024.
//

import Foundation
import SwiftUI

enum RootCoordinatorSheetRoute : Identifiable {
    case busStopDetail(busStop : any BusStopModel, detail: any BusStopDetailModel)
    
    var id : String {
        
        switch self {
        case .busStopDetail:
            return "busStopDetail"
        }
    }
    
}

enum RootCoordinatorNavigationPath : Identifiable, Hashable {
    
    case routeDetail(route: any BusRouteModel)
    
    var id : String {
        
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

class RootCoordinator: ObservableObject {
    
    @Published
    var path = NavigationPath()
    
    @Published
    var sheetRoute : RootCoordinatorSheetRoute?
    
    func buildRouteListView() -> some View {
        let vm = BusRoutesViewModel()
        vm.delegate = self
        return BusRoutesView(viewModel: vm)
    }
    
    func buildRouteDetailView(route: any BusRouteModel) -> some View {
        
        let vm = BusRouteDetailViewModel(route: route)
        vm.delegate = self
        return BusRouteDetailView(viewModel: vm)
        
    }
    
    func buildETAListView() -> some View {
        
        Text("Implement ETA List View")
    }
    
    func buildBusStopDetailView(busStop : any BusStopModel, detail: any BusStopDetailModel) -> some View {

        let vm = BusStopDetailViewModel(busStop: busStop, busStopDetail: detail)
        
        return BusStopDetailView(viewModel: vm)

    }
}

extension RootCoordinator: BusRoutesViewModelDelegate {
    func busRoutesViewModel(_ viewModel: BusRoutesViewModel, didSelectRoute route: any BusRouteModel) {
        path.append(RootCoordinatorNavigationPath.routeDetail(route: route))
    }
    
}

extension RootCoordinator: BusRouteDetailViewModelDelegate {
    func busRouteDetailViewModel(_ viewModel: BusRouteDetailViewModel, didRequestDisplayBusStop busStop: any BusStopModel, withDetails details: any BusStopDetailModel) {
        
        sheetRoute = .busStopDetail(busStop: busStop, detail: details)
    }
    
  

}
