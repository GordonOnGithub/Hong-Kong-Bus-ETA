//
//  BusStopDetailView.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 22/1/2024.
//

import Foundation
import MapKit
import SwiftUI

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

          if viewModel.showBookmarkReminder {
            Group {
              HStack {
                Spacer().frame(width: 10)
                Image("info", bundle: .main)
                  .renderingMode(.template)
                  .resizable().scaledToFit().frame(height: 20)
                  .foregroundStyle(.primary)
                Text(String(localized: "bookmark_reminder"))
                  .foregroundStyle(.primary)
                  .font(.system(size: 12))
                Spacer()
              }
              .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            }.background(.green)
              .clipShape(RoundedRectangle(cornerRadius: 5))

          }

          if viewModel.busStopDetail != nil {
            Text(viewModel.getBusStopName()).font(.title)
          }

          HStack {
            Button(
              action: {
                viewModel.showBusRouteDetail()
              },
              label: {
                Text(viewModel.getRouteName()).font(.headline).foregroundStyle(.white)
              }
            ).buttonStyle(.borderedProminent).tint(
              viewModel.busStopETA.company == "KMB" ? .red : .blue)

            Spacer().frame(width: 10)

            if let busFare = viewModel.busFare {
              Image(systemName: "banknote.fill")
              Text("$\(busFare.fullFare)")

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
              Button(
                action: {

                  viewModel.openMapApp()

                },
                label: {
                  HStack {
                    Image("map")
                      .renderingMode(.template)
                      .resizable().scaledToFit()
                      .foregroundStyle(.primary)
                      .frame(height: 20)

                    Text(String(localized: "open_in_map_app"))
                  }
                })

            }

            Map(initialPosition: position, interactionModes: []) {
              Marker(
                viewModel.getBusStopName(),
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))

              UserAnnotation()

            }
            .frame(height: 200)

          }

        }.padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
      }
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
                }
              }
            })
        }
      }
    }
  }
}
