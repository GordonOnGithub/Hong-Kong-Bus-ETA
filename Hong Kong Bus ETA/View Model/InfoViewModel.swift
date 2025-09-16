//
//  InfoViewModel.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 17/2/2024.
//

import Foundation
import StoreKit
import UIKit

@MainActor
class InfoViewModel {

  let uiApplication: UIApplicationType

  let storeReviewController: SKStoreReviewControllerInjectableType

  let userDefaults: UserDefaultsType

  init(
    uiApplication: UIApplicationType = UIApplication.shared,
    storeReviewController: SKStoreReviewControllerInjectableType =
      SKStoreReviewControllerInjectable(),
    userDefaults: UserDefaultsType = UserDefaults.standard
  ) {
    self.uiApplication = uiApplication
    self.storeReviewController = storeReviewController
    self.userDefaults = userDefaults

  }

  func onCheckRepositoryButtonClicked() {
    Task {
      if let repoURL = URL(string: "https://github.com/GordonOnGithub/Hong-Kong-Bus-ETA"),
        uiApplication.canOpenURL(repoURL)
      {
        await uiApplication.open(repoURL, options: [:])
      }
    }
  }

  func onRateThisAppClicked() {
    storeReviewController.requestReview()
  }

  func onCheckOtherAppsButtonClicked() {
    Task {
      if let otherAppsURL = URL(
        string: "https://apps.apple.com/us/developer/ka-chun-wong/id1734201673"),
        uiApplication.canOpenURL(otherAppsURL)
      {
        await uiApplication.open(otherAppsURL, options: [:])
      }
    }
  }

  func onDonationButtonClicked() {
    Task {
      if let donationURL = URL(
        string: "https://buymeacoffee.com/gordonw"),
        uiApplication.canOpenURL(donationURL)
      {
        await uiApplication.open(donationURL, options: [:])
      }
    }
  }

  func shouldShowdonationButton() -> Bool {
    return userDefaults.object(forKey: "showRatingReminder") as? Bool == false
  }

  lazy var headerString: String = {

    String(localized: "setting_header")

  }()

  lazy var versionString: String = {

    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

    return "v" + (appVersion ?? "")
  }()

}
