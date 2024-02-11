//
//  DataStorage.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 24/1/2024.
//

import Combine
import Foundation
import SwiftData

protocol BusETAStorageType {

  var cache: CurrentValueSubject<[BusStopETA.ID: BusStopETA], Never> { get }

  func fetch() -> AnyPublisher<[BusStopETA], Error>
  func insert(data: BusStopETA) -> AnyPublisher<Bool, Never>
  func delete(data: BusStopETA) -> AnyPublisher<Bool, Never>

}

class BusETAStorage: BusETAStorageType {

  static var shared = BusETAStorage()

  private let container: ModelContainer

  var cache: CurrentValueSubject<[BusStopETA.ID: BusStopETA], Never> = CurrentValueSubject([:])

  private var cancellable = Set<AnyCancellable>()

  private init() {

    let schema = Schema([
      BusStopETA.self
    ])

    self.container = try! ModelContainer(for: schema)

  }

  func fetch() -> AnyPublisher<[BusStopETA], Error> {

    return Future { block in
      Task {
        let context = await self.container.mainContext

        do {
          let result = try context.fetch(FetchDescriptor<BusStopETA>())

          var updatedCache: [BusStopETA.ID: BusStopETA] = [:]

          for data in result {
            updatedCache[data.id] = data
          }

          self.cache.value = updatedCache

          block(.success(result))
        } catch {
          block(.failure(error))
        }
      }

    }.receive(on: DispatchQueue.main)
      .eraseToAnyPublisher()

  }

  func insert(data: BusStopETA) -> AnyPublisher<Bool, Never> {

    return Future<Bool, Never> { block in

      Task {
        do {
          let context = await self.container.mainContext

          context.insert(data)

          try context.save()

          var updatedCache = self.cache.value

          updatedCache[data.id] = data

          self.cache.value = updatedCache

          block(.success(true))
        } catch {
          block(.success(false))
        }

      }

    }.receive(on: DispatchQueue.main)
      .eraseToAnyPublisher()
  }

  func delete(data: BusStopETA) -> AnyPublisher<Bool, Never> {

    return Future<Bool, Never> { block in

      Task {
        do {
          let context = await self.container.mainContext

          var updatedCache = self.cache.value

          updatedCache.removeValue(forKey: data.id)

          self.cache.value = updatedCache

          let key = data.id

          let predicate = #Predicate<BusStopETA> { d in
            d.id == key
          }

          try context.delete(model: BusStopETA.self, where: predicate)
          try context.save()

          block(.success(true))
        } catch {
          block(.success(false))
        }
      }

    }.receive(on: DispatchQueue.main)
      .eraseToAnyPublisher()

  }

}
