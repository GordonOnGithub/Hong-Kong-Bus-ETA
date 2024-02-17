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
        VStack {
          Text(String(localized: "network_not_reachable"))
            .foregroundStyle(.black)
            .font(.system(size: 16, weight: .semibold))
            .frame(maxWidth: .infinity)
          Spacer().frame(height: 10)

        }.background(.yellow)
      }
      NavigationStack(path: $coordinator.path) {

        TabView(selection: $coordinator.tab) {

          BusStopETAListView(viewModel: coordinator.buildETAListViewModel()).tabItem {
            Label(String(localized: "ETA"), systemImage: "clock.fill")

          }.tag(Tab.ETA)

          BusRoutesView(viewModel: coordinator.buildCTBRouteListViewModel())
            .tabItem {
              Label(BusCompany.CTB.localizedName(), systemImage: "bus.doubledecker.fill")

            }.tag(Tab.CTB)

          BusRoutesView(viewModel: coordinator.buildKMBRouteListViewModel())
            .tabItem {
              Label(BusCompany.KMB.localizedName(), systemImage: "bus.doubledecker.fill")

            }.tag(Tab.KMB)

          InfoView(viewModel: InfoViewModel())
            .tabItem {
              Label(String(localized: "info_tab"), systemImage: "info.circle")

            }.tag(Tab.info)
        }
        .navigationDestination(for: RootCoordinatorNavigationPath.self) { path in
          switch path {
          case .routeDetail(let route):
            coordinator.buildRouteDetailView(route: route)
          }

        }
      }.sheet(item: $coordinator.sheetRoute) { sheet in

        switch sheet {
        case .busStopDetail(
          let route, let company, let stopId, let serviceType, let isInbound, let detail):
          coordinator.buildBusStopDetailView(
            route: route, company: company, stopId: stopId, serviceType: serviceType,
            isInbound: isInbound, detail: detail)

        case .sortingPref:
          coordinator.buildETASortingPreferenceView()
        }

      }
    }
  }

}
