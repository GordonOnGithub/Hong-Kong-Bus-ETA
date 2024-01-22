//
//  BusStopRowViewModel.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 22/1/2024.
//

import Foundation
import Combine

protocol BusStopRowViewModelDelegate : AnyObject {
    
    func busStopRowViewModel(_ viewModel: BusStopRowViewModel, didRequestDisplayBusStop busStop: any BusStopModel ,withDetails details: any BusStopDetailModel )
}

class BusStopRowViewModel : ObservableObject {
    
    let busStop: any BusStopModel
    
    var apiManager : APIManagerType

    @Published
    var busStopDetail : (any BusStopDetailModel)?
    
    @Published
    var error : (any Error)?
    
    weak var delegate: BusStopRowViewModelDelegate?
    
    private var cancellable = Set<AnyCancellable>()
    
    init(busStop: any BusStopModel, apiManager: APIManagerType = APIManager.shared) {
        self.busStop = busStop
        self.apiManager = apiManager
        
        fetch()
    }
    
    func fetch(){
        
        error = nil
        
        if let ctbBusStop = busStop as? CTBBusStopModel {
            fetchCTBBusStopDetail(busStop: ctbBusStop)
            
        } else if let kmbBusStop = busStop as? KMBBusStopModel {
            fetchKMBBusStopDetail(busStop: kmbBusStop)
        }
                
    }
    
    private func fetchCTBBusStopDetail(busStop: CTBBusStopModel){
        
        guard let stopId = busStop.stopId else { return }
        
        apiManager.call(api: .CTBBusStopDetail(stopId: stopId)).sink { [weak self] completion in
            
            switch completion {
            case .failure(let error):
                self?.error = error
                break
            default:
                self?.error = nil
                break
            }
            
        } receiveValue: { [weak self] data in
            
            if let self, let data, let response = try? JSONDecoder().decode(APIResponseModel<CTBBusStopDetailModel>.self, from: data) {
                busStopDetail = response.data
            }
            
        }.store(in: &cancellable)

    }
    
    private func fetchKMBBusStopDetail(busStop: KMBBusStopModel){
        
        guard let stopId = busStop.stopId else { return }
        
        apiManager.call(api: .KMBBusStopDetail(stopId: stopId)).sink { [weak self] completion in
            
            switch completion {
            case .failure(let error):
                self?.error = error
                break
            default:
                self?.error = nil
                break
            }
            
        } receiveValue: {  [weak self] data in
            
            if let self, let data, let response = try? JSONDecoder().decode(APIResponseModel<KMBBusStopDetailModel>.self, from: data) {
                busStopDetail = response.data
            }
            
        }.store(in: &cancellable)

    }
    
    func onBusStopSelected(){
        guard let busStopDetail else { return }
        
        delegate?.busStopRowViewModel(self, didRequestDisplayBusStop: busStop, withDetails: busStopDetail)
        
    }
}
