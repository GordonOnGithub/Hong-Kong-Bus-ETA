//
//  BusStopETA.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 24/1/2024.
//

import Foundation
import SwiftData

@Model
final class BusStopETA: Identifiable, @unchecked Sendable {

  var stopId: String

  var route: String

  var company: String

  var serviceType: String?

  var isInbound: Bool

  var addDate: Date

  @Attribute(.unique)
  var id: String

  init(stopId: String, route: String, company: String, serviceType: String?, isInbound: Bool) {
    self.stopId = stopId
    self.route = route
    self.company = company
    self.serviceType = serviceType
    self.isInbound = isInbound

    self.id = company + route + stopId + (serviceType ?? "") + (isInbound ? "I" : "O")

    self.addDate = Date()

  }

  func getFullRouteName() -> String {
    return (company == "KMB" ? BusCompany.KMB.localizedName() : BusCompany.CTB.localizedName())
      + " " + route
  }

}
