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
            
            TabView {
                
                coordinator.buildETAListView().tabItem {
                    Text("ETA")
                }
                
                coordinator.buildRouteListView().tabItem {
                    Text("Routes")
                }
            }.navigationDestination(for: RootCoordinatorNavigationPath.self) { path in
                switch path {
                case .routeDetail(let route):
                    coordinator.buildRouteDetailView(route: route)
                }
                
            }
        }.sheet(item: $coordinator.sheetRoute) { sheet in
            
            switch sheet {
                case .busStopDetail(let busStop, let detail):
                coordinator.buildBusStopDetailView(busStop: busStop, detail: detail)
            }
            
        }
    }
    
    
    
    
}
