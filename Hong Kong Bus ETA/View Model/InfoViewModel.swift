//
//  InfoViewModel.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 17/2/2024.
//

import Foundation
import StoreKit
import UIKit

class InfoViewModel: ObservableObject {

  let uiApplication: UIApplicationType

  init(uiApplication: UIApplicationType = UIApplication.shared) {
    self.uiApplication = uiApplication
  }

  func onCheckRepositoryButtonClicked() {
    if let repoURL = URL(string: "https://github.com/GordonOnGithub/Hong-Kong-Bus-ETA"),
      uiApplication.canOpenURL(repoURL)
    {
      uiApplication.openURL(repoURL)
    }
  }

  func onRateThisAppClicked() {
    if let scene = uiApplication.connectedScenes.first(where: {
      $0.activationState == .foregroundActive
    }) as? UIWindowScene {
      SKStoreReviewController.requestReview(in: scene)
    }
  }

  lazy var headerString: String = {

    String(localized: "setting_header")

  }()

  lazy var versionString: String = {

    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

    return "v" + (appVersion ?? "")
  }()

}
