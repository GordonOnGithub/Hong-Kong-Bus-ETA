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

          if viewModel.hasError {

            Text(String(localized: "failed_to_fetch")).font(.headline)
            Spacer().frame(height: 10)

            Button {
              viewModel.fetch()
            } label: {
              Text(String(localized: "retry"))
            }

          } else if viewModel.showMap {
            Spacer().frame(height: 20)
            Map(
              initialPosition: MapCameraPosition.positionOfHongKong,
              bounds: MapCameraBounds.boundsOfHongKong
            ) {

              if let list = viewModel.stopList {

                ForEach(list, id: \.id) { stop in

                  if let stopId = stop.stopId,
                    let busStopDetail = viewModel.busStopDetailsDict[stopId],
                    let name = busStopDetail.localizedName(),
                    let latitude = Double(busStopDetail.position?.0 ?? ""),
                    let longitude = Double(busStopDetail.position?.1 ?? "")
                  {

                    Marker(
                      name,
                      coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))

                  }
                }
              }

              UserAnnotation()

            }.mapControls {
              if viewModel.hasLocationPermission {
                MapUserLocationButton()
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
                Text(String(localized: "origin"))
              } footer: {
                Text(String(localized: "destination"))
              }
            }.searchable(
              text: $viewModel.filter, placement: .navigationBarDrawer(displayMode: .always),
              prompt: Text(String(localized: "search"))
            ).keyboardType(.alphabet)

          }
        } else {
          ProgressView().frame(height: 120)
        }

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
            viewModel.askLocationPermission()
          },
          label: {
            Image(viewModel.showMap ? "list" : "map", bundle: .main)
              .renderingMode(.template)
              .resizable().scaledToFit().frame(height: 25)
              .foregroundStyle((viewModel.displayedList?.isEmpty ?? true) ? .gray : .blue)
          }
        ).disabled((viewModel.displayedList?.isEmpty ?? true))
      }
    }

  }
}
