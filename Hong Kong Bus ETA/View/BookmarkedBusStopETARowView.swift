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
            
            
            Text(viewModel.busStopETA.getFullRouteName()).font(.title)
            
            if viewModel.busRoute != nil {
                Text(viewModel.getDestinationDescription()).font(.headline)
            }
            
            if viewModel.busStopDetail != nil {
                Text(viewModel.getBusStopName())
            }
            
            if let busETAList = viewModel.busETAList {
                    
                if let latest = busETAList.first(where: { eta in
                    
                    switch eta.remainingTime {
                    case .expired:
                        return false
                    default:
                        return true
                    }
                    
                }) {
                    
                    ETARowView(eta: latest)
                    
                } else {
                    HStack{
                        Text("-- : --").foregroundStyle(.gray)
                        Spacer()
                        Text(" - ").foregroundStyle(.gray)
                    }
                }
                
                
            } else {
                ProgressView()
            }
            
        })
        .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.onRowClicked()
        }
    }
}
