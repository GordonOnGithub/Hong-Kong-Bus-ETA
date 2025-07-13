//
//  BookmarkedBusStopETARowView.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 26/1/2024.
//

import Foundation
import SwiftUI

struct BookmarkedBusStopETARowView: View {

  @ObservedObject
  var viewModel: BookmarkedBusStopETARowViewModel

  @Binding
  var pinnedETA: BusStopETA?

  var body: some View {
    VStack(
      alignment: .leading, spacing: 10,
      content: {
        HStack {
          Text(viewModel.busStopETA.getFullRouteName()).font(.title2).fontWeight(.medium).lineLimit(
            1
          ).onTapGesture {
            viewModel.onRowClicked()
          }

          Spacer()

          Image(systemName: pinnedETA == viewModel.busStopETA ? "pin.slash" : "pin")
            .foregroundStyle(pinnedETA == viewModel.busStopETA ? .red : .blue)
            .padding(12)
            .background(Circle().fill(.thickMaterial))
            .onTapGesture {
              if pinnedETA == viewModel.busStopETA {
                pinnedETA = nil
              } else {
                pinnedETA = viewModel.busStopETA
              }

              viewModel.onPinnedETAUpdated(pinnedETA)
            }

        }
        VStack(
          alignment: .leading, spacing: 10
        ) {
          if viewModel.busRoute != nil {

            Text(viewModel.getDestinationDescription()).font(.body)

          } else {
            Spacer().frame(height: 30)
          }

          if viewModel.busStopDetail != nil {
            HStack {
              Image("location", bundle: .main)
                .renderingMode(.template)
                .resizable().scaledToFit()
                .foregroundStyle((.secondary))
                .frame(height: 16)
              Text(viewModel.getBusStopName()).font(.footnote).lineLimit(1)
                .foregroundStyle(.secondary)
            }
          } else {
            Spacer().frame(height: 30)
          }

          switch viewModel.busETAResult {

          case .success(let busETAList):
            if let busETAList = busETAList?.filter({
              switch $0.remainingTime {
              case .expired:
                return false
              default:
                return true
              }
            }) {
              if let latest = busETAList.first {
                if pinnedETA == viewModel.busStopETA, busETAList.count > 1 {
                  Divider().padding(1)
                }
                ETARowView(eta: latest, isFetching: $viewModel.isFetchingETA)
                  .font(.title3)
                  .padding(1)

              } else {
                HStack {
                  if viewModel.isFetchingETA {
                    ProgressView().padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 2))
                  } else {
                    Image(systemName: "clock.badge.questionmark")
                  }
                  Text(String(localized: "no_eta_info"))
                  Spacer()
                }.foregroundStyle(.gray)

              }

              if pinnedETA == viewModel.busStopETA, busETAList.count > 1 {

                let moreETAs = busETAList[1..<min(3, busETAList.count)]

                ForEach(moreETAs) {
                  ETARowView(eta: $0, isFetching: $viewModel.isFetchingETA)
                    .foregroundStyle(.secondary)
                    .font(.title3)
                    .padding(1)
                }

              }

            } else {
              HStack {
                ProgressView()
                Spacer()
              }
            }
          case .failure:
            HStack {

              if viewModel.isFetchingETA {
                ProgressView().padding(5)
              } else {
                Image(systemName: "exclamationmark.arrow.triangle.2.circlepath")
              }
              Text(String(localized: "failed_to_fetch_eta_info"))
              Spacer()
            }.foregroundStyle(.gray)

          }
        }
        .contentShape(Rectangle())
        .onTapGesture {
          viewModel.onRowClicked()
        }
      }
    )

  }
}
