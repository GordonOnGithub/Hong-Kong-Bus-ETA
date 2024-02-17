//
//  ETASortingPreferenceView.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 17/2/2024.
//

import Foundation
import SwiftUI

struct ETASortingPreferenceView: View {

  @StateObject
  var viewModel: ETASortingPreferenceViewModel

  var body: some View {
    VStack {
      Text(String(localized: "eta_sorting_pref")).font(.headline)
        .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))

      List {

        Button(
          action: {
            viewModel.changeSorting(sorting: .routeNumber)

          },
          label: {
            Text(String(localized: "large_route_number_first"))
              .frame(maxWidth: .infinity)
          }
        ).buttonStyle(.plain)
          .foregroundStyle(viewModel.sorting == .routeNumber ? .blue : .primary)

        Button(
          action: {
            viewModel.changeSorting(sorting: .routeNumberInverse)

          },
          label: {
            Text(String(localized: "small_route_number_first"))
              .frame(maxWidth: .infinity)
          }
        ).buttonStyle(.plain)
          .foregroundStyle(viewModel.sorting == .routeNumberInverse ? .blue : .primary)

        Button(
          action: {
            viewModel.changeSorting(sorting: .addDateLatest)

          },
          label: {
            Text(String(localized: "latest_added_first"))
              .frame(maxWidth: .infinity)
          }
        ).buttonStyle(.plain)
          .foregroundStyle(viewModel.sorting == .addDateLatest ? .blue : .primary)

        Button(
          action: {
            viewModel.changeSorting(sorting: .addDateEarliest)

          },
          label: {
            Text(String(localized: "earliest_added_first"))
              .frame(maxWidth: .infinity)
          }
        ).buttonStyle(.plain)
          .foregroundStyle(viewModel.sorting == .addDateEarliest ? .blue : .primary)
      }
    }
  }
}
