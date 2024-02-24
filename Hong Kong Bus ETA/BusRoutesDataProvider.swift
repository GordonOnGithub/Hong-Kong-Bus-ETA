//
//  BusRoutesDataProvider.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 22/1/2024.
//

import Combine
import Foundation

protocol BusRoutesDataProviderType {
  var ctbRouteDict: CurrentValueSubject<[String: CTBBusRouteModel]?, Never> { get }
  var kmbRouteDict: CurrentValueSubject<[String: KMBBusRouteModel]?, Never> { get }

  static var shared: BusRoutesDataProviderType { get }

  func fetchCTBRoutes()

  func fetchKMBRoutes()

  func getCacheKey(company: BusCompany, route: String, serviceType: String?, isInbound: Bool)
    -> String
}

class BusRoutesDataProvider: BusRoutesDataProviderType {

  var apiManager: APIManagerType

  let userDefaults: UserDefaultsType

  var ctbRouteDict: CurrentValueSubject<[String: CTBBusRouteModel]?, Never> = CurrentValueSubject(
    nil)

  var kmbRouteDict: CurrentValueSubject<[String: KMBBusRouteModel]?, Never> = CurrentValueSubject(
    nil)

  static var shared: BusRoutesDataProviderType = BusRoutesDataProvider()

  private var cancellable = Set<AnyCancellable>()

  private let ctbRoutesDataKey = "ctbRoutesData"

  private let kmbRoutesDataKey = "kmbRoutesData"

  private init(
    apiManager: APIManagerType = APIManager.shared,
    userDefaults: UserDefaultsType = UserDefaults.standard
  ) {
    self.apiManager = apiManager
    self.userDefaults = userDefaults

    loadCacheIfAvailalbe()
    fetchCTBRoutes()
    fetchKMBRoutes()
  }

  func loadCacheIfAvailalbe() {

    if let ctbRouteData = userDefaults.object(forKey: ctbRoutesDataKey) as? Data {

      let routes = parseCTBRouteData(ctbRouteData)
      if ctbRouteDict.value?.isEmpty ?? true {
        handleCTBRoutesUpdate(list: routes)
      }

    }

    if let kmbRouteData = userDefaults.object(forKey: kmbRoutesDataKey) as? Data {

      let routes = parseKMBRouteData(kmbRouteData)
      if kmbRouteDict.value?.isEmpty ?? true {
        handleKMBRoutesUpdate(list: routes)
      }

    }

  }

  private func parseCTBRouteData(_ data: Data?) -> [CTBBusRouteModel] {
    var list: [CTBBusRouteModel] = []

    guard let data else { return list }

    let decoder = JSONDecoder()

    if let response = try? decoder.decode(APIResponseModel<[CTBBusRouteModel]>.self, from: data) {

      list = response.data

      list.append(
        contentsOf: response.data.map({ route in

          CTBBusRouteModel(
            originTC: route.originTC, originSC: route.originSC, originEn: route.originEn,
            destinationTC: route.destinationTC, destinationSC: route.destinationSC,
            destinationEn: route.destinationEn, route: route.route,
            timestamp: route.timestamp,
            isInbound: !route.isInbound)

        }))

    }

    return list

  }

  private func handleCTBRoutesUpdate(list: [CTBBusRouteModel]) {
    var cache: [String: CTBBusRouteModel] = [:]
    for route in list {

      guard let company = route.company, let routeCode = route.route else { continue }

      cache[
        self.getCacheKey(
          company: company, route: routeCode, serviceType: nil, isInbound: route.isInbound)] = route
    }

    self.ctbRouteDict.value = cache
  }

  func fetchCTBRoutes() {

    apiManager.call(api: .CTBRoutes).map { [weak self] data -> [CTBBusRouteModel] in

      guard let self else { return [] }

      let routes = self.parseCTBRouteData(data)

      if !routes.isEmpty {
        self.userDefaults.setValue(data, forKey: self.ctbRoutesDataKey)
      }

      return routes

    }.replaceError(with: [])
      .sink { [weak self] list in

        self?.handleCTBRoutesUpdate(list: list)

      }.store(in: &cancellable)

  }

  private func parseKMBRouteData(_ data: Data?) -> [KMBBusRouteModel] {
    guard let data else { return [] }

    let decoder = JSONDecoder()

    if let response = try? decoder.decode(APIResponseModel<[KMBBusRouteModel]>.self, from: data) {

      return response.data

    }

    return []
  }

  private func handleKMBRoutesUpdate(list: [KMBBusRouteModel]) {
    var cache: [String: KMBBusRouteModel] = [:]
    for route in list {

      guard let company = route.company, let routeCode = route.route else { continue }

      cache[
        self.getCacheKey(
          company: company, route: routeCode, serviceType: route.serviceType,
          isInbound: route.isInbound)] = route
    }

    self.kmbRouteDict.value = cache
  }

  func fetchKMBRoutes() {

    apiManager.call(api: .KMBRoutes).map({ [weak self] data -> [KMBBusRouteModel] in

      guard let self else { return [] }

      let routes = self.parseKMBRouteData(data)

      if !routes.isEmpty {
        self.userDefaults.setValue(data, forKey: self.kmbRoutesDataKey)
      }

      return routes

    }).replaceError(with: [])
      .sink(receiveValue: { [weak self] list in

        self?.handleKMBRoutesUpdate(list: list)

      }).store(in: &cancellable)
  }

  func getCacheKey(company: BusCompany, route: String, serviceType: String?, isInbound: Bool)
    -> String
  {

    return company.rawValue + "_" + route + "_" + (serviceType ?? "") + (isInbound ? "I" : "O")

  }
}
