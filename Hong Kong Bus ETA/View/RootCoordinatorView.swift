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
  private var coordinator: RootCoordinator = RootCoordinator()

  var body: some View {

    VStack {
      if coordinator.showNetworkUnavailableWarning {
        HStack {
          Spacer()

          Image(systemName: "network.slash")
            .foregroundStyle(.black)

          Text(String(localized: "network_not_reachable"))
            .foregroundStyle(.black)
            .font(.system(size: 16, weight: .semibold))
          Spacer()

        }.padding(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))
          .background(.yellow)
      }
      NavigationStack(path: $coordinator.path) {

        TabView(selection: $coordinator.tab) {

          BusStopETAListView(viewModel: coordinator.buildETAListViewModel()).tabItem {
            Label(String(localized: "ETA"), systemImage: "clock.fill")

          }.tag(Tab.ETA)

          RoutesTabView(viewModel: coordinator.routesTabViewModel)
            .tabItem {
              Label("routes", systemImage: "bus.doubledecker.fill")

            }.tag(Tab.routes)

          InfoView(viewModel: InfoViewModel())
            .tabItem {
              Label(String(localized: "info_tab"), systemImage: "info.circle")

            }.tag(Tab.info)
        }
        .navigationDestination(for: RootCoordinatorNavigationPath.self) { path in
          switch path {
          case .routeDetail(let route):
            BusRouteDetailView(viewModel: coordinator.buildRouteDetailViewModel(route: route))

          }

        }
      }.sheet(item: $coordinator.sheetRoute) { sheet in

        switch sheet {
        case .busStopDetail(
          let route, let company, let stopId, let serviceType, let isInbound, let detail):
          BusStopDetailView(
            viewModel: coordinator.buildBusStopDetailViewModel(
              route: route, company: company, stopId: stopId, serviceType: serviceType,
              isInbound: isInbound, detail: detail))

        }

      }
    }
  }

}
