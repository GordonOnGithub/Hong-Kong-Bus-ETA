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
            VStack(spacing: 20) {
                
                Text(viewModel.busRoutesListSource.title).font(.headline).padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                
                TextField("Search", text: $viewModel.filter)
                    .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                    
                List {
                    
                    ForEach(list, id: \.id) { route in
                        
                        Button(action: {
                            viewModel.onRouteSelected(route)
                        }, label: {
                            HStack {
                                VStack (alignment: .leading){
                                    
                                    Text("\(route.company?.rawValue ?? "") \(route.route ?? "")").font(.headline)
                                    Text("To: \(route.destination())")
                                }
                                    Spacer()
                            }.frame(height: 80)
                            .contentShape(Rectangle())
                        }).buttonStyle(.plain)
                                    
                    }
                    
                }
            }
            
        } else {
            ProgressView()
        }
        
    }
}
