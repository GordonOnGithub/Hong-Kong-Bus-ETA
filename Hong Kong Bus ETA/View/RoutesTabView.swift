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
              HStack {
                Spacer()

                Text(BusRoutesListSource.ctb.title).foregroundStyle(
                  .blue
                ).font(.headline)
                  .fontWeight(viewModel.selectedTab == .ctb ? .bold : .regular)

                if let count = viewModel.searchResult[BusRoutesListSource.ctb] {
                  Text("(\(count))").foregroundStyle(
                    .blue
                  ).font(.headline)
                }

                if viewModel.selectedTab == .ctb {
                  Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(
                      .blue
                    )
                }
                Spacer()

              }
            }
          ).buttonStyle(.borderedProminent).tint(
            .yellow

          )
          .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
          .opacity(viewModel.selectedTab == .ctb ? 1 : 0.7)

          Button(
            action: {
              viewModel.selectedTab = .kmb
            },
            label: {
              HStack {
                Spacer()

                Text(BusRoutesListSource.kmb.title).foregroundStyle(
                  .white
                ).font(.headline)
                  .fontWeight(viewModel.selectedTab == .kmb ? .bold : .regular)

                if let count = viewModel.searchResult[BusRoutesListSource.kmb] {
                  Text("(\(count))").foregroundStyle(
                    .white
                  ).font(.headline)
                }

                if viewModel.selectedTab == .kmb {
                  Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(
                      .white
                    )
                }

                Spacer()

              }
            }
          ).buttonStyle(.borderedProminent).tint(
            .red
          )
          .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
          .opacity(viewModel.selectedTab == .kmb ? 1 : 0.7)
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
