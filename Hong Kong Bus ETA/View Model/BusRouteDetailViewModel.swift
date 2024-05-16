//
//  BusRouteDetailViewModel.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 22/1/2024.
//

import Combine
import CoreLocation
import Foundation

protocol BusRouteDetailViewModelDelegate: AnyObject {
  func busRouteDetailViewModel(
    _ viewModel: BusRouteDetailViewModel, didRequestDisplayBusStop busStop: any BusStopModel,
    isInbound: Bool, withDetails details: any BusStopDetailModel)

}

class BusRouteDetailViewModel: NSObject, ObservableObject {

  let route: any BusRouteModel

  var apiManager: APIManagerType

  var locationManager: CLLocationManagerType

  let busRoutesDataProvider: BusRoutesDataProviderType

  @Published
  var stopList: [any BusStopModel]? = nil {
    didSet {
      if let stopList {
        for busStop in stopList {
          let vm = makeBusStopRowViewModel(busStop: busStop)
          // make sure all bus stop details are loaded at the beginning for the map
        }
      }
    }

  }

  @Published
  var displayedList: [any BusStopModel]? = nil

  @Published
  var closestBusStop: (any BusStopDetailModel, Double)? = nil

  @Published
  var currentLocation: CLLocation? = nil

  @Published
  var busFare: BusFareModel? = nil

  @Published
  var selectedMapMarker: String? = nil

  @Published
  var filter: String = ""

  @Published
  var showMap: Bool = false

  @Published
  var hasError: Bool = false

  @Published
  var busStopDetailsDict: [String: any BusStopDetailModel] = [:]

  @Published
  var hasLocationPermission: Bool = false

  weak var delegate: BusRouteDetailViewModelDelegate?

  private var cancellable = Set<AnyCancellable>()

  let userDefaults: UserDefaultsType

  private let showMapTipKey = "showMapTip"

  init(
    route: any BusRouteModel, apiManager: APIManagerType = APIManager.shared,
    locationManager: CLLocationManagerType = CLLocationManager(),
    busRoutesDataProvider: BusRoutesDataProviderType = BusRoutesDataProvider.shared,
    userDefaults: UserDefaultsType = UserDefaults.standard
  ) {
    self.route = route
    self.apiManager = apiManager
    self.locationManager = locationManager
    self.busRoutesDataProvider = busRoutesDataProvider
    self.userDefaults = userDefaults

    super.init()

    setupPublisher()
    fetch()

    self.locationManager.delegate = self

    let showMapTip = userDefaults.object(forKey: showMapTipKey) as? Bool ?? true
    MapTip.showMapTip = showMapTip

    if showMapTip {
      self.userDefaults.setValue(false, forKey: showMapTipKey)
    }

    askLocationPermission()
  }

  func setupPublisher() {

    $showMap.sink { [weak self] showMap in
      if let self {
        MapTip.showMapTip = false
      }
    }.store(in: &cancellable)

    apiManager.isReachable.dropFirst().sink { [weak self] reachable in
      if reachable {
        self?.fetch()
      }
    }.store(in: &cancellable)

    $filter.debounce(for: 0.3, scheduler: DispatchQueue.main)
      .combineLatest($stopList).sink { filter, stopList in

        let filterList = filter.lowercased().split(separator: " ").map { s in
          String(s)
        }

        if filterList.count > 0 {
          self.displayedList = stopList?.filter({ busStop in

            guard let stopId = busStop.stopId, let detail = self.busStopDetailsDict[stopId] else {
              return false
            }

            for keyword in filterList {

              if (detail.nameEn?.lowercased().contains(keyword.lowercased()) ?? false)
                || (detail.nameTC?.contains(keyword) ?? false)
                || (detail.nameSC?.contains(keyword) ?? false)
              {
                continue
              }
              return false
            }

            return true

          })
        } else {
          self.displayedList = stopList
        }

      }.store(in: &cancellable)

    $selectedMapMarker.sink { [weak self] stopId in

      guard let stopId, let self else { return }

      self.onBusStopSelected(stopId: stopId)

    }.store(in: &cancellable)

    busRoutesDataProvider.busFareDict.map { [weak self] dict -> BusFareModel? in

      guard let dict, let route = self?.route, let companyCode = route.company?.rawValue,
        let routeNumber = route.route
      else { return nil }

      let key = "\(companyCode)_\(routeNumber)"

      if let busFare = dict[key] {
        return busFare
      }

      for value in dict.values {

        if value.companyCode.contains(companyCode), value.routeNumber == routeNumber {
          return value
        }

      }

      return nil

    }.assign(to: &$busFare)

    $currentLocation.combineLatest($busStopDetailsDict).receive(on: DispatchQueue.main).map {
      location, busStopsDetailsDict -> (BusStopDetailModel, Double)? in

      guard let location else {

        return nil
      }

      let sortedBusStops = busStopsDetailsDict.values.sorted { a, b in

        guard let aLat = Double(a.position?.0 ?? ""),
          let aLong = Double(a.position?.1 ?? ""),
          let bLat = Double(b.position?.0 ?? ""),
          let bLong = Double(b.position?.1 ?? "")
        else { return false }

        let aCoord = CLLocation(latitude: aLat, longitude: aLong)
        let bCoord = CLLocation(latitude: bLat, longitude: bLong)

        return location.distance(from: aCoord) < location.distance(from: bCoord)

      }

      if let closestBusStop = sortedBusStops.first,
        let lat = Double(closestBusStop.position?.0 ?? ""),
        let long = Double(closestBusStop.position?.1 ?? "")
      {

        let distance = location.distance(from: CLLocation(latitude: lat, longitude: long))
        if distance < 1000 {
          return (closestBusStop, distance)
        }
      }

      return nil
    }.assign(to: &$closestBusStop)

  }

  func fetch() {

    stopList = nil

    if let ctbRoute = route as? CTBBusRouteModel {

      fetchCTBRouteData(route: ctbRoute)

    } else if let kmbRoute = route as? KMBBusRouteModel {
      fetchKMBRouteData(route: kmbRoute)
    }

    if busFare == nil {
      busRoutesDataProvider.fetchBusFareInfo()
    }

  }

  private func fetchKMBRouteData(route: KMBBusRouteModel) {
    apiManager.call(
      api: .KMBRouteData(
        route: route.route ?? "", isInbound: route.isInbound, serviceType: route.serviceType ?? "")
    ).sink { [weak self] completion in

      switch completion {
      case .failure(let error):
        self?.stopList = []
        self?.hasError = true
        break
      default:
        self?.hasError = false
        break

      }

    } receiveValue: { [weak self] data in

      if let self, let data,
        let response = try? JSONDecoder().decode(
          APIResponseModel<[KMBBusStopModel]>.self, from: data)
      {

        self.stopList = response.data
      }

    }.store(in: &cancellable)

  }

  private func fetchCTBRouteData(route: CTBBusRouteModel) {
    apiManager.call(api: .CTBRouteData(route: route.route ?? "", isInbound: route.isInbound)).sink {
      [weak self] completion in

      switch completion {
      case .failure(let error):
        self?.stopList = []
        self?.hasError = true
        break
      default:
        self?.hasError = false
        break

      }

    } receiveValue: { [weak self] data in

      if let self, let data,
        let response = try? JSONDecoder().decode(
          APIResponseModel<[CTBBusStopModel]>.self, from: data)
      {

        self.stopList = response.data
      }

    }.store(in: &cancellable)

  }

  private var busStopRowViewModeDict: [String: BusStopRowViewModel] = [:]

  func makeBusStopRowViewModel(busStop: any BusStopModel) -> BusStopRowViewModel {

    guard let stopId = busStop.stopId,
      let vm = busStopRowViewModeDict[stopId]
    else {
      let vm = BusStopRowViewModel(busStop: busStop)

      vm.delegate = self

      busStopRowViewModeDict[busStop.stopId ?? ""] = vm

      return vm
    }

    return vm

  }

  func getDestinationDescription() -> String {

    let destination = self.route.destination()

    return String(localized: "to") + destination
  }

  func askLocationPermission() {

    self.locationManager.requestWhenInUseAuthorization()
    self.locationManager.startUpdatingLocation()
  }

  func resetFilter() {
    filter = ""
    displayedList = stopList
  }
}

extension BusRouteDetailViewModel: CLLocationManagerDelegate {
  func locationManager(
    _ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus
  ) {

    switch status {

    case .authorizedAlways, .authorizedWhenInUse, .authorized:
      hasLocationPermission = true

    default:
      hasLocationPermission = false
    }

  }

  func onBusStopSelected(stopId: String) {

    guard
      let busStopModel = self.stopList?.first(where: { busStopModel in
        busStopModel.stopId == stopId
      }), let busStopDetailModel = self.busStopDetailsDict[stopId]
    else { return }

    self.delegate?.busRouteDetailViewModel(
      self, didRequestDisplayBusStop: busStopModel, isInbound: route.isInbound,
      withDetails: busStopDetailModel)
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    currentLocation = locations.first
  }
}

extension BusRouteDetailViewModel: BusStopRowViewModelDelegate {
  func busStopRowViewModel(
    _ viewModel: BusStopRowViewModel, didRequestDisplayBusStop busStop: any BusStopModel,
    withDetails details: any BusStopDetailModel
  ) {
    delegate?.busRouteDetailViewModel(
      self, didRequestDisplayBusStop: busStop, isInbound: busStop.isInbound, withDetails: details)
  }

  func busStopRowViewModel(
    _ viewModel: BusStopRowViewModel, didUpdateBusStop busStop: any BusStopModel,
    withDetails details: (any BusStopDetailModel)?
  ) {
    if let stopId = busStop.stopId, let details {
      busStopDetailsDict[stopId] = details
    }
  }
}
