//
//  RootCoordinatorView.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 21/1/2024.
//

import Foundation
import SwiftUI

struct RootCoordinatorView: View {
    
    @StateObject
    private var coordinator : RootCoordinator = RootCoordinator()
    
    var body: some View {
            
        NavigationStack(path: $coordinator.path) {
            
            TabView (selection: $coordinator.tab){
                
                BusStopETAListView(viewModel: coordinator.buildETAListViewModel()).tabItem {
                    Text("ETA")
                }.tag(Tab.ETA)
                
                BusRoutesView(viewModel: coordinator.buildCTBRouteListViewModel())
                    .tabItem {
                        Text("CTB")
                    }.tag(Tab.CTB)
               
                BusRoutesView(viewModel: coordinator.buildKMBRouteListViewModel())
                    .tabItem {
                        Text("KMB")
                    }.tag(Tab.KMB)
                
            }
            .navigationDestination(for: RootCoordinatorNavigationPath.self) { path in
                switch path {
                case .routeDetail(let route):
                    coordinator.buildRouteDetailView(route: route)
                }
                
            }
        }.sheet(item: $coordinator.sheetRoute) { sheet in
            
            switch sheet {
                case .busStopDetail(let route, let company, let stopId, let serviceType, let detail):
                coordinator.buildBusStopDetailView(route: route, company: company, stopId: stopId, serviceType: serviceType, detail: detail)
            }
            
        }
    }
    
    
    
    
}
