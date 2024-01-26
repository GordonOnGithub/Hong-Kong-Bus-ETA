//
//  BusRoutesDataProvider.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 22/1/2024.
//

import Foundation
import Combine

protocol BusRoutesDataProviderType {
    var ctbRouteDict : CurrentValueSubject<[String : CTBBusRouteModel]?, Never> { get }
    var kmbRouteDict : CurrentValueSubject<[String : KMBBusRouteModel]?, Never> { get }
    
    static var shared : BusRoutesDataProviderType { get }
    
    func fetchCTBRoutes()
    
    func fetchKMBRoutes()
    
    func getCacheKey(company: BusCompany, route: String, serviceType : String?) -> String
}

class BusRoutesDataProvider : BusRoutesDataProviderType {
    
    var apiManager : APIManagerType
    
    var ctbRouteDict : CurrentValueSubject<[String : CTBBusRouteModel]?, Never> = CurrentValueSubject(nil)
    
    var kmbRouteDict : CurrentValueSubject<[String : KMBBusRouteModel]?, Never> = CurrentValueSubject(nil)
    
    static var shared : BusRoutesDataProviderType = BusRoutesDataProvider()
    
    private var cancellable = Set<AnyCancellable>()
    
    private init(apiManager: APIManagerType = APIManager.shared) {
        self.apiManager = apiManager
        
    }
    
    func fetchCTBRoutes(){
        
        apiManager.call(api: .CTBRoutes).map { data -> [CTBBusRouteModel] in
            
            var list : [CTBBusRouteModel] = []
            
            guard let data else { return list }
            
            let decoder = JSONDecoder()

            if let response = try? decoder.decode(APIResponseModel<[CTBBusRouteModel]>.self, from: data) {
                
                list = response.data
                
                list.append(contentsOf: response.data.map({ route in
                    
                    CTBBusRouteModel(originTC: route.originTC, originSC: route.originSC, originEn: route.originEn, destinationTC: route.destinationTC, destinationSC: route.destinationSC, destinationEn: route.destinationEn, route: route.route,
                        timestamp: route.timestamp,
                                     isInbound: !route.isInbound)
                    
                }))
                
            
        }
        
            return list
        
        }.replaceError(with: [])
            .sink { list in
                
                var cache : [String : CTBBusRouteModel] = [:]
                for route in list {
                    
                    guard let company = route.company, let routeCode = route.route else { continue }
                    
                    cache[self.getCacheKey(company: company, route: routeCode, serviceType: nil)] = route
                }
                
                self.ctbRouteDict.value = cache
                
            }.store(in: &cancellable)
    
    }
    
    func fetchKMBRoutes(){
        
        apiManager.call(api: .KMBRoutes).map({ data -> [KMBBusRouteModel] in
            
            guard let data else { return [] }
            
            let decoder = JSONDecoder()
            
            if let response = try? decoder.decode(APIResponseModel<[KMBBusRouteModel]>.self, from: data) {
                
                return response.data
                
            }
            
            return []
            
        }).replaceError(with: [])
            .sink(receiveValue: { list in
                
                var cache : [String : KMBBusRouteModel] = [:]
                for route in list {
                    
                    guard let company = route.company, let routeCode = route.route else { continue }
                    
                    cache[self.getCacheKey(company: company, route: routeCode, serviceType: route.serviceType)] = route
                }
                
                self.kmbRouteDict.value = cache
                
            }).store(in: &cancellable)
    }
    
    func getCacheKey(company: BusCompany, route: String, serviceType : String?) -> String {
        
        return company.rawValue + "_" + route + "_" + (serviceType ?? "")
        
    }
}
