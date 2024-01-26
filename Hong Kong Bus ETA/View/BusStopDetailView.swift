//
//  BusStopDetailView.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 22/1/2024.
//

import Foundation
import SwiftUI

struct BusStopDetailView : View {
    
    @Environment(\.dismiss) var dismiss
    
    @StateObject
    var viewModel: BusStopDetailViewModel<DataStorage<BusStopETA>>
    
    var body: some View {
        NavigationView {
            VStack (spacing: 20){
                
                if viewModel.busStopDetail != nil {
                    Text(viewModel.getBusStopName()).font(.headline)
                }
                
                Text("\(viewModel.busStopETA.company) \(viewModel.busStopETA.route)")
                // TODO: show destination

                if let busETAList = viewModel.busETAList {
                    
                    if busETAList.isEmpty {
                        Text("No information on estimated time of arrival.")
                    }
                    
                    List(busETAList) { eta in
                        
                        ETARowView(eta: eta)
                    }
                } else {
                    
                    ProgressView().frame(height: 200)
                }
                
                Spacer()
                
                if let lastUpdatedTimestamp = viewModel.lastUpdatedTimestamp {
                    
                    Text("Last update: \(lastUpdatedTimestamp.ISO8601Format())")
                }
            }.padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        dismiss()
                    }, label: {
                        Text("Dismiss")
                    })
                }
                
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        viewModel.onSaveButtonClicked()
                    }, label: {
                        
                        if viewModel.isSaved {
                            Text("Unbookmark")
                        } else {
                            Text("Bookmark")
                        }
                    })
                }
            }
        }
    }
}
