//
//  BookmarkedBusStopETARowView.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 26/1/2024.
//

import Foundation
import SwiftUI

struct BookmarkedBusStopETARowView : View {
    
    @ObservedObject
    var viewModel: BookmarkedBusStopETARowViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10, content: {
            
            if viewModel.busStopDetail != nil {
                Text(viewModel.getBusStopName()).font(.headline)
            }
            
            Text("\(viewModel.busStopETA.company) \(viewModel.busStopETA.route)")
            
            if viewModel.busRoute != nil {
                Text(viewModel.getDestinationDescription())
            }
            
            if let busETAList = viewModel.busETAList {
                    
                if let latest = busETAList.first {
                    
                    ETARowView(eta: latest)
                    
                } else {
                    
                    Text("-- : --").foregroundStyle(.gray)
                }
                
                
            } else {
                ProgressView()
            }
            
        })
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.onRowClicked()
        }
    }
}
