//
//  InfoView.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 17/2/2024.
//

import Foundation
import SwiftUI

struct InfoView: View {

  var viewModel: InfoViewModel

  var body: some View {

    VStack {
      Text(String(localized: "info_tab")).font(.headline)

      List {

        Section {
          Button(
            action: {
              viewModel.onCheckRepositoryButtonClicked()
            },
            label: {
              Label(String(localized: "repository"), systemImage: "swift")
            })

          Button(
            action: {
              viewModel.onRateThisAppClicked()
            },
            label: {
              Label(String(localized: "rate_this_app"), systemImage: "star")
            })

          Button(
            action: {
              viewModel.onCheckOtherAppsButtonClicked()
            },
            label: {
              Label(String(localized: "check_other_apps"), systemImage: "arrow.down.app")
            })

          if viewModel.shouldShowdonationButton() {
            Button(
              action: {
                viewModel.onDonationButtonClicked()
              },
              label: {
                Label(String(localized: "donate_to_support"), systemImage: "cup.and.saucer")
              })
          }

        } header: {
          Text(viewModel.headerString)
        } footer: {
          Text(viewModel.versionString)

        }

      }
    }
  }
}
