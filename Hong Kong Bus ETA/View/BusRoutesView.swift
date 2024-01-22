//
//  BusRoutesView.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 21/1/2024.
//

import Foundation
import SwiftUI

struct BusRoutesView : View {
    
    @StateObject
    var viewModel : BusRoutesViewModel
    
    var body: some View {
        
        
        if let list = viewModel.displayedList {
            VStack {
                
                TextField("Search", text: $viewModel.filter)
                
                Spacer().frame(height: 20)
                
                List {
                    
                    ForEach(list, id: \.id) { route in
                        
                        Button(action: {
                            viewModel.onRouteSelected(route)
                        }, label: {
                            VStack (alignment: .leading){
                                
                                Text("\(route.company ?? "") \(route.route ?? "")").font(.headline)
                                Text("To: \(route.destination())")
                            }
                        }).buttonStyle(.plain)
                            .frame(height: 80)
                                    
                    }
                    
                }
            }
            
        } else {
            ProgressView()
        }
        
    }
}
