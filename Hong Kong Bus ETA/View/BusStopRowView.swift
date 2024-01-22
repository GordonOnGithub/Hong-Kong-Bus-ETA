//
//  BusStopRowView.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 22/1/2024.
//

import Foundation
import SwiftUI

struct BusStopRowView: View {
    
    @StateObject
    var viewModel : BusStopRowViewModel
    
    var body: some View {

        if let detail = viewModel.busStopDetail {
            
                Button(action: {
                    viewModel.onBusStopSelected()
                }, label: {
                    HStack(alignment: .center) {
                        
                        Text(detail.nameEn ?? "")
                        Spacer()
                         
                    }.frame(height: 80)
                }).buttonStyle(.plain)
            
        } else if let error = viewModel.error {
            
            Button(action: {
                viewModel.fetch()
            }, label: {
                Text("Reload")
            })
            
        } else {
            ProgressView().frame(height: 80)
        }
        
    }
}
