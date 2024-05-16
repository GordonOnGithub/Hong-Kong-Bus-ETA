//
//  Hong_Kong_Bus_ETAApp.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 21/1/2024.
//

import SwiftData
import SwiftUI
import TipKit

@main
struct HongKongBusETAApp: App {

  init() {
    // Configure Tip's data container
    try? Tips.configure()
  }

  var body: some Scene {
    WindowGroup {
      RootCoordinatorView()
    }
  }
}
