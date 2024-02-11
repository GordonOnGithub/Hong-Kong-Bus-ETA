//
//  CTBBusStopDetailModel.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 22/1/2024.
//

import Foundation

struct CTBBusStopDetailModel: BusStopDetailModel, Decodable {

  let nameEn: String?
  let nameTC: String?
  let nameSC: String?
  let stopId: String?
  let timestamp: Date?
  let position: (String, String)?

  private enum CodingKeys: String, CodingKey {
    case stopId = "stop"
    case nameEn = "name_en"
    case nameTC = "name_tc"
    case nameSC = "name_sc"
    case timestamp = "data_timestamp"
    case latitude = "lat"
    case longitude = "long"

  }

  init(from decoder: Decoder) throws {

    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.stopId = try? container.decodeIfPresent(String.self, forKey: .stopId)
    self.nameEn = try? container.decodeIfPresent(String.self, forKey: .nameEn)
    self.nameTC = try? container.decodeIfPresent(String.self, forKey: .nameTC)
    self.nameSC = try? container.decodeIfPresent(String.self, forKey: .nameSC)

    if let timestampString = try? container.decode(String.self, forKey: .timestamp) {

      self.timestamp = ISO8601DateFormatter().date(from: timestampString)
    } else {
      self.timestamp = nil
    }

    if let latitude = try? container.decode(String.self, forKey: .latitude),
      let longitude = try? container.decode(String.self, forKey: .longitude)
    {
      self.position = (latitude, longitude)
    } else {
      self.position = nil
    }
  }

}
