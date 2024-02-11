//
//  BusStopRowView.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 22/1/2024.
//

import Foundation
import SwiftUI

struct BusStopRowView: View {

  @StateObject
  var viewModel: BusStopRowViewModel

  var body: some View {

    if let detail = viewModel.busStopDetail {

      Button(
        action: {
          viewModel.onBusStopSelected()
        },
        label: {
          HStack(alignment: .center) {

            Text(detail.localizedName() ?? "")
            Spacer()

          }.frame(height: 50)
            .contentShape(Rectangle())
        }
      ).buttonStyle(.plain)

    } else if let error = viewModel.error {

      Button(
        action: {
          viewModel.fetch()
        },
        label: {
          Text(String(localized: "retry"))
        })

    } else {
      ProgressView().frame(height: 50)
    }

  }
}
