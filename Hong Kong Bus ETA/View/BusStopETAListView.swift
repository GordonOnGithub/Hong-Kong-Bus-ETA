//
//  BusStopETAListView.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 26/1/2024.
//

import Foundation
import SwiftUI

struct BusStopETAListView: View {

  @StateObject
  var viewModel: BusStopETAListViewModel

  var body: some View {

    VStack {
      if !viewModel.busStopETAList.isEmpty {
        Spacer().frame(height: 10)

        Text(String(localized: "estimated_time_of_arrival")).font(.headline)

        List(viewModel.busStopETAList) { eta in

          BookmarkedBusStopETARowView(
            viewModel: viewModel.buildBookmarkedBusStopETARowViewModel(busStopETA: eta)
          )
          .frame(height: 200)

        }
      } else {
        VStack(spacing: 20) {
          Text(String(localized: "empty_eta_list_title")).font(.headline)
                .multilineTextAlignment(.center)
            Text(String(localized: "empty_eta_list_message")).font(.subheadline).multilineTextAlignment(.center)

          Button(
            action: {
              viewModel.onSearchCTBRoutesButtonClicked()
            },
            label: {
                Text(String(localized: "search_ctb_routes"))
            }
          ).buttonStyle(.bordered).tint(.blue)

          Button(
            action: {
              viewModel.onSearchKMBRoutesButtonClicked()
            },
            label: {
              Text(String(localized: "search_kmb_routes"))
            }
          ).buttonStyle(.bordered).tint(.red)
        }.padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))

      }
    }
  }
}
