//
//  UserDefaults+Extension.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 3/2/2024.
//

import Foundation

protocol UserDefaultsType {

  func string(forKey: String) -> String?

  func object(forKey defaultName: String) -> Any?

  func setValue(_ value: Any?, forKey key: String)
}

extension UserDefaults: UserDefaultsType {

}
