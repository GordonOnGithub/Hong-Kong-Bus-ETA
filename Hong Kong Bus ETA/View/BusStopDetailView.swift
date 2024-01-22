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
    var viewModel: BusStopDetailViewModel
    
    var body: some View {
        NavigationView {
            VStack (spacing: 20){
                
                Text(viewModel.getBusStopName()).font(.headline)
                
                Text(viewModel.busStop.getFullRouteName())
                // TODO: show destination

                if let busETAList = viewModel.busETAList {
                    
                    if busETAList.isEmpty {
                        Text("No information on estimated time of arrival.")
                    }
                    
                    List(busETAList) { eta in
                        
                        HStack {
                            
                            switch eta.remainingTime {
                            case .expired:
                                Text(eta.getReadableHourAndMinute()).foregroundStyle(.gray)
                                Spacer()
                                Text(eta.remainingTime.description).foregroundStyle(.gray)
                                
                            case .imminent:
                                Text(eta.getReadableHourAndMinute()).bold()
                                Spacer()
                                
                                Text(eta.remainingTime.description).bold()
                                
                            case .minutes:
                                Text(eta.getReadableHourAndMinute())
                                Spacer()
                                Text(eta.remainingTime.description)
                            }
                            
                        }
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
                        
                    }, label: {
                        Text("Save")
                    })
                }
            }
        }
    }
}
