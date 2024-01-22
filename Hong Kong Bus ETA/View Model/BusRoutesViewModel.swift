//
//  BusRoutesViewModel.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 21/1/2024.
//

import Foundation
import Combine

protocol BusRoutesViewModelDelegate : AnyObject {
    
    func busRoutesViewModel(_ viewModel:  BusRoutesViewModel, didSelectRoute route: any BusRouteModel)
    
}

class BusRoutesViewModel : ObservableObject {
    
    var apiManager : APIManagerType
    
    @Published
    var filter : String = ""
    
    @Published
    var ctbRouteList : [any BusRouteModel]?
    
    @Published
    var kmbRouteList : [any BusRouteModel]?
    
    @Published
    var displayedList : [any BusRouteModel]? = nil
    
    weak var delegate: BusRoutesViewModelDelegate?
    
    private var cancellable = Set<AnyCancellable>()
    
    init(apiManager: APIManagerType = APIManager.shared) {
        self.apiManager = apiManager
        
        setupPublisher()
        
        fetchCTBRoutes()
        
        fetchKMBRoutes()
        
    }
    
    func setupPublisher(){
        
        $filter.debounce(for: 0.3, scheduler: DispatchQueue.main)
            .combineLatest($kmbRouteList, $ctbRouteList).sink { [weak self] filter, kmb, ctb in
            
            guard let self else { return }
            
            var list :[any BusRouteModel]? = nil
            
            if let kmb {
                if list == nil { list = [] }
                list?.append(contentsOf: kmb)
                
            }
            
            if let ctb {
                if list == nil { list = [] }
                list?.append(contentsOf: ctb)
            }
            
                let filterList = filter.lowercased().split(separator: " ")
            
            if  filterList.count > 0 {
                
                list = list?.filter({ busRoute in
                    
                    guard
                          let route = busRoute.route?.lowercased(),
                          let originTC = busRoute.originTC,
                          let originSC = busRoute.originSC,
                          let originEn = busRoute.originEn?.lowercased(),
                          let destinationTC = busRoute.destinationTC,
                          let destinationSC = busRoute.destinationSC,
                          let destinationEn = busRoute.destinationEn?.lowercased() else {
                              
                              return false
                          }
                    
                    for filter in filterList {
                        
                        if route.contains(filter) ||
                            originEn.contains(filter) ||
                            originSC.contains(filter) ||
                            originTC.contains(filter) ||
                            destinationEn.contains(filter) ||
                            destinationSC.contains(filter) ||
                            destinationTC.contains(filter) {
                            return true
                        }
                        
                    }
                    
                    return false
                })
                
            }
            
            self.displayedList = list?.sorted(by: { a, b in
                (a.route ?? "" ) > (b.route ?? "")
            })
            
        }.store(in: &cancellable)
    }
    
    func fetchCTBRoutes(){
        
        apiManager.call(api: .CTBRoutes).sink { [weak self] completion in
            
            switch completion {
                case .failure(let error):
                    print(error)
                self?.ctbRouteList = []
                default:
                    break
                
            }
            
        } receiveValue: { [weak self] data in
            
            guard let self, let data else { return }
            
            let decoder = JSONDecoder()

            
            if let response = try? decoder.decode(APIResponseModel<[CTBBusRouteModel]>.self, from: data) {
                
                self.ctbRouteList = response.data
                
                self.ctbRouteList?.append(contentsOf: response.data.map({ route in
                    
                    CTBBusRouteModel(originTC: route.originTC, originSC: route.originSC, originEn: route.originEn, destinationTC: route.destinationTC, destinationSC: route.destinationSC, destinationEn: route.destinationEn, route: route.route, company: route.company, timestamp: route.timestamp,
                                     isInbound: !route.isInbound)
                    
                }))
                
            }
            
            
        }.store(in: &cancellable)

        
    }
    
    func fetchKMBRoutes(){
        
        apiManager.call(api: .KMBRoutes).sink { completion in
            
            switch completion {
                case .failure(let error):
                print(error)
                    break
                
            default:
                break
            }
            
        } receiveValue: { [weak self] data in
            
            guard let self, let data else { return }
            
            let decoder = JSONDecoder()

            
            if let response = try? decoder.decode(APIResponseModel<[KMBBusRouteModel]>.self, from: data) {
                
                self.kmbRouteList = response.data
                
            }
            
        }.store(in: &cancellable)

    }
    
    
    func onRouteSelected(_ route: any BusRouteModel){
        
        delegate?.busRoutesViewModel(self, didSelectRoute: route)
    }
    
    
}
