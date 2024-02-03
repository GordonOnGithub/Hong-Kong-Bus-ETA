//
//  BusRouteDetailView.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 22/1/2024.
//

import Foundation
import SwiftUI

struct BusRouteDetailView : View {
    
    @StateObject
    var viewModel : BusRouteDetailViewModel
    
    var body: some View {
        Group {
            
            VStack() {
            
                Text(viewModel.getDestinationDescription()).padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                
                if let list = viewModel.stopList {
                    List {
                        
                        ForEach(list, id: \.id) { stop in
                            
                            VStack(alignment: .leading, content: {
                                
                                BusStopRowView(viewModel: viewModel.makeBusStopRowViewModel(busStop: stop))
                                
                            })
                        }
                        
                    }
                } else {
                    ProgressView().frame(height: 80)
                }
                
                Spacer()
            }
        }.navigationTitle("\(viewModel.route.getFullRouteName())")
    }
}
