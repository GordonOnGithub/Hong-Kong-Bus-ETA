//
//  DataStorage.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 24/1/2024.
//

import Combine
import Foundation
import SwiftData

protocol BusETAStorageType: Sendable {

  var cache: CurrentValueSubject<[BusStopETA.ID: BusStopETA], Never> { get }

  func fetch() throws -> [BusStopETA]
  func insert(data: BusStopETA) throws
  func delete(data: BusStopETA) throws

}

class BusETAStorage: BusETAStorageType, @unchecked Sendable {

  static let shared = BusETAStorage()

  private let container: ModelContainer

  var cache: CurrentValueSubject<[BusStopETA.ID: BusStopETA], Never> = CurrentValueSubject([:])

  private var cancellable = Set<AnyCancellable>()

  private init() {

    let schema = Schema([
      BusStopETA.self
    ])

    self.container = try! ModelContainer(for: schema)

  }

  func fetch() throws -> [BusStopETA] {
    let context = ModelContext(self.container)

    let result = try context.fetch(FetchDescriptor<BusStopETA>())

    var updatedCache: [BusStopETA.ID: BusStopETA] = [:]

    for data in result {
      updatedCache[data.id] = data
    }

    self.cache.value = updatedCache

    return result
  }

  func insert(data: BusStopETA) throws {
    let context = ModelContext(self.container)

    context.insert(data)

    try context.save()

    var updatedCache = self.cache.value

    updatedCache[data.id] = data

    self.cache.value = updatedCache

  }

  func delete(data: BusStopETA) throws {
    let context = ModelContext(self.container)

    var updatedCache = self.cache.value

    updatedCache.removeValue(forKey: data.id)

    self.cache.value = updatedCache

    let key = data.id

    let predicate = #Predicate<BusStopETA> { d in
      d.id == key
    }

    try context.delete(model: BusStopETA.self, where: predicate)
    try context.save()
  }

}
