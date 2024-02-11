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
    
    let isInbound: Bool
    
    @Attribute(.unique)
    var id : String 
    
    init(stopId: String, route: String, company: String, serviceType: String?, isInbound: Bool) {
        self.stopId = stopId
        self.route = route
        self.company = company
        self.serviceType = serviceType
        self.isInbound = isInbound
        
        self.id = company + route + stopId + (serviceType ?? "") + (isInbound ? "I" : "O")

    }
    
    func getFullRouteName() -> String {
        return company + " " + route
    }

}
