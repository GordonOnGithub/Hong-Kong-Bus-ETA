//
//  BusFareModel.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 27/4/2024.
//

import Foundation

struct BusFareModel {

  enum BusRouteSpecialType: String {
    case none = "0"
    case timeSpecific = "1"
    case differentFeeForHoliday = "2"
    case both = "3"

    var description: String? {

      switch self {
      case .none:
        nil
      case .timeSpecific:
        String(localized: "time_specific_route")
      case .differentFeeForHoliday:
        String(localized: "different_holiday_fee")

      case .both:
        String(localized: "time_specific_route") + "\n" + String(localized: "different_holiday_fee")

      }

    }
  }

  var companyCode: String
  var routeNumber: String
  var fullFare: String
  var specialType: BusRouteSpecialType
  var jouneryTime: String

}
