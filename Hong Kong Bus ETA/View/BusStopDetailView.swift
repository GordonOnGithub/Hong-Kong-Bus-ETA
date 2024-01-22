//
//  BusStopDetailView.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 22/1/2024.
//

import Foundation
import SwiftUI

struct BusStopDetailView : View {
    
    @StateObject
    var viewModel: BusStopDetailViewModel
    
    var body: some View {

        Text(viewModel.busStopDetail.nameEn ?? "")
        
        if let busETAList = viewModel.busETAList {
            List(busETAList) { eta in
                
                Text(eta.etaTimestamp?.ISO8601Format() ?? "")
            }
            
        }
    }
}
