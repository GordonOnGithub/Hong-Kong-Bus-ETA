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
    var viewModel : BusStopETAListViewModel
    
    var body: some View {
        
        VStack {
            if !viewModel.busStopETAList.isEmpty {
                Text("Estimated Time of Arrival (ETA)").font(.headline)

                List(viewModel.busStopETAList) { eta in
                    
                    BookmarkedBusStopETARowView(viewModel: viewModel.buildBookmarkedBusStopETARowViewModel(busStopETA: eta))
                        .frame(height: 200)
                    
                }
            } else {
                VStack(spacing: 20)  {
                    Text("No bus stop is bookmarked.").font(.headline)
                    Text("Bookmark bus stops to see their estimated time of arrival").font(.subheadline)
                    
                    Button(action: {
                        viewModel.onSearchCTBRoutesButtonClicked()
                    }, label: {
                        Text("Search for CTB routes")
                    }).buttonStyle(.bordered).tint(.blue)
                    
                    Button(action: {
                        viewModel.onSearchKMBRoutesButtonClicked()
                    }, label: {
                        Text("Search for KMB routes")
                    }).buttonStyle(.bordered).tint(.red)
                }.padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                
                
            }
        }
    }
}
