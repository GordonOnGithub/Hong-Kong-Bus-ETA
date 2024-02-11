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
          VStack {
            Text(String(localized: "network_not_reachable"))
              .foregroundStyle(.black)
              .font(.system(size: 16, weight: .semibold))
              .frame(maxWidth: .infinity)
              .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))

          }.background(.yellow)
        }

        VStack(alignment: .leading, spacing: 10) {

          if viewModel.busStopDetail != nil {
            Text(viewModel.getBusStopName()).font(.title)
          }

            Button(action: {
                viewModel.showBusRouteDetail()
            }, label: {
                Text(viewModel.getRouteName()).font(.headline).foregroundStyle(.white)
            }).buttonStyle(.borderedProminent).tint(viewModel.busStopETA.company == "KMB" ? .red : .blue )

              if viewModel.busRoute != nil {
                Text(viewModel.getDestinationDescription()).font(.subheadline)
              }
            

          Spacer().frame(height: 10)
          if let busETAList = viewModel.busETAList {

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
                       String(localized: "last_update") + " \(lastUpdatedTimestamp.ISO8601Format(.iso8601(timeZone: TimeZone.current)))"
                    ).listRowInsets(EdgeInsets())
                  }
                }
              }

            }

          } else {

            ProgressView().frame(height: 300)
          }

          if let busStopDetail = viewModel.busStopDetail,
            let latitude = Double(busStopDetail.position?.0 ?? ""),
            let longitude = Double(busStopDetail.position?.1 ?? "")
          {

            let position = MapCameraPosition.region(
              MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
              )
            )
            Spacer().frame(height: 10)

            HStack {

                Text(String(localized: "location")).font(.headline)
              Spacer()
              Button(
                action: {

                  viewModel.openMapApp()

                },
                label: {
                    Text(String(localized: "open_in_map_app"))
                })

            }

            Map(initialPosition: position) {
              Marker(
                viewModel.getBusStopName(),
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
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
                  Text(String(localized: "unbookmark"))
              } else {
                Text(String(localized: "bookmark"))
              }
            })
        }
      }
    }
  }
}
