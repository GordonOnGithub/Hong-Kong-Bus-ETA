//
//  BusStopDetailViewModel.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 22/1/2024.
//

import Foundation
import Combine

class BusStopDetailViewModel : ObservableObject {
    
    let busStop: any BusStopModel
    
    let busStopDetail : any BusStopDetailModel
    
    let apiManager: APIManagerType
    
    @Published
    var busETAList : [BusETAModel]? = nil
    
    @Published
    var lastUpdatedTimestamp : Date?
    
    private var cancellable = Set<AnyCancellable>()

    init( busStop: any BusStopModel, busStopDetail: any BusStopDetailModel, apiManager: APIManagerType = APIManager.shared) {
        self.busStop = busStop
        self.busStopDetail = busStopDetail
        self.apiManager = apiManager
        
        setupPublisher()
        
        fetchETA()
    }
    
    private func setupPublisher(){
        Timer.publish(every: 30, on: .main, in: .default).autoconnect().sink { [weak self] _ in
            self?.fetchETA()
        }.store(in: &cancellable)

    }
    
    func fetchETA(){
        if let busStop = self.busStop as? CTBBusStopModel ,let busStopDetail = self.busStopDetail as? CTBBusStopDetailModel {
            
            fetchCTBETA(busStop: busStop, busStopDetail: busStopDetail)
            
        } else if let busStop = self.busStop as? KMBBusStopModel ,let busStopDetail = self.busStopDetail as? KMBBusStopDetailModel {
            fetchKMBETA(busStop: busStop, busStopDetail: busStopDetail)
        }
        
    }
    
    func fetchCTBETA(busStop: CTBBusStopModel ,busStopDetail : CTBBusStopDetailModel){
        
        guard let stopId = busStopDetail.stopId,
        let route = busStop.route else { return }
        
        apiManager.call(api: .CTBArrivalEstimation(stopId: stopId, route: route)).sink { [weak self] completion in
            
            switch completion {
            case .failure(let error):
                self?.busETAList = []
            default:
                break
            }
            self?.lastUpdatedTimestamp = Date()
            
        } receiveValue: { [weak self] data in
            
            if let self, let data,
               let response = try? JSONDecoder().decode(APIResponseModel<[BusETAModel]>.self, from: data){
                    
                self.busETAList = response.data.sorted(by: { a, b in
                    
                    (a.etaTimestamp?.timeIntervalSince1970 ?? 0) < (b.etaTimestamp?.timeIntervalSince1970 ?? 0)
                })
            }
            
        }.store(in: &cancellable)

    }
    
    func fetchKMBETA(busStop: KMBBusStopModel ,busStopDetail : KMBBusStopDetailModel){
        
        guard let stopId = busStopDetail.stopId,
        let route = busStop.route , let serviceType = busStop.serviceType else { return }
        
        apiManager.call(api: .KMBArrivalEstimation(stopId: stopId, route: route, serviceType: serviceType)).sink { [weak self] completion in
            
            switch completion {
            case .failure(let error):
                self?.busETAList = []
            default:
                break
            }
            self?.lastUpdatedTimestamp = Date()
            
        } receiveValue: { [weak self] data in
            
            if let self, let data,
               let response = try? JSONDecoder().decode(APIResponseModel<[BusETAModel]>.self, from: data){
                self.busETAList = response.data.sorted(by: { a, b in
                    
                    (a.etaTimestamp?.timeIntervalSince1970 ?? 0) < (b.etaTimestamp?.timeIntervalSince1970 ?? 0)
                })
            }
            
        }.store(in: &cancellable)

    }

    func getBusStopName() -> String {
        
        return busStopDetail.nameEn ?? ""
        
    }
    
    func getDestinationName() -> String {
        return ""
    }
    
}
