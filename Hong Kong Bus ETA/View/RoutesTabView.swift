//
//  RoutesTabView.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 15/6/2024.
//

import Foundation
import SwiftUI

enum SelectedRouteTab: String {
  case ctb = "ctb"
  case kmb = "kmb"
}

struct RoutesTabView: View {

  @StateObject
  var viewModel: RoutesTabViewModel

  var body: some View {
    NavigationView {
      VStack(spacing: 0) {

        HStack {
          Spacer()

          Button(
            action: {
              viewModel.selectedTab = .ctb
            },
            label: {
              HStack(spacing: 0) {

                Text(BusRoutesListSource.ctb.title).foregroundStyle(
                  .blue
                )
                .fontWeight(viewModel.selectedTab == .ctb ? .bold : .regular)

                if let count = viewModel.searchResult[BusRoutesListSource.ctb] {
                  Text(" (\(count))").foregroundStyle(
                    .blue
                  )
                }

              }.padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))

            }
          ).buttonStyle(.borderedProminent).tint(
            .yellow
          )
          .opacity(viewModel.selectedTab == .ctb ? 1 : 0.6)

          Button(
            action: {
              viewModel.selectedTab = .kmb
            },
            label: {
              HStack(spacing: 0) {

                Text(BusRoutesListSource.kmb.title).foregroundStyle(
                  .white
                )
                .fontWeight(viewModel.selectedTab == .kmb ? .bold : .regular)

                if let count = viewModel.searchResult[BusRoutesListSource.kmb] {
                  Text(" (\(count))").foregroundStyle(
                    .white
                  )
                }

              }.padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))

            }
          ).buttonStyle(.borderedProminent).tint(
            .red
          )
          .opacity(viewModel.selectedTab == .kmb ? 1 : 0.6)
          Spacer()

        }
        .padding(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))
        .background(.thinMaterial)

        TabView(
          selection: $viewModel.selectedTab,
          content: {

            BusRoutesView(viewModel: viewModel.ctbRouteListViewModel).tag(SelectedRouteTab.ctb)

            BusRoutesView(viewModel: viewModel.kmbRouteListViewModel).tag(SelectedRouteTab.kmb)
          }
        )
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
      }
    }
    .searchable(
      text: $viewModel.filter, placement: .navigationBarDrawer(displayMode: .always),
      prompt: Text(String(localized: "search_by_keywords"))
    )

  }
}
