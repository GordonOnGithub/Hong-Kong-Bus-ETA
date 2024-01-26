//
//  BusStopETAListView.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 26/1/2024.
//

import Foundation
import SwiftUI


struct BusStopETAListView: View {
    
    @StateObject
    var viewModel : BusStopETAListViewModel<DataStorage<BusStopETA>>
    
    var body: some View {
        
        if !viewModel.busStopETAList.isEmpty {
            List(viewModel.busStopETAList) { eta in
                
                BookmarkedBusStopETARowView(viewModel: viewModel.buildBookmarkedBusStopETARowViewModel(busStopETA: eta))
                    .frame(height: 150)
                
            }
        } else {
            Text("No bus stop is bookmarked")
            
        }
    }
}
