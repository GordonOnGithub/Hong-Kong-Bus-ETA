//
//  ETAStorage.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 24/1/2024.
//

import Foundation
import SwiftData
import Combine

protocol DataStorageType {
    
    associatedtype T : PersistentModel
    
    var cache : [T.ID: T] { get }
    
    func fetch() -> AnyPublisher<[T],Error>
    func insert(data: T) -> AnyPublisher<Bool, Never>
    func delete(data : T) -> AnyPublisher<Bool, Never>
}

class BusETAStorage {
    
    
    static var shared : DataStorage<BusStopETA> = DataStorage<BusStopETA>()
    
    private init(){
        
    }
}

class DataStorage<U: PersistentModel> : DataStorageType {
    
    typealias T = U
    
    private let container : ModelContainer

    var cache : [T.ID: T] = [:]
    
    init(){
        self.container = try! ModelContainer(for: T.self)
        
        Task {
            let container = await container.mainContext
            container.autosaveEnabled = true
        }
    }
    
    func fetch() -> AnyPublisher<[T],Error> {
        
        return Future { block in
            
            Task {
                let context = await self.container.mainContext
                
                do {
                    let result = try context.fetch(FetchDescriptor<T>())
                    
                    self.cache.removeAll()
                    
                    for data in result {
                        self.cache[data.id] = data
                    }
                                            
                    block(.success(result))
                } catch {
                    block(.failure(error))
                }
            }
            
        }.receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        
    }
    
    func insert(data: T) -> AnyPublisher<Bool, Never> {
        
        return Future<Bool, Never> { block in
            
            Task {
                let context = await self.container.mainContext
                
                context.insert(data)
                
                self.cache[data.id] = data
                
                block(.success(true))

            }
            
            
        }.receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    func delete(data : T) -> AnyPublisher<Bool, Never> {
        
        return Future<Bool, Never> { block in
            
            Task {
                
                let context = await self.container.mainContext
                
                context.delete(data)
                
                self.cache.removeValue(forKey: data.id)
            
                block(.success(true))
            }
            
            
        }.receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
        
    }
    
}

