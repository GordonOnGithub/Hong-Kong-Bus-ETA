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
            Spacer()
          }
        } else {
          Spacer().frame(height: 30)
        }

        Spacer().frame(height: 5)

        if let busETAList = viewModel.busETAList {

          if let latest = busETAList.first(where: { eta in

            switch eta.remainingTime {
            case .expired:
              return false
            default:
              return true
            }

          }) {

            ETARowView(eta: latest)

          } else {
            Text(String(localized: "no_eta_info")).foregroundStyle(.gray)

          }

        } else {
          ProgressView()
        }

      }
    )
    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
    .contentShape(Rectangle())
    .onTapGesture {
      viewModel.onRowClicked()
    }
  }
}
