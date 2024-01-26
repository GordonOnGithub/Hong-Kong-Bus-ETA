//
//  DataStorage.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 24/1/2024.
//

import Foundation
import SwiftData
import Combine

protocol DataStorageType {
    
    associatedtype PersistentModelType : PersistentModel
    
    var cache : CurrentValueSubject<[PersistentModelType.ID: PersistentModelType], Never> { get }
    
    func fetch() -> AnyPublisher<[PersistentModelType],Error>
    func insert(data: PersistentModelType) -> AnyPublisher<Bool, Never>
    func delete(data : PersistentModelType) -> AnyPublisher<Bool, Never>
    
}

class BusETAStorage {
    
    
    static var shared : DataStorage<BusStopETA> = DataStorage<BusStopETA>()
    
    private init(){
        
    }
}

class DataStorage<U: PersistentModel> : DataStorageType {
    
    typealias PersistentModelType = U
    
    private let container : ModelContainer

    var cache : CurrentValueSubject<[PersistentModelType.ID: PersistentModelType], Never> = CurrentValueSubject([:])

    
    private var cancellable = Set<AnyCancellable>()

    init(){
        
        let schema = Schema([
            PersistentModelType.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        
        self.container = try! ModelContainer(for: schema, configurations: [modelConfiguration])
        
        Task {
            let container = await container.mainContext
            container.autosaveEnabled = true
        }
    }
        
    func fetch() -> AnyPublisher<[PersistentModelType],Error> {
        
        return Future { block in
            Task {
                let context = await self.container.mainContext
                
                do {
                    let result = try context.fetch(FetchDescriptor<PersistentModelType>())
                    
                    
                    var updatedCache : [PersistentModelType.ID: PersistentModelType] = [:]
                    
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
    
    func insert(data: PersistentModelType) -> AnyPublisher<Bool, Never> {
        
        return Future<Bool, Never> { block in
            
            Task {
                let context = await self.container.mainContext
                
                context.insert(data)
                
                var updatedCache = self.cache.value
                
                updatedCache[data.id] = data
                
                self.cache.value = updatedCache
                
                block(.success(true))

            }
            
            
        }.receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    func delete(data : PersistentModelType) -> AnyPublisher<Bool, Never> {
        
        return Future<Bool, Never> { block in
            
            Task {
                
                let context = await self.container.mainContext
            
                var updatedCache = self.cache.value
                
                updatedCache.removeValue(forKey: data.id)
            
                self.cache.value = updatedCache
                
                context.delete(data)
            
                block(.success(true))
            }
            
            
        }.receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
        
    }
    
}

