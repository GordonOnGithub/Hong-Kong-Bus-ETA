//
//  APIResponseModel.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 21/1/2024.
//

import Foundation

struct APIResponseModel<T: Decodable>: Decodable {

  var data: T

  enum CodingKeys: CodingKey {
    case data
  }

  init(from decoder: Decoder) throws {
    let container: KeyedDecodingContainer<APIResponseModel<T>.CodingKeys> = try decoder.container(
      keyedBy: APIResponseModel<T>.CodingKeys.self)
    self.data = try container.decode(T.self, forKey: APIResponseModel<T>.CodingKeys.data)
  }
}
