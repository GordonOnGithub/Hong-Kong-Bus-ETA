//
//  BusStopETAListView.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 26/1/2024.
//

import Foundation
import SwiftUI

struct BusStopETAListView: View {

  @StateObject
  var viewModel: BusStopETAListViewModel

  var body: some View {

    VStack {
      if !viewModel.busStopETAList.isEmpty {
        Spacer().frame(height: 10)

        HStack {
          Spacer().frame(width: 50)

          Text(String(localized: "estimated_time_of_arrival")).font(.headline).frame(
            maxWidth: .infinity)

          Menu {
            Section(String(localized: "eta_sorting_pref")) {

              Button(
                action: {
                  viewModel.changeSorting(sorting: .routeNumber)

                },
                label: {

                  HStack {

                    if viewModel.sorting == .routeNumber {
                      Image(systemName: "checkmark.circle")
                        .foregroundStyle(.primary)
                    }

                    Text(String(localized: "large_route_number_first"))
                  }
                }
              ).buttonStyle(.plain)

              Button(
                action: {
                  viewModel.changeSorting(sorting: .routeNumberInverse)

                },
                label: {
                  HStack {
                    if viewModel.sorting == .routeNumberInverse {
                      Image(systemName: "checkmark.circle")
                        .foregroundStyle(.primary)
                    }
                    Text(String(localized: "small_route_number_first"))
                  }

                }
              ).buttonStyle(.plain)

              Button(
                action: {
                  viewModel.changeSorting(sorting: .addDateLatest)

                },
                label: {
                  HStack {
                    if viewModel.sorting == .addDateLatest {
                      Image(systemName: "checkmark.circle")
                        .foregroundStyle(.primary)
                    }
                    Text(String(localized: "latest_added_first"))
                  }
                }
              ).buttonStyle(.plain)

              Button(
                action: {
                  viewModel.changeSorting(sorting: .addDateEarliest)

                },
                label: {
                  HStack {
                    if viewModel.sorting == .addDateEarliest {
                      Image(systemName: "checkmark.circle")
                        .foregroundStyle(.primary)
                    }
                    Text(String(localized: "earliest_added_first"))
                  }

                }
              ).buttonStyle(.plain)
            }
          } label: {
            Label("", systemImage: "arrow.up.and.down.text.horizontal")
          }

        }.padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))

        List {

          Section {
            ForEach(viewModel.busStopETAList) { eta in
              BookmarkedBusStopETARowView(
                viewModel: viewModel.buildBookmarkedBusStopETARowViewModel(busStopETA: eta)
              )
              .frame(height: 180)

            }
          } header: {
            Text(String(localized: "update_every_30_seconds")).listRowInsets(EdgeInsets())

          }

        }

        if viewModel.showRatingReminder {
          Button(
            action: {
              viewModel.onRatingButtonClicked()

            },
            label: {
              Text(String(localized: "rate_this_app_reminder")).frame(maxWidth: .infinity)
            }
          ).buttonStyle(.borderedProminent)
            .tint(.green)
            .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
        }

      } else {
        VStack(spacing: 20) {
          Text(String(localized: "empty_eta_list_title")).font(.headline)
            .multilineTextAlignment(.center)
          Text(String(localized: "empty_eta_list_message")).font(.subheadline)
            .multilineTextAlignment(.center)

          Button(
            action: {
              viewModel.onSearchCTBRoutesButtonClicked()
            },
            label: {
              HStack {
                Image(systemName: "magnifyingglass")
                Text(String(localized: "search_ctb_routes"))
              }
            }
          ).buttonStyle(.bordered).tint(.blue)

          Button(
            action: {
              viewModel.onSearchKMBRoutesButtonClicked()
            },
            label: {
              HStack {
                Image(systemName: "magnifyingglass")
                Text(String(localized: "search_kmb_routes"))
              }
            }
          ).buttonStyle(.bordered).tint(.red)
        }.padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))

      }
    }
  }
}
