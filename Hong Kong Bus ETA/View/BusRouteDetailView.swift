//
//  BusRouteDetailView.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 22/1/2024.
//

import Foundation
import MapKit
import SwiftUI

struct BusRouteDetailView: View {

  @StateObject
  var viewModel: BusRouteDetailViewModel

  var body: some View {
    NavigationView {

      VStack {

        if let list = viewModel.displayedList {
          if viewModel.showMap {
            Spacer().frame(height: 20)
            Map(
              initialPosition: MapCameraPosition.positionOfHongKong,
              bounds: MapCameraBounds.boundsOfHongKong
            ) {

              if let list = viewModel.stopList {

                ForEach(list, id: \.id) { stop in

                  if let stopId = stop.stopId,
                    let busStopDetail = viewModel.busStopDetailsDict[stopId],
                    let name = busStopDetail.nameEn,
                    let latitude = Double(busStopDetail.position?.0 ?? ""),
                    let longitude = Double(busStopDetail.position?.1 ?? "")
                  {

                    Marker(
                      name,
                      coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))

                  }
                }
              }

            }

          } else {
            List {
              Section {
                ForEach(list, id: \.id) { stop in

                  VStack(
                    alignment: .leading,
                    content: {

                      BusStopRowView(viewModel: viewModel.makeBusStopRowViewModel(busStop: stop))

                    })
                }
              } header: {
                Text("Origin")
              } footer: {
                Text("Destination")
              }
            }.searchable(
              text: $viewModel.filter, placement: .navigationBarDrawer(displayMode: .always),
              prompt: Text("Search")
            ).keyboardType(.alphabet)

          }
        } else {
          ProgressView().frame(height: 80)
        }

        Spacer()
      }
    }
    .navigationTitle(
      "\(viewModel.route.getFullRouteName()), \(viewModel.getDestinationDescription())"
    )
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button(
          action: {
            viewModel.showMap.toggle()
          },
          label: {

            Text(viewModel.showMap ? "Show List" : "Show Map")

          })
      }
    }
  }
}
