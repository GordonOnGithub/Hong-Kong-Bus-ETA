//
//  BusRouteDetailViewModel.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 22/1/2024.
//

import Foundation
import Combine

protocol BusRouteDetailViewModelDelegate : AnyObject {
    func busRouteDetailViewModel(_ viewModel: BusRouteDetailViewModel, didRequestDisplayBusStop busStop: any BusStopModel ,withDetails details: any BusStopDetailModel )
    
}

class BusRouteDetailViewModel: ObservableObject {
 
    let route: any BusRouteModel
        
    var apiManager : APIManagerType
    
    @Published
    var stopList : [any BusStopModel]? = nil
    
    weak var delegate: BusRouteDetailViewModelDelegate?
    
    private var cancellable = Set<AnyCancellable>()

    init(route: any BusRouteModel, apiManager: APIManagerType = APIManager.shared) {
        self.route = route
        self.apiManager = apiManager
        
        fetch()
    }
    
    
    func fetch(){
        if let ctbRoute = route as? CTBBusRouteModel {
            
            fetchCTBRouteData(route: ctbRoute)
            
        } else if let kmbRoute = route as? KMBBusRouteModel {
            fetchKMBRouteData(route: kmbRoute)
        }
        
    }
    
    private func fetchKMBRouteData(route: KMBBusRouteModel){
        apiManager.call(api: .KMBRouteData(route: route.route ?? "", isInbound: route.isInbound, serviceType: route.serviceType ?? "")).sink {  [weak self] completion in
            
            switch completion {
            case .failure(let error):
                self?.stopList = []
                break
            default:
                break
                
            }
            
        } receiveValue: { [weak self] data in
            
            if let self, let data, let response = try? JSONDecoder().decode(APIResponseModel<[KMBBusStopModel]>.self, from: data) {
                                
                self.stopList = response.data
            }
            
        }.store(in: &cancellable)

    }
    
    private func fetchCTBRouteData(route: CTBBusRouteModel){
        apiManager.call(api: .CTBRouteData(route: route.route ?? "", isInbound: route.isInbound)).sink { [weak self] completion in
            
            switch completion {
            case .failure(let error):
                self?.stopList = []
                break
            default:
                break
                
            }
            
        } receiveValue: {  [weak self]  data in
            
            if let self, let data, let response = try? JSONDecoder().decode(APIResponseModel<[CTBBusStopModel]>.self, from: data) {
                
                self.stopList = response.data
            }
            
        }.store(in: &cancellable)

    }
    
    func makeBusStopRowViewModel(busStop : any BusStopModel) -> BusStopRowViewModel {
        
        let vm = BusStopRowViewModel(busStop: busStop)
        
        vm.delegate = self
        
        return vm
        
    }
    
    func getDestinationDescription() -> String {
                
        let destination = self.route.destination()
        
        return " To: " + destination
    }
}

extension BusRouteDetailViewModel : BusStopRowViewModelDelegate {
    func busStopRowViewModel(_ viewModel: BusStopRowViewModel, didRequestDisplayBusStop busStop: any BusStopModel, withDetails details: any BusStopDetailModel) {
        delegate?.busRouteDetailViewModel(self, didRequestDisplayBusStop: busStop, withDetails: details)
    }
    
    
}
