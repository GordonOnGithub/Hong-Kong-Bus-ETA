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

  init(
    route: any BusRouteModel, apiManager: APIManagerType = APIManager.shared,
    locationManager: CLLocationManagerType = CLLocationManager()
  ) {
    self.route = route
    self.apiManager = apiManager
    self.locationManager = locationManager

    super.init()

    setupPublisher()
    fetch()

    self.locationManager.delegate = self

  }

  func setupPublisher() {

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

      guard let stopId, let self,
        let busStopModel = self.stopList?.first(where: { busStopModel in
          busStopModel.stopId == stopId
        }), let busStopDetailModel = self.busStopDetailsDict[stopId]
      else { return }

      self.delegate?.busRouteDetailViewModel(
        self, didRequestDisplayBusStop: busStopModel, isInbound: route.isInbound,
        withDetails: busStopDetailModel)

    }.store(in: &cancellable)
  }

  func fetch() {

    stopList = nil

    if let ctbRoute = route as? CTBBusRouteModel {

      fetchCTBRouteData(route: ctbRoute)

    } else if let kmbRoute = route as? KMBBusRouteModel {
      fetchKMBRouteData(route: kmbRoute)
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

    guard showMap else { return }
    self.locationManager.requestWhenInUseAuthorization()
    self.locationManager.startUpdatingLocation()
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
