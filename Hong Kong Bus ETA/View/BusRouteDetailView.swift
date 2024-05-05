//
//  BusRouteDetailView.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 22/1/2024.
//

import Foundation
import MapKit
import SwiftUI
import TipKit

struct BusRouteDetailView: View {

  @Environment(\.dismiss) var dismiss

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
              bounds: MapCameraBounds.boundsOfHongKong,
              interactionModes: [.pan, .zoom],
              selection: $viewModel.selectedMapMarker
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
                      coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    ).tag(stopId)

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

            Group {

              if list.isEmpty, !viewModel.filter.isEmpty {
                Text(String(localized: "no_matching_bus_stop"))
                  .multilineTextAlignment(.center)
                  .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                Button(
                  action: {
                    viewModel.resetFilter()
                  },
                  label: {
                    HStack {
                      Image(systemName: "eraser")
                      Text("reset")    
                        .foregroundStyle(.gray)
                    }
                  })
              } else {

                List {
                  Section {
                    ForEach(list, id: \.id) { stop in

                      VStack(
                        alignment: .leading,
                        content: {

                          BusStopRowView(
                            viewModel: viewModel.makeBusStopRowViewModel(busStop: stop))

                        })
                    }
                  } header: {
                    Text(String(localized: "origin"))
                  } footer: {
                    Text(String(localized: "destination"))
                  }
                }
              }
            }.searchable(
              text: $viewModel.filter, placement: .navigationBarDrawer(displayMode: .always),
              prompt: Text(String(localized: "search"))
            ).keyboardType(.alphabet)

          }
        } else {
          ProgressView(label: {
            Text("loading_bus_route_detail")
          }).frame(height: 120)
        }

        if viewModel.filter.isEmpty {
          Spacer()

          if let closestBusStop = viewModel.closestBusStop {

            Button {
              viewModel.onBusStopSelected(stopId: closestBusStop.0.stopId ?? "")
            } label: {

              HStack {

                Image(systemName: "mappin.and.ellipse")

                VStack(alignment: .leading) {
                  HStack {
                    Text(String(localized: "closest_bus_stop")).fontWeight(.bold)
                      + Text("( ~\(Int(closestBusStop.1))m)").fontWeight(.bold)
                    Spacer()
                  }

                  Text(closestBusStop.0.localizedName() ?? "")
                    .multilineTextAlignment(.leading)

                }
              }.padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))

            }
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 10).fill(.indigo).shadow(radius: 5, x: 0, y: 5)
            )
            .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))

          }

          busRouteSummary
        }
      }
    }
    .navigationTitle(
      viewModel.route.getFullRouteName()
    )
    .navigationBarBackButtonHidden(true)
    .toolbar {

      ToolbarItem(placement: .topBarLeading) {

        Button {

          if viewModel.showMap {
            viewModel.showMap = false
          } else {
            dismiss()
          }

        } label: {
          Image(systemName: "chevron.backward")
        }

      }

      ToolbarItem(placement: .topBarTrailing) {
        Button(
          action: {
            viewModel.showMap.toggle()
          },
          label: {
            VStack {
              Image(viewModel.showMap ? "list" : "map", bundle: .main)
                .renderingMode(.template)
                .resizable().scaledToFit().frame(height: 25)
                .foregroundStyle((viewModel.displayedList?.isEmpty ?? true) ? .gray : .blue)
              Text(String(localized: viewModel.showMap ? "list" : "map"))
                .font(.system(size: 10))
                .foregroundStyle((viewModel.displayedList?.isEmpty ?? true) ? .gray : .blue)

            }
          }
        ).disabled((viewModel.displayedList?.isEmpty ?? true))
              .popoverTip(MapTip())
      }
    }

  }

  var busRouteSummary: some View {
    VStack(alignment: .leading) {

      Text(
        viewModel.getDestinationDescription()
      ).lineLimit(2).multilineTextAlignment(.leading)
        .font(.title3)

      if let busFare = viewModel.busFare {
        HStack {
          Image(systemName: "banknote.fill")
          Text("$\(busFare.fullFare)")
          Spacer()
          Image(systemName: "point.bottomleft.filled.forward.to.point.topright.scurvepath")

          Text("\(busFare.jouneryTime) \(String(localized: "minutes"))")

        }.frame(height: 30)

        if let description = busFare.specialType.description {
          HStack {
            Image(systemName: "info.circle")

            Text(description).lineLimit(2).multilineTextAlignment(.leading)
              .font(.subheadline)
            Spacer()
          }

        }
      }
    }.padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
      .foregroundStyle(.primary)
      .background(RoundedRectangle(cornerRadius: 10).fill(.clear).stroke(.primary))
      .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
  }
}

struct MapTip : Tip {
    
    var title: Text {
        Text(String(localized: "map"))
    }
    
    var message: Text? {
        Text(String(localized: "map_reminder"))
    }
    
    @Parameter
    static var showMapTip: Bool = true

    var rules: [Rule] {
      [
        #Rule(Self.$showMapTip) {
          $0 == true
        }
      ]
    }
    
 
}
