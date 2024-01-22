//
//  BusRouteModel.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 21/1/2024.
//

import Foundation

struct CTBBusRouteModel : BusRouteModel, Decodable {
    
    let originTC : String?
    let originSC : String?
    let originEn : String?
        
    let destinationTC : String?
    let destinationSC : String?
    let destinationEn : String?
    
    let route : String?
    let company : String?
    let timestamp : Date?
    let isInbound : Bool

    var id : String = UUID().uuidString
    
    func destination() -> String {
        
        if isInbound { // TODO: verify
            return originEn ?? ""
        } else {
            return destinationEn ?? ""

        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case originTC = "orig_tc"
        case originSC = "orig_sc"
        case originEn = "orig_en"
        
        case destinationTC = "dest_tc"
        case destinationSC = "dest_sc"
        case destinationEn = "dest_en"
        
        case company = "co"
        case route = "route"
        case timestamp = "data_timestamp"
        
        
    }
    
    init(originTC: String?, originSC: String?, originEn: String?, destinationTC: String?, destinationSC: String?, destinationEn: String?, route: String?, company: String?, timestamp: Date?, isInbound: Bool) {
        self.originTC = originTC
        self.originSC = originSC
        self.originEn = originEn
        self.destinationTC = destinationTC
        self.destinationSC = destinationSC
        self.destinationEn = destinationEn
        self.route = route
        self.company = company
        self.timestamp = timestamp
        self.isInbound = isInbound
        self.id = UUID().uuidString
        
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.originTC = try? container.decode(String.self, forKey: .originTC)
        self.originSC = try? container.decode(String.self, forKey: .originSC)
        self.originEn = try? container.decode(String.self, forKey: .originEn)
        self.destinationTC = try? container.decode(String.self, forKey: .destinationTC)
        self.destinationSC = try? container.decode(String.self, forKey: .destinationSC)
        self.destinationEn = try? container.decode(String.self, forKey: .destinationEn)
        self.company = try? container.decode(String.self, forKey: .company)
        self.route = try? container.decode(String.self, forKey: .route)
        if let timestampString = try? container.decode(String.self, forKey: .timestamp) {
                        
            self.timestamp = ISO8601DateFormatter().date(from: timestampString)
        } else {
            self.timestamp = nil
        }
        
        self.isInbound = false
    }

    
}
