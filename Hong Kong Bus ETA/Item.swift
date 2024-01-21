//
//  Item.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 21/1/2024.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
