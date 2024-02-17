//
//  KMBBusStopDetailModel.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 22/1/2024.
//

import Foundation

protocol BusStopDetailModel {

  var nameEn: String? { get }
  var nameTC: String? { get }
  var nameSC: String? { get }
  var stopId: String? { get }
  var position: (String, String)? { get }

}

extension BusStopDetailModel {

  func localizedName(locale: String? = Locale.preferredLanguages.first) -> String? {

    if let locale, locale.contains("zh") {
      return nameTC
    }
    return nameEn
  }
}

struct KMBBusStopDetailModel: BusStopDetailModel, Decodable {

  let nameEn: String?
  let nameTC: String?
  let nameSC: String?
  let stopId: String?
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

    if let latitude = try? container.decode(String.self, forKey: .latitude),
      let longitude = try? container.decode(String.self, forKey: .longitude)
    {
      self.position = (latitude, longitude)
    } else {
      self.position = nil
    }
  }

}
