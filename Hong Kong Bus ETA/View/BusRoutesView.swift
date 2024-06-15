//
//  BusRoutesView.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 21/1/2024.
//

import Foundation
import SwiftUI

struct BusRoutesView: View {

  @StateObject
  var viewModel: BusRoutesViewModel

  var body: some View {
    Group {
      if let list = viewModel.displayedList {
        VStack(spacing: 20) {
          if list.isEmpty {
            if viewModel.filter.isEmpty {
              Text(String(localized: "failed_to_fetch"))

              Button(
                action: {
                  viewModel.fetch()
                },
                label: {
                  Text(String(localized: "retry"))
                })
            } else {
              Text(
                String(
                  format: String(localized: "no_matching_bus_routes"),
                  "\(viewModel.busRoutesListSource.title)")
              )
              .multilineTextAlignment(.center)
              .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
              .foregroundStyle(.gray)

              Button(
                action: {
                  viewModel.resetFilter()
                },
                label: {
                  HStack {
                    Image(systemName: "eraser")
                    Text("reset")
                  }
                })
            }

          } else {
            List {

              Section {
                ForEach(list, id: \.id) { route in

                  Button(
                    action: {
                      viewModel.onRouteSelected(route)
                    },
                    label: {
                      HStack {
                        VStack(alignment: .leading) {

                          Text(route.getFullRouteName()).font(.title)

                          Text(String(localized: "to")) + Text(route.destination())
                        }
                        Spacer()
                      }.frame(height: 80)
                        .contentShape(Rectangle())
                    }
                  ).buttonStyle(.plain)

                }
              } header: {

                if !viewModel.filter.isEmpty {
                  Text(
                    String(
                      format: String(localized: "number_of_result"),
                      "\(viewModel.displayedList?.count ?? 0)"))
                }

              } footer: {

              }

            }.scrollIndicators(.visible)
          }
        }

      } else {
        ProgressView(label: {
          Text("downloading_database")
        })
        .frame(height: 120)
      }
    }.onReceive(
      NotificationCenter.default.publisher(
        for: UIApplication.didEnterBackgroundNotification, object: nil)
    ) { _ in
      viewModel.onEnterBackground()
    }.onReceive(
      NotificationCenter.default.publisher(
        for: UIApplication.willEnterForegroundNotification, object: nil)
    ) { _ in
      viewModel.onReturnToForeground()
    }
  }
}
