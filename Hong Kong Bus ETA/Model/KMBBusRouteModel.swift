//
//  KMBBusRouteModel.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 21/1/2024.
//

import Foundation

enum BusCompany: String {
  case CTB = "CTB"
  case KMB = "KMB"

}

protocol BusRouteModel: Identifiable {

  var originTC: String? { get }
  var originSC: String? { get }
  var originEn: String? { get }

  var destinationTC: String? { get }
  var destinationSC: String? { get }
  var destinationEn: String? { get }

  var route: String? { get }
  var company: BusCompany? { get }
  var isInbound: Bool { get }
  var id: String { get }

  func getFullRouteName() -> String
  func destination() -> String
}

struct KMBBusRouteModel: BusRouteModel, Decodable {

  let originTC: String?
  let originSC: String?
  let originEn: String?

  let destinationTC: String?
  let destinationSC: String?
  let destinationEn: String?

  let company: BusCompany?
  let isInbound: Bool
  let route: String?
  let serviceType: String?  // TODO: figure out what the heck service type is

  var id: String = UUID().uuidString

  func getFullRouteName() -> String {
    return "KMB \(route ?? "")"
  }

  func destination() -> String {

    return destinationEn ?? ""

  }

  private enum CodingKeys: String, CodingKey {
    case originTC = "orig_tc"
    case originSC = "orig_sc"
    case originEn = "orig_en"

    case destinationTC = "dest_tc"
    case destinationSC = "dest_sc"
    case destinationEn = "dest_en"

    case bound = "bound"
    case route = "route"
    case serviceType = "service_type"

  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.originTC = try? container.decode(String.self, forKey: .originTC)
    self.originSC = try? container.decode(String.self, forKey: .originSC)
    self.originEn = try? container.decode(String.self, forKey: .originEn)
    self.destinationTC = try? container.decode(String.self, forKey: .destinationTC)
    self.destinationSC = try? container.decode(String.self, forKey: .destinationSC)
    self.destinationEn = try? container.decode(String.self, forKey: .destinationEn)
    self.route = try? container.decode(String.self, forKey: .route)
    let inbound = try? container.decode(String.self, forKey: .bound)
    self.serviceType = try? container.decode(String.self, forKey: .serviceType)

    self.company = .KMB

    self.isInbound = inbound == "I"

  }

}
