//
//  CTBBusStopModel.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 22/1/2024.
//

import Foundation

struct CTBBusStopModel: BusStopModel, Decodable {
    
    let stopId: String?
    let sequence: String?
    let route : String?
    let isInbound : Bool
    let timestamp : Date?
    
    var id: String = UUID().uuidString
    
    func getFullRouteName() -> String {
        return "\(company.rawValue) \(route ?? "")"
    }
    
    var company: BusCompany { .CTB }
    
    private enum CodingKeys: String, CodingKey {
        case stopId = "stop"
        case sequence = "seq"
        case route = "route"
        case isInbound = "dir"
        case timestamp = "data_timestamp"

        
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.stopId = try? container.decodeIfPresent(String.self, forKey: .stopId)
        let seq = try? container.decodeIfPresent(Int.self, forKey: .sequence)
        
        self.sequence = "\(seq)"
        
        self.route = try? container.decodeIfPresent(String.self, forKey: .route)
        let inbound = try? container.decode(String.self, forKey: .isInbound)
        
        if let timestampString = try? container.decode(String.self, forKey: .timestamp) {
                        
            self.timestamp = ISO8601DateFormatter().date(from: timestampString)
        } else {
            self.timestamp = nil
        }
        
        
        self.isInbound = inbound == "I"
    }
    
    
}
