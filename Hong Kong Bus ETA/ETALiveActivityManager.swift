//
//  ETALiveActivityManager.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 24/3/2025.
//

import ActivityKit
import Foundation

protocol ETALiveActivityManagerType: AnyObject, Sendable {
  var busStopETA: BusStopETA? { get }
  var etaLiveActivity: Activity<HongKongBusETALiveActivityAttributes>? { get }
  func start(busStopETA: BusStopETA?, destination: String, stop: String, eta: Date?)
  func update(_ etaList: [BusETAModel])
  func stop()
}

class ETALiveActivityManager: @unchecked Sendable, ETALiveActivityManagerType {

  private(set) var etaLiveActivity: Activity<HongKongBusETALiveActivityAttributes>?

  static let shared: ETALiveActivityManagerType = ETALiveActivityManager()

  private(set) var busStopETA: BusStopETA?

  private init() {}

  func start(busStopETA: BusStopETA?, destination: String, stop: String, eta: Date?) {
    Task {

      await self.etaLiveActivity?.end(
        .init(state: .init(eta: nil), staleDate: nil), dismissalPolicy: .immediate)

      self.busStopETA = busStopETA

      guard let busStopETA else { return }
      do {

        let staleDate = eta?.addingTimeInterval(900) ?? Date(timeIntervalSinceNow: 900)

        self.etaLiveActivity = try Activity<HongKongBusETALiveActivityAttributes>.request(
          attributes: .init(
            code: busStopETA.route, destination: destination, company: busStopETA.company,
            stop: stop), content: .init(state: .init(eta: eta), staleDate: staleDate))

      } catch {
        print(error)
      }
    }
  }

  func update(_ etaList: [BusETAModel]) {

    Task {

      if etaLiveActivity?.activityState == .stale || etaLiveActivity?.activityState == .ended {
        stop()
        return
      }

      let staleDate =
        etaList.first?.etaTimestamp?.addingTimeInterval(900) ?? Date(timeIntervalSinceNow: 900)

      await etaLiveActivity?.update(
        ActivityContent(state: .init(eta: etaList.first?.etaTimestamp), staleDate: staleDate))

    }

  }

  func stop() {

    Task {
      await self.etaLiveActivity?.end(
        .init(state: .init(eta: nil), staleDate: Date()), dismissalPolicy: .immediate)
      etaLiveActivity = nil
      busStopETA = nil

    }

  }

}
