//
//  Array+Extension.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 22/1/2024.
//

import Foundation

extension Array where Element == any BusRouteModel {
    
    func filterByKeywords(_ keywords: [String]) -> [Element] {
        
        guard !keywords.isEmpty else { return self }
        
       return self.filter { busRoute in
            
            guard
                  let route = busRoute.route?.lowercased(),
                  let originTC = busRoute.originTC,
                  let originSC = busRoute.originSC,
                  let originEn = busRoute.originEn?.lowercased(),
                  let destinationTC = busRoute.destinationTC,
                  let destinationSC = busRoute.destinationSC,
                  let destinationEn = busRoute.destinationEn?.lowercased() else {
                      
                      return false
                  }
            
            for keyword in keywords {
                
                if route.contains(keyword) ||
                    originEn.contains(keyword) ||
                    originSC.contains(keyword) ||
                    originTC.contains(keyword) ||
                    destinationEn.contains(keyword) ||
                    destinationSC.contains(keyword) ||
                    destinationTC.contains(keyword) {
                    continue
                }
                
                return false
                
            }
            
            return true
            
        }
        
    }
    
}
