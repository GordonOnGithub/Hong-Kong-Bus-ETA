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

  @State
  var destinationName = ""

  var body: some View {

    VStack(spacing: 0) {

      if viewModel.filter.isEmpty {
        busRouteSummary
          .padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
          .background(
            RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemGroupedBackground))
          )
          .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))

        Divider()
      }

      if let list = viewModel.displayedList {

        if viewModel.hasError {
          Spacer()
          Text(String(localized: "failed_to_fetch")).font(.headline)
          Spacer().frame(height: 10)

          Button {
            viewModel.fetch()
          } label: {
            Text(String(localized: "retry"))
          }
          Spacer()

        } else if viewModel.showMap {
          Map(
            initialPosition: MapCameraPosition.positionOfHongKong,
            bounds: MapCameraBounds.boundsOfHongKong,
            interactionModes: [.pan, .zoom, .rotate],
            selection: $viewModel.selectedMapMarker
          ) {

            if let list = viewModel.displayedList {

              ForEach(list, id: \.id) { stop in

                if let stopId = stop.stopId,
                  let busStopDetail = viewModel.busStopDetailsDict[stopId],
                  let name = busStopDetail.localizedName(),
                  let latitude = Double(busStopDetail.position?.0 ?? ""),
                  let longitude = Double(busStopDetail.position?.1 ?? "")
                {

                  let isDestination =
                    (stopId == (list.last?.stopId ?? "")) && viewModel.filter.isEmpty

                  Marker(
                    coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                  ) {
                    Label(name, systemImage: isDestination ? "flag.fill" : "mappin")
                  }
                  .tint(isDestination ? .green : .red)
                  .tag(stopId)

                }
              }
            }

            UserAnnotation()

          }.mapControls {
            if viewModel.hasLocationPermission {
              MapUserLocationButton()
            }
            MapScaleView()
            MapCompass()
          }
          .mapStyle(
            .standard(
              elevation: .automatic, emphasis: .automatic, pointsOfInterest: .all,
              showsTraffic: true))

        } else {

          if list.isEmpty, !viewModel.filter.isEmpty {
            Spacer()

            Text(String(localized: "no_matching_bus_stop"))
              .foregroundStyle(.gray)
              .multilineTextAlignment(.center)
              .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
            Spacer().frame(height: 20)
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
            Spacer()

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
                if viewModel.filter.isEmpty {
                  Text(String(localized: "origin"))
                } else {
                  Text(
                    String(
                      format: String(localized: "number_of_bus_stop_result"),
                      "\(list.count)"))

                }
              } footer: {
                if viewModel.filter.isEmpty {
                  Text(String(localized: "destination"))
                }
              }
            }
          }
        }

      } else {
        Spacer()
        ProgressView(label: {
          Text("loading_bus_route_detail")
        }).frame(height: 120)
        Spacer()

      }

      if viewModel.filter.isEmpty {

        if let closestBusStop = viewModel.closestBusStop {

          Divider()
          Label {
            Text(String(localized: "closest_bus_stop"))
          } icon: {
            Image(systemName: "figure.wave.circle")
              .renderingMode(.template)
              .resizable().scaledToFit()
              .foregroundStyle(.primary)
              .frame(height: 20)
          }.font(.subheadline).multilineTextAlignment(.leading)
            .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 10))

          closetBusStopButton(closestBusStop: closestBusStop)
            .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))

        }

      }
    }
    .padding(EdgeInsets(top: 0, leading: 0, bottom: 20, trailing: 0))
    .searchable(
      text: $viewModel.filter, placement: .navigationBarDrawer(displayMode: .automatic),
      prompt: Text(String(localized: "search"))
    ).keyboardType(.alphabet)
    .background(Color(.systemGroupedBackground))
    .navigationTitle(
      String(localized: "route_details")
    )
    .toolbar {

      ToolbarItem(placement: .topBarTrailing) {
        Button(
          action: {
            viewModel.switchRouteDirection()
            withAnimation(.easeInOut(duration: 0.3)) {
              destinationName = viewModel.getDestinationDescription()
            }
          },
          label: {

            Image(
              systemName: viewModel.route.isInbound ? "arrow.left.circle" : "arrow.right.circle"
            )
            .foregroundStyle((viewModel.stopList?.isEmpty ?? true) ? .gray : .blue)

          }
        )
        .contentTransition(.symbolEffect(.replace))
        .disabled((viewModel.stopList?.isEmpty ?? true))
      }

      ToolbarItem(placement: .topBarTrailing) {
        Button(
          action: {
            viewModel.showMap.toggle()
          },
          label: {

            Image(systemName: viewModel.showMap ? "list.number" : "map")
              .foregroundStyle((viewModel.stopList?.isEmpty ?? true) ? .gray : .blue)

          }
        ).disabled((viewModel.stopList?.isEmpty ?? true))
          .popoverTip(MapTip())
          .contentTransition(.symbolEffect(.replace))
      }
    }

  }

  func closetBusStopButton(closestBusStop: (any BusStopDetailModel, Double)) -> some View {
    Button {
      viewModel.onBusStopSelected(stopId: closestBusStop.0.stopId ?? "")
    } label: {

      HStack {

        VStack(alignment: .leading, spacing: 10) {

          HStack {

            Text(closestBusStop.0.localizedName() ?? "")
              .multilineTextAlignment(.leading)
            Spacer()
          }
          HStack {
            Image(systemName: "figure.walk")

            if closestBusStop.1 > 1 {
              Text(
                "\(Int(closestBusStop.1)) \(String(localized:"minutes_walk"))"
              ).font(.footnote)
            } else {
              Text(
                String(localized: "near_you")
              ).font(.footnote)
            }
            Spacer()
          }

        }
      }.padding(12)

    }
    .foregroundStyle(.white)
    .background(
      RoundedRectangle(cornerRadius: 12).fill(.indigo)
    )
  }

  var busRouteSummary: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text(viewModel.route.getFullRouteName()).font(.title2).fontWeight(.medium)
          .multilineTextAlignment(.leading)

        if viewModel.routeSummary?.serviceMode.contains("N") ?? false {
          Image(systemName: "moon.stars")
        }

        Spacer()
      }
      Text(
        destinationName
      ).lineLimit(2).multilineTextAlignment(.leading)

      if let busFare = viewModel.routeSummary {
        HStack {
          Image(systemName: "dollarsign.circle.fill")
          Text("\(busFare.fullFare)")

          Spacer()
          Image(systemName: "point.bottomleft.filled.forward.to.point.topright.scurvepath")

          Text("\(busFare.jouneryTime) \(String(localized: "minutes"))")

        }.foregroundStyle(.secondary)

        if let description = busFare.specialType.description {
          HStack {
            Image(systemName: "info.circle")

            Text(description).lineLimit(2).multilineTextAlignment(.leading)
              .font(.caption)
            Spacer()
          }.foregroundStyle(.secondary)

        }
      }
    }.onAppear {
      destinationName = viewModel.getDestinationDescription()
    }
  }
}

struct MapTip: Tip {

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
