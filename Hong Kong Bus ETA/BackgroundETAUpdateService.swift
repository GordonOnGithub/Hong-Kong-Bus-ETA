//
//  BackgroundETAUpdateService.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 23/3/2025.
//

import BackgroundTasks
import Foundation

protocol BackgroundETAUpdateServiceType: AnyObject, Sendable {
  var delegate: BackgroundETAUpdateServiceDelegate? { get set }
  var eta: BusStopETA? { get set }
  func registerBackgroundETAUpdateTask()
  func schedueBackgroundETAUpdateTask()
}

extension BGAppRefreshTask: @unchecked @retroactive Sendable {

}

@MainActor
protocol BackgroundETAUpdateServiceDelegate: AnyObject {
  func backgroundETAUpdateService(
    _ service: BackgroundETAUpdateService, didUpdateETA etaList: [BusETAModel],
    forBusStopETA eta: BusStopETA)
}

class BackgroundETAUpdateService: BackgroundETAUpdateServiceType, @unchecked Sendable {

  static let shared: BackgroundETAUpdateServiceType = BackgroundETAUpdateService()

  let etaBackgroundTaskIdentifieer = "com.gordonthedeveloper.hkbuseta.etaupdate"

  let apiManager: APIManagerType

  weak var eta: BusStopETA?

  weak var delegate: BackgroundETAUpdateServiceDelegate?

  private init() {

    apiManager = APIManager.shared

  }

  private var task: Task<Void, Never>?

  private var didRegisterBackgroundETAUpdateTask = false

  func registerBackgroundETAUpdateTask() {

    guard !didRegisterBackgroundETAUpdateTask else { return }

    didRegisterBackgroundETAUpdateTask = true

    BGTaskScheduler.shared.register(forTaskWithIdentifier: etaBackgroundTaskIdentifieer, using: nil)
    { [weak self] task in
      self?.handleBackgroundETAUpdateTask(task as! BGAppRefreshTask)
    }
  }

  private func handleBackgroundETAUpdateTask(_ bgTask: BGAppRefreshTask) {

    task?.cancel()

    task = Task {

      defer {
        bgTask.setTaskCompleted(success: !(task?.isCancelled ?? false))
        task = nil
        schedueBackgroundETAUpdateTask()
      }

      guard let eta else { return }

      var data: Data? = nil

      switch BusCompany(rawValue: eta.company) {
      case .CTB:
        data = try? await apiManager.call(
          api: .CTBArrivalEstimation(stopId: eta.stopId, route: eta.route))
      case .KMB:
        data = try? await apiManager.call(
          api: .KMBArrivalEstimation(
            stopId: eta.stopId, route: eta.route, serviceType: eta.serviceType ?? ""))
      case .none:
        break
      }

      guard let data, !Task.isCancelled else { return }

      guard
        let response = try? JSONDecoder().decode(APIResponseModel<[BusETAModel]>.self, from: data)
      else { return }

      let busETAList = response.data.sorted(by: { a, b in

        (a.etaTimestamp?.timeIntervalSince1970 ?? 0)
          < (b.etaTimestamp?.timeIntervalSince1970 ?? 0)
      })

      await delegate?.backgroundETAUpdateService(self, didUpdateETA: busETAList, forBusStopETA: eta)
    }

    bgTask.expirationHandler = { [weak self] in
      self?.task?.cancel()
    }

  }

  func schedueBackgroundETAUpdateTask() {

    guard let _ = eta else { return }

    let request = BGAppRefreshTaskRequest(identifier: etaBackgroundTaskIdentifieer)

    request.earliestBeginDate = Date(timeIntervalSinceNow: 300)

    do {
      try BGTaskScheduler.shared.submit(request)
    } catch {
      print(error)
    }

  }

}
