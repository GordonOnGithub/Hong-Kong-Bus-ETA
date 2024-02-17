//
//  ETASortingPreferenceViewModel.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 17/2/2024.
//

import Foundation

protocol ETASortingPreferenceViewModelDelegate: AnyObject {

  func ETASortingPreferenceViewModelDidUpdateSorting(_ viewModel: ETASortingPreferenceViewModel)
}

class ETASortingPreferenceViewModel: ObservableObject {

  @Published
  var sorting: Sorting = .addDateLatest

  weak var delegate: ETASortingPreferenceViewModelDelegate?

  let userDefaults: UserDefaultsType

  private let etaSortingKey = "etaSorting"

  init(userDefaults: UserDefaultsType = UserDefaults.standard) {
    self.userDefaults = userDefaults

    if let sortingPreference = userDefaults.object(forKey: etaSortingKey) as? Int {

      self.sorting = Sorting(rawValue: sortingPreference) ?? .addDateLatest
    }
  }

  func changeSorting(sorting: Sorting) {

    self.sorting = sorting

    userDefaults.setValue(sorting.rawValue, forKey: etaSortingKey)

    delegate?.ETASortingPreferenceViewModelDidUpdateSorting(self)

  }

}
