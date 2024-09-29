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

  var body: some View {
    VStack(
      alignment: .leading, spacing: 10,
      content: {

        Text(viewModel.busStopETA.getFullRouteName()).font(.title)

        if viewModel.busRoute != nil {

          Text(viewModel.getDestinationDescription()).font(.headline)

        } else {
          Spacer().frame(height: 30)
        }

        if viewModel.busStopDetail != nil {
          HStack {
            Image("location", bundle: .main)
              .renderingMode(.template)
              .resizable().scaledToFit()
              .foregroundStyle(.primary)
              .frame(height: 20)
            Text(viewModel.getBusStopName()).lineLimit(2)
              .font(.system(size: 14, weight: .regular))
            Spacer()
          }.padding(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))
        } else {
          Spacer().frame(height: 30)
        }

        switch viewModel.busETAResult {

        case .success(let busETAList):
          if let busETAList {
            if let latest = busETAList.first(where: { eta in

              switch eta.remainingTime {
              case .expired:
                return false
              default:
                return true
              }

            }) {

              ETARowView(eta: latest, isFetching: $viewModel.isFetchingETA)
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
    )
    .contentShape(Rectangle())
    .onTapGesture {
      viewModel.onRowClicked()
    }
  }
}
