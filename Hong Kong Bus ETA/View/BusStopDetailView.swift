//
//  BusStopDetailView.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 22/1/2024.
//

import Foundation
import MapKit
import SwiftUI
import TipKit

struct BusStopDetailView: View {

  @Environment(\.dismiss) var dismiss

  @StateObject
  var viewModel: BusStopDetailViewModel

  var body: some View {
    NavigationView {
      VStack {

        if viewModel.showNetworkUnavailableWarning {
          HStack {
            Spacer()

            Image(systemName: "network.slash").foregroundStyle(.black)

            Text(String(localized: "network_not_reachable"))
              .foregroundStyle(.black)
              .font(.system(size: 16, weight: .semibold))
            Spacer()

          }
          .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))

          .background(.yellow)
        }

        VStack(alignment: .leading, spacing: 10) {

          if viewModel.busStopDetail != nil {
            Text(viewModel.getBusStopName()).font(.title)
          }

          HStack {
            Button(
              action: {
                viewModel.showBusRouteDetail()
              },
              label: {
                Text(viewModel.getRouteName()).font(.headline).foregroundStyle(
                  viewModel.busStopETA.company == "KMB" ? .white : .blue)
              }
            ).buttonStyle(.borderedProminent).tint(
              viewModel.busStopETA.company == "KMB" ? .red : .yellow)

            Spacer().frame(width: 10)

            if let busFare = viewModel.busFare {
              Image(systemName: "dollarsign.circle.fill")
              Text("\(busFare.fullFare)")

            }

            Spacer()
          }
          if viewModel.busRoute != nil {
            Text(viewModel.getDestinationDescription()).font(.subheadline)
          }

          Divider()
          if let busETAList = viewModel.busETAList?.filter({ eta in
            eta.etaTimestamp != nil
          }) {

            List {

              Section {
                ForEach(busETAList) { eta in
                  ETARowView(eta: eta)
                }

              } header: {
                if busETAList.isEmpty {
                  // No information on estimated time of arrival.
                  Text(String(localized: "no_eta_info")).listRowInsets(EdgeInsets())
                } else {
                  Text(String(localized: "estimated_time_of_arrival")).listRowInsets(EdgeInsets())
                }
              } footer: {
                if let lastUpdatedTimestamp = viewModel.lastUpdatedTimestamp {
                  Section {
                    Text(
                      String(localized: "last_update")
                        + " \(lastUpdatedTimestamp.ISO8601Format(.iso8601(timeZone: TimeZone.current)))"
                    ).listRowInsets(EdgeInsets())
                  }
                }
              }

            }.refreshable {
              viewModel.fetchETA()
              try? await Task.sleep(nanoseconds: 1_000_000_000)
            }

          } else {
            HStack {
              Spacer()
              ProgressView(label: {
                Text("fetching_eta")
              }).frame(height: 300)
              Spacer()
            }
          }

          if let busStopDetail = viewModel.busStopDetail,
            let latitude = Double(busStopDetail.position?.0 ?? ""),
            let longitude = Double(busStopDetail.position?.1 ?? "")
          {

            let position = MapCameraPosition.region(
              MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
              )
            )
            Divider()

            HStack {
              Image("location", bundle: .main)
                .renderingMode(.template)
                .resizable().scaledToFit()
                .foregroundStyle(.primary)
                .frame(height: 20)
              Text(String(localized: "location")).font(.headline)
              Spacer()

              Button {
                viewModel.showMap.toggle()
              } label: {
                if viewModel.showMap {
                  Label("look around", systemImage: "binoculars")
                } else {
                  Label("map", systemImage: "map")
                }
              }.disabled(viewModel.lookAroundScene == nil)

            }

            if viewModel.showMap {
              Map(initialPosition: position, interactionModes: []) {
                Marker(
                  viewModel.getBusStopName(),
                  coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))

                UserAnnotation()

              }
              .frame(height: 200)
            } else if viewModel.lookAroundScene != nil {

              LookAroundPreview(scene: $viewModel.lookAroundScene)
                .frame(height: 200)

            }

            HStack {
              Spacer()
              Button(
                action: {

                  viewModel.openMapApp()

                },
                label: {
                  HStack {

                    Text(String(localized: "open_in_map_app"))

                    Image(systemName: "arrow.up.forward.app")
                      .foregroundStyle(.primary)
                      .frame(height: 20)

                  }
                })
              Spacer()

            }
          }

        }.padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
      }
      .alert(
        String(localized: "failed_to_fetch"), isPresented: $viewModel.encounteredError,
        actions: {

          Button(role: .cancel) {
            viewModel.encounteredError = false
          } label: {
            Text("dismiss")
          }

          Button(role: .none) {
            viewModel.fetchAllData()
          } label: {
            Text("retry")
          }

        }
      )
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(
            action: {
              dismiss()
            },
            label: {
              Text(String(localized: "dismiss"))
            })
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button(
            action: {
              viewModel.onSaveButtonClicked()
            },
            label: {

              if viewModel.isSaved {
                HStack {
                  Image(systemName: "bookmark.slash")
                    .foregroundStyle(.red)
                  Text(String(localized: "unbookmark")).fontWeight(.semibold).foregroundStyle(.red)
                }
              } else {
                HStack {
                  Image(systemName: "bookmark")
                  Text(String(localized: "bookmark")).fontWeight(.semibold)
                }.popoverTip(BookmarkTip())

              }
            })
        }
      }
    }
  }
}

struct BookmarkTip: Tip {

  var title: Text {
    Text(String(localized: "bookmark"))
  }

  var message: Text? {
    Text(String(localized: "bookmark_reminder"))
  }

  @Parameter
  static var showBookmarkTip: Bool = true

  var rules: [Rule] {
    [
      #Rule(Self.$showBookmarkTip) {
        $0 == true
      }
    ]
  }

}
