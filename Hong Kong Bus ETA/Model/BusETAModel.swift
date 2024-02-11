//
//  CTBETAModel.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 22/1/2024.
//

import Foundation

enum RemainingTime {
  case expired
  case imminent
  case minutes(minutes: Int)

  var description: String {

    switch self {
    case .expired:
      return "-"
    case .imminent:
      return "Less than a minute"
    case .minutes(let minutes):
      return "\(minutes) \( minutes > 1 ? "minutes" : "minute" )"
    }
  }

}

struct BusETAModel: Identifiable, Decodable {

  let destinationTC: String?
  let destinationSC: String?
  let destinationEn: String?

  let etaTimestamp: Date?
  let company: String?
  let route: String?
  let isInbound: Bool
  let stop: String?

  let remarkEn: String?
  let remarkTC: String?
  let remarkSC: String?
  let sequence: String?

  var id: String = UUID().uuidString

  func getReadableHourAndMinute() -> String {

    guard let etaTimestamp else { return "" }

    let hour = Calendar.current.component(.hour, from: etaTimestamp)
    let minute = Calendar.current.component(.minute, from: etaTimestamp)

    var hourString = hour >= 10 ? "\(hour)" : "0\(hour)"
    var minuteString = minute >= 10 ? "\(minute)" : "0\(minute)"

    return hourString + ":" + minuteString

  }

  var remainingTime: RemainingTime {

    guard let etaTimestamp else { return .expired }

    let diffInSecond = etaTimestamp.timeIntervalSince1970 - Date().timeIntervalSince1970

    if diffInSecond < 1 {

      return .expired
    }

    if diffInSecond < 60 {

      return .imminent

    } else {

      let diffInMinute = diffInSecond / 60

      return .minutes(minutes: Int(diffInMinute))

    }

  }

  private enum CodingKeys: String, CodingKey {

    case destinationTC = "dest_tc"
    case destinationSC = "dest_sc"
    case destinationEn = "dest_en"

    case company = "co"
    case route = "route"
    case etaTimestamp = "eta"
    case stop = "stop"
    case inbound = "dir"

    case remarkEn = "rmk_en"
    case remarkTC = "rmk_tc"
    case remarkSC = "rmk_sc"
    case sequence = "seq"
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.destinationTC = try? container.decode(String.self, forKey: .destinationTC)
    self.destinationSC = try? container.decode(String.self, forKey: .destinationSC)
    self.destinationEn = try? container.decode(String.self, forKey: .destinationEn)

    self.company = try? container.decode(String.self, forKey: .company)
    self.route = try? container.decode(String.self, forKey: .route)
    self.stop = try? container.decode(String.self, forKey: .stop)

    if let etaString = try? container.decode(String.self, forKey: .etaTimestamp) {

      self.etaTimestamp = ISO8601DateFormatter().date(from: etaString)
    } else {
      self.etaTimestamp = nil
    }

    let inbound = try? container.decode(String.self, forKey: .inbound)

    self.isInbound = inbound == "I"

    self.remarkEn = try? container.decode(String.self, forKey: .remarkEn)
    self.remarkTC = try? container.decode(String.self, forKey: .remarkTC)
    self.remarkSC = try? container.decode(String.self, forKey: .remarkSC)

    let seq = try? container.decode(Int.self, forKey: .sequence)

    self.sequence = "\(seq)"
  }

}
