//
//  APIManager.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 21/1/2024.
//

import Alamofire
import Combine
import Foundation

protocol APIManagerType: Sendable {
  static var shared: APIManagerType { get }
  var isReachable: CurrentValueSubject<Bool, Never> { get }
  func call(api: API) async throws -> Data?
}

enum API {

  case CTBRoutes
  case KMBRoutes
  case CTBRouteData(route: String, isInbound: Bool)
  case KMBRouteData(route: String, isInbound: Bool, serviceType: String)
  case CTBBusStopDetail(stopId: String)
  case KMBBusStopDetail(stopId: String)
  case CTBArrivalEstimation(stopId: String, route: String)
  case KMBArrivalEstimation(stopId: String, route: String, serviceType: String)

  case fare

  var url: URL {

    var urlString: String? = nil

    switch self {
    case .CTBRoutes:
      urlString = "https://rt.data.gov.hk/v2/transport/citybus/route/ctb"
    case .KMBRoutes:
      urlString = "https://data.etabus.gov.hk/v1/transport/kmb/route/"
    case .CTBRouteData(let route, let isInbound):
      urlString =
        "https://rt.data.gov.hk/v2/transport/citybus/route-stop/CTB/\(route)/\(isInbound ? "inbound" : "outbound")/"
    case .KMBRouteData(let route, let isInbound, let serviceType):
      urlString =
        "https://data.etabus.gov.hk/v1/transport/kmb/route-stop/\(route)/\(isInbound ? "inbound" : "outbound")/\(serviceType)"
    case .CTBBusStopDetail(let stopId):
      urlString = "https://rt.data.gov.hk/v2/transport/citybus/stop/\(stopId)"
    case .KMBBusStopDetail(let stopId):
      urlString = "https://data.etabus.gov.hk/v1/transport/kmb/stop/\(stopId)"
    case .CTBArrivalEstimation(let stopId, let route):
      urlString = "https://rt.data.gov.hk/v2/transport/citybus/eta/CTB/\(stopId)/\(route)/"
    case .KMBArrivalEstimation(let stopId, let route, let serviceType):
      urlString =
        "https://data.etabus.gov.hk/v1/transport/kmb/eta/\(stopId)/\(route)/\(serviceType)"
    case .fare:
      urlString = "https://static.data.gov.hk/td/routes-fares-xml/ROUTE_BUS.xml"
    }

    return URL(string: urlString!)!

  }

  var header: [HTTPHeader] {

    let dict: [String: String] =
      switch self {
      case .CTBRoutes, .KMBRoutes, .CTBRouteData, .KMBRouteData, .CTBBusStopDetail,
        .KMBBusStopDetail, .CTBArrivalEstimation, .KMBArrivalEstimation, .fare:
        [:]

      }

    return dict.map { (key: String, value: String) in
      HTTPHeader(name: key, value: value)
    }

  }

  var parameter: [String: String] {

    switch self {
    case .CTBRoutes, .KMBRoutes, .CTBRouteData, .KMBRouteData, .CTBBusStopDetail, .KMBBusStopDetail,
      .CTBArrivalEstimation, .KMBArrivalEstimation, .fare:
      return [:]

    }

  }

}

class APIManager: APIManagerType, @unchecked Sendable {

  static let shared: APIManagerType = APIManager()

  var isReachable: CurrentValueSubject<Bool, Never> = CurrentValueSubject(true)

  private let reachabilityMAnager = NetworkReachabilityManager()

  private let session: Alamofire.Session = Session()

  private init() {
    reachabilityMAnager?.startListening(
      onQueue: .main,
      onUpdatePerforming: { status in

        switch status {
        case .reachable:
          self.isReachable.value = true
        default:
          self.isReachable.value = false
        }

      })

    session.sessionConfiguration.timeoutIntervalForRequest = 10
  }

  func call(api: API) async throws -> Data? {
    let response = await self.session.request(
      api.url, method: HTTPMethod(rawValue: self.getMethod(forAPI: api)),
      parameters: api.parameter, headers: HTTPHeaders(api.header)
    ).serializingData().response

    if let error = response.error {
      throw error
    } else {
      return response.data
    }
  }

  func getMethod(forAPI api: API) -> String {

    switch api {
    case .CTBRoutes, .KMBRoutes, .CTBRouteData, .KMBRouteData, .CTBBusStopDetail, .KMBBusStopDetail,
      .CTBArrivalEstimation, .KMBArrivalEstimation, .fare:
      return "GET"
    }
  }

}
