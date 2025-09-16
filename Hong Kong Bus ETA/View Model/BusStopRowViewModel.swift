//
//  BusStopRowViewModel.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 22/1/2024.
//

import Foundation
import Observation

@MainActor
protocol BusStopRowViewModelDelegate: AnyObject {

  func busStopRowViewModel(
    _ viewModel: BusStopRowViewModel, didRequestDisplayBusStop busStop: any BusStopModel,
    withDetails details: any BusStopDetailModel)

  func busStopRowViewModel(
    _ viewModel: BusStopRowViewModel, didUpdateBusStop busStop: any BusStopModel,
    withDetails details: (any BusStopDetailModel)?)
}

@MainActor
@Observable
class BusStopRowViewModel {

  let busStop: any BusStopModel

  var apiManager: APIManagerType

  var busStopDetail: (any BusStopDetailModel)?

  var error: (any Error)?

  weak var delegate: BusStopRowViewModelDelegate?

  init(busStop: any BusStopModel, apiManager: APIManagerType = APIManager.shared) {
    self.busStop = busStop
    self.apiManager = apiManager

    fetch()
  }

  func fetch() {

    error = nil

    if let ctbBusStop = busStop as? CTBBusStopModel {
      fetchCTBBusStopDetail(busStop: ctbBusStop)

    } else if let kmbBusStop = busStop as? KMBBusStopModel {
      fetchKMBBusStopDetail(busStop: kmbBusStop)
    }

  }

  private func fetchCTBBusStopDetail(busStop: CTBBusStopModel) {

    guard let stopId = busStop.stopId else { return }

    Task {

      do {
        guard let data = try await apiManager.call(api: .CTBBusStopDetail(stopId: stopId)),
          let response = try? JSONDecoder().decode(
            APIResponseModel<CTBBusStopDetailModel>.self, from: data)
        else {
          return
        }

        busStopDetail = response.data
        self.delegate?.busStopRowViewModel(
          self, didUpdateBusStop: self.busStop, withDetails: busStopDetail)

      } catch {
        self.error = error
      }
    }

  }

  private func fetchKMBBusStopDetail(busStop: KMBBusStopModel) {

    guard let stopId = busStop.stopId else { return }

    Task {

      do {
        guard let data = try await apiManager.call(api: .KMBBusStopDetail(stopId: stopId)),
          let response = try? JSONDecoder().decode(
            APIResponseModel<KMBBusStopDetailModel>.self, from: data)
        else {
          return
        }

        busStopDetail = response.data

        self.delegate?.busStopRowViewModel(
          self, didUpdateBusStop: self.busStop, withDetails: busStopDetail)

      } catch {
        self.error = error
      }
    }

  }

  func onBusStopSelected() {
    guard let busStopDetail else { return }

    delegate?.busStopRowViewModel(
      self, didRequestDisplayBusStop: busStop, withDetails: busStopDetail)

  }
}
