//
//  KMBBusStopModel.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 22/1/2024.
//

import Foundation

protocol BusStopModel : Identifiable {
    
    var stopId: String? { get }
    var sequence: String? { get }
    var route : String? { get }
    var isInbound : Bool { get }
    var id: String { get }
    
    func getFullRouteName() -> String
}

struct KMBBusStopModel: BusStopModel, Decodable {
    
    let stopId: String?
    let sequence: String?
    let route : String?
    let isInbound : Bool
    let serviceType: String?
    
    var id: String = UUID().uuidString
    
    func getFullRouteName() -> String {
        return "KMB \(route ?? "")"
    }
    
    private enum CodingKeys: String, CodingKey {
        case stopId = "stop"
        case sequence = "seq"
        case route = "route"
        case isInbound = "bound"
        case serviceType = "service_type"
        
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.stopId = try? container.decodeIfPresent(String.self, forKey: .stopId)
        self.sequence = try? container.decodeIfPresent(String.self, forKey: .sequence)
        self.route = try? container.decodeIfPresent(String.self, forKey: .route)
        let inbound = try? container.decode(String.self, forKey: .isInbound)
        
        self.serviceType = try? container.decodeIfPresent(String.self, forKey: .serviceType)
        
        self.isInbound = inbound == "I"
    }
    
    
}
