//
//  BusRoutesView.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 21/1/2024.
//

import Foundation
import SwiftUI

struct BusRoutesView: View {

  @StateObject
  var viewModel: BusRoutesViewModel

  var body: some View {

    if let list = viewModel.displayedList {
      NavigationView {
        VStack {

          List {

            ForEach(list, id: \.id) { route in

              Button(
                action: {
                  viewModel.onRouteSelected(route)
                },
                label: {
                  HStack {
                    VStack(alignment: .leading) {

                      Text(route.getFullRouteName()).font(.title)
                      Text("To: \(route.destination())")
                    }
                    Spacer()
                  }.frame(height: 80)
                    .contentShape(Rectangle())
                }
              ).buttonStyle(.plain)

            }

          }
        }
      }
      .searchable(
        text: $viewModel.filter, placement: .navigationBarDrawer(displayMode: .always),
        prompt: Text("Search")
      ).keyboardType(.namePhonePad)

    } else {
      ProgressView()
    }

  }
}
