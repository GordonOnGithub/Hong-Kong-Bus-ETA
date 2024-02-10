//
//  UIApplication+Extension.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 3/2/2024.
//

import Foundation
import UIKit

protocol UIApplicationType {
    func canOpenURL(_ url: URL) -> Bool
    func openURL(_ url: URL) -> Bool

}

extension UIApplication: UIApplicationType {
    
}
