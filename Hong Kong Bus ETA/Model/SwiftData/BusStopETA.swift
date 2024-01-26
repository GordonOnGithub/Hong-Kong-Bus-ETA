//
//  BusStopETA.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 24/1/2024.
//

import Foundation
import SwiftData

@Model
class BusStopETA : Identifiable {
    
    let stopId: String
    
    let route: String
    
    let company : String
    
    let serviceType: String?
    
    
    @Attribute(.unique)
    var id : String {
        company + route + stopId + (serviceType ?? "")
    }
    
    init(stopId: String, route: String, company: String, serviceType: String?) {
        self.stopId = stopId
        self.route = route
        self.company = company
        self.serviceType = serviceType
    }
    
}
