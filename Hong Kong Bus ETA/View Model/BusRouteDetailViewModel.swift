//
//  BusRouteDetailViewModel.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 22/1/2024.
//

import Combine
import CoreLocation
import Foundation
import MapKit

@MainActor
protocol BusRouteDetailViewModelDelegate: AnyObject {
  func busRouteDetailViewModel(
    _ viewModel: BusRouteDetailViewModel, didRequestDisplayBusStop busStop: any BusStopModel,
    isInbound: Bool, withDetails details: any BusStopDetailModel)

}
@MainActor
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
  var routeSummary: BusRouteSummaryModel? = nil

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
        self.selectedMapMarker = nil
      }
    }.store(in: &cancellable)

    apiManager.isReachable.dropFirst().sink { [weak self] reachable in
      if reachable {
        self?.fetch()
      }
    }.store(in: &cancellable)

    $filter.debounce(for: 0.3, scheduler: DispatchQueue.main)
      .combineLatest($stopList).sink { [weak self] filter, stopList in

        guard let self else { return }

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

    busRoutesDataProvider.busRouteSummaryDict
      .receive(on: DispatchQueue.main)
      .map { [weak self] dict -> BusRouteSummaryModel? in

        guard let dict, let route = self?.route, let companyCode = route.company?.rawValue,
          let routeNumber = route.route,
          let destination = route.destinationEn
        else { return nil }

        let key = "\(companyCode)_\(routeNumber)_\(destination)"

        if let busFare = dict[key] {
          return busFare
        }

        for value in dict.values {

          if value.companyCode.contains(companyCode), value.routeNumber == routeNumber {
            return value
          }

        }

        return nil

      }.assign(to: &$routeSummary)

    $currentLocation.combineLatest($busStopDetailsDict).map {
      location, busStopsDetailsDict -> (BusStopDetailModel, CLLocationCoordinate2D)? in

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
        if distance < 500 {
          return (closestBusStop, location.coordinate)
        }
      }

      return nil
    }
    .throttle(for: 2, scheduler: DispatchQueue.main, latest: true)
    .flatMap({ tuple in

      guard let tuple else {
        return Just<(BusStopDetailModel, Double)?>.init(nil).setFailureType(to: Never.self)
          .eraseToAnyPublisher()
      }

      return Future<(BusStopDetailModel, Double)?, Never> { completion in
        Task {
          let request = MKDirections.Request()

          request.source = MKMapItem(placemark: MKPlacemark(coordinate: tuple.1))

          let lat = Double(tuple.0.position?.0 ?? "") ?? 0
          let long = Double(tuple.0.position?.1 ?? "") ?? 0
          request.destination = MKMapItem(
            placemark: MKPlacemark(
              coordinate: CLLocationCoordinate2D(latitude: lat, longitude: long)))

          request.transportType = .walking

          if let result = try? await MKDirections.init(request: request).calculateETA() {

            completion(.success((tuple.0, result.expectedTravelTime / 60)))
          } else {
            completion(.success(nil))
          }

        }
      }.eraseToAnyPublisher()

    })
    .receive(on: DispatchQueue.main)
    .assign(to: &$closestBusStop)

  }

  func fetch() {

    stopList = nil

    if let ctbRoute = route as? CTBBusRouteModel {

      fetchCTBRouteData(route: ctbRoute)

    } else if let kmbRoute = route as? KMBBusRouteModel {
      fetchKMBRouteData(route: kmbRoute)
    }

    if routeSummary == nil {
      busRoutesDataProvider.fetchBusFareInfo()
    }

  }

  private func fetchKMBRouteData(route: KMBBusRouteModel) {

    Task {

      do {
        if let data = try await apiManager.call(
          api: .KMBRouteData(
            route: route.route ?? "", isInbound: route.isInbound,
            serviceType: route.serviceType ?? "")
        ),
          let response = try? JSONDecoder().decode(
            APIResponseModel<[KMBBusStopModel]>.self, from: data)
        {
          self.stopList = response.data
          self.hasError = false

        } else {
          self.stopList = []
          self.hasError = false
        }

      } catch {
        self.stopList = []
        self.hasError = true
      }
    }

  }

  private func fetchCTBRouteData(route: CTBBusRouteModel) {

    Task {

      do {
        if let data = try await apiManager.call(
          api: .CTBRouteData(route: route.route ?? "", isInbound: route.isInbound)),
          let response = try? JSONDecoder().decode(
            APIResponseModel<[CTBBusStopModel]>.self, from: data)
        {
          self.stopList = response.data
          self.hasError = false

        } else {
          self.stopList = []
          self.hasError = false
        }

      } catch {
        self.stopList = []
        self.hasError = true
      }
    }

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
  nonisolated func locationManager(
    _ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus
  ) {
    Task { @MainActor in
      switch status {

      case .authorizedAlways, .authorizedWhenInUse, .authorized:
        hasLocationPermission = true

      default:
        hasLocationPermission = false
      }
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

  nonisolated func locationManager(
    _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]
  ) {
    Task { @MainActor in
      currentLocation = locations.first
    }
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

extension MKDirections.ETAResponse: @unchecked Sendable {}
