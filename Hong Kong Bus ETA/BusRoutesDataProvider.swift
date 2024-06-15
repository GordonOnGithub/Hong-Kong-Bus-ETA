//
//  BusRoutesDataProvider.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 22/1/2024.
//

import Combine
import Foundation

protocol BusRoutesDataProviderType: Sendable {
  var ctbRouteDict: CurrentValueSubject<[String: CTBBusRouteModel]?, Never> { get }
  var kmbRouteDict: CurrentValueSubject<[String: KMBBusRouteModel]?, Never> { get }
  var busRouteSummaryDict: CurrentValueSubject<[String: BusRouteSummaryModel]?, Never> { get }

  static var shared: BusRoutesDataProviderType { get }

  func fetchCTBRoutes()

  func fetchKMBRoutes()

  func fetchBusFareInfo()

  func getCacheKey(company: BusCompany, route: String, serviceType: String?, isInbound: Bool)
    -> String
}

class BusRoutesDataProvider: BusRoutesDataProviderType, @unchecked Sendable {

  let apiManager: APIManagerType

  let userDefaults: UserDefaultsType

  var ctbRouteDict: CurrentValueSubject<[String: CTBBusRouteModel]?, Never> = CurrentValueSubject(
    nil)

  var kmbRouteDict: CurrentValueSubject<[String: KMBBusRouteModel]?, Never> = CurrentValueSubject(
    nil)

  var busRouteSummaryDict: CurrentValueSubject<[String: BusRouteSummaryModel]?, Never> =
    CurrentValueSubject(
      nil)

  static let shared: BusRoutesDataProviderType = BusRoutesDataProvider()

  private var cancellable = Set<AnyCancellable>()

  private let ctbRoutesDataKey = "ctbRoutesData"

  private let kmbRoutesDataKey = "kmbRoutesData"

  private let busFaresDataKey = "busFaresData"

  private init(
    apiManager: APIManagerType = APIManager.shared,
    userDefaults: UserDefaultsType = UserDefaults.standard
  ) {
    self.apiManager = apiManager
    self.userDefaults = userDefaults

    Task {
      await loadCTBCacheIfAvailalbe()
    }

    Task {
      await loadKMBCacheIfAvailalbe()
    }

    Task {
      await loadBusFareCacheIfAvailalbe()
    }

    fetchCTBRoutes()
    fetchKMBRoutes()

    fetchBusFareInfo()
  }

  func loadCTBCacheIfAvailalbe() async {

    if let ctbRouteData = userDefaults.object(forKey: ctbRoutesDataKey) as? Data {

      let routes = parseCTBRouteData(ctbRouteData)
      if ctbRouteDict.value?.isEmpty ?? true {
        handleCTBRoutesUpdate(list: routes)
      }

    }

  }

  func loadKMBCacheIfAvailalbe() async {

    if let kmbRouteData = userDefaults.object(forKey: kmbRoutesDataKey) as? Data {

      let routes = parseKMBRouteData(kmbRouteData)
      if kmbRouteDict.value?.isEmpty ?? true {
        handleKMBRoutesUpdate(list: routes)
      }

    }

  }

  func loadBusFareCacheIfAvailalbe() async {

    if let busFaresData = userDefaults.object(forKey: busFaresDataKey) as? Data {
      parseBusFareData(busFaresData)
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

    ctbRouteDict.send(cache)
  }

  func fetchCTBRoutes() {

    Task {
      do {
        let data = try await apiManager.call(api: .CTBRoutes)

        let routes: [CTBBusRouteModel] =
          if let data {
            parseCTBRouteData(data)
          } else {
            []
          }

        if !routes.isEmpty {
          self.userDefaults.setValue(data, forKey: self.ctbRoutesDataKey)
        }

        handleCTBRoutesUpdate(list: routes)

      } catch {
        handleCTBRoutesUpdate(list: [])
      }
    }

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

    kmbRouteDict.send(cache)
  }

  func fetchKMBRoutes() {

    Task {
      do {
        let data = try await apiManager.call(api: .KMBRoutes)

        let routes: [KMBBusRouteModel] =
          if let data {
            parseKMBRouteData(data)
          } else {
            []
          }

        if !routes.isEmpty {
          self.userDefaults.setValue(data, forKey: self.kmbRoutesDataKey)
        }

        handleKMBRoutesUpdate(list: routes)

      } catch {
        handleKMBRoutesUpdate(list: [])
      }
    }
  }

  func getCacheKey(company: BusCompany, route: String, serviceType: String?, isInbound: Bool)
    -> String
  {

    return company.rawValue + "_" + route + "_" + (serviceType ?? "") + (isInbound ? "I" : "O")

  }

  func fetchBusFareInfo() {

    Task {
      do {
        if let data = try await apiManager.call(api: .fare) {

          parseBusFareData(data)

          if !(busRouteSummaryDict.value?.isEmpty ?? true) {
            self.userDefaults.setValue(data, forKey: self.busFaresDataKey)

          }
        }
      } catch {
        print(error)
      }
    }

  }

  private func parseBusFareData(_ data: Data) {

    let parser = XMLParser(data: data)

    let delegate = BusRouteSummaryXMLParserDelegate()

    parser.delegate = delegate

    parser.parse()

    busRouteSummaryDict.send(delegate.busRouteSummaryDict)

  }
}

class BusRouteSummaryXMLParserDelegate: NSObject, XMLParserDelegate {

  var companyCode: String?
  var routeNumber: String?
  var fullFare: String?
  var specialType: BusRouteSummaryModel.BusRouteSpecialType?
  var jouneryTime: String?
  var serviceMode: String?
  var destination: String?

  var currentElement: BusFareXMLElement?

  var busRouteSummaryDict: [String: BusRouteSummaryModel] = [:]

  enum BusFareXMLElement: String {

    case routeId = "ROUTE_ID"
    case companyCode = "COMPANY_CODE"
    case routeNumber = "ROUTE_NAMEE"
    case fullFare = "FULL_FARE"
    case specialType = "SPECIAL_TYPE"
    case jouneryTime = "JOURNEY_TIME"
    case serviceMode = "SERVICE_MODE"
    case destination = "LOC_END_NAMEE"
  }

  func parser(
    _ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
    qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]
  ) {

    if let element = BusFareXMLElement(rawValue: elementName) {
      currentElement = element
    }

    if currentElement == .routeId {
      self.companyCode = nil
      self.routeNumber = nil
      self.fullFare = nil
      self.specialType = nil
      self.jouneryTime = nil
      self.serviceMode = nil
      self.destination = nil
    }

  }

  func parser(_ parser: XMLParser, foundCharacters string: String) {

    if !string.isEmpty, string != "\n" {

      switch currentElement {
      case .companyCode:
        if companyCode == nil {
          companyCode = string
        }

      case .routeNumber:
        if routeNumber == nil {
          routeNumber = string
        }

      case .fullFare:
        if fullFare == nil {
          fullFare = string
        }

      case .specialType:
        if specialType == nil {
          specialType = BusRouteSummaryModel.BusRouteSpecialType(rawValue: string)
        }

      case .jouneryTime:
        if jouneryTime == nil {
          jouneryTime = string
        }

      case .serviceMode:
        if serviceMode == nil {
          serviceMode = string
        }
      case .destination:
        if destination == nil {
          destination = string
        }

      default:
        break
      }

    }

  }

  func parser(
    _ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
    qualifiedName qName: String?
  ) {

    if let companyCode, let routeNumber,
      let fullFare, let specialType, let jouneryTime, let serviceMode, let destination
    {
      let busFare = BusRouteSummaryModel(
        companyCode: companyCode, routeNumber: routeNumber, fullFare: fullFare,
        specialType: specialType, jouneryTime: jouneryTime,
        serviceMode: serviceMode, destination: destination)

      let companyCodes = companyCode.split(separator: "+")

      for company in companyCodes {

        busRouteSummaryDict["\(company)_\(routeNumber)_\(destination)"] = busFare
      }
    }

    currentElement = nil

  }

}
