//
//  BusStopETAListViewModel.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 26/1/2024.
//

import Foundation
import Combine

protocol BusStopETAListViewModelDelegate : AnyObject {
    
    func busStopETAListViewModelModel(_ viewModel: BusStopETAListViewModel<some DataStorageType>, didRequestDisplayBusStopDetailForRoute route: String, company: BusCompany, stopId: String, serviceType: String?, isInbound: Bool, detail: (any BusStopDetailModel)?)
}

class BusStopETAListViewModel<T>: ObservableObject where T : DataStorageType, T.PersistentModelType : BusStopETA {
    
    @Published
    var busStopETAList: [T.PersistentModelType] = []
    
    let busETAStorage : T
    
    weak var delegate: BusStopETAListViewModelDelegate?

    private var cancellable = Set<AnyCancellable>()

    init( busETAStorage: T = BusETAStorage.shared) {
        self.busETAStorage = busETAStorage
                
        busETAStorage.fetch()
        
        setupPublisher()
    }
    
    private func setupPublisher(){
        
        busETAStorage.cache.map { cache in
            
            cache.values.sorted { a, b in
                a.route > b.route
            }
            
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$busStopETAList)
        
    }
    
    func buildBookmarkedBusStopETARowViewModel(busStopETA: BusStopETA) -> BookmarkedBusStopETARowViewModel {
        
        let vm =  BookmarkedBusStopETARowViewModel(busStopETA: busStopETA)
        
        vm.delegate = self
        
        return vm
        
    }
}

extension BusStopETAListViewModel : BookmarkedBusStopETARowViewModelDelegate {
    func bookmarkedBusStopETARowViewModel(_ viewModel: BookmarkedBusStopETARowViewModel, didRequestDisplayBusStopDetailForRoute route: String, company: BusCompany, stopId: String , serviceType: String?, isInbound: Bool, detail: (any BusStopDetailModel)?) {
        
        delegate?.busStopETAListViewModelModel(self, didRequestDisplayBusStopDetailForRoute: route, company: company,stopId: stopId, serviceType: serviceType, isInbound: isInbound, detail: detail)
        
    }
    

    
    
    
}
