//
//  InfoView.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 17/2/2024.
//

import Foundation
import SwiftUI

struct InfoView : View {
    
    @StateObject
    var viewModel : InfoViewModel
    
    var body: some View {
        
        VStack {
            Text(String(localized: "info_tab")).font(.headline)
        
            List {
                
                Section {
                    Button(action: {
                        viewModel.onCheckRepositoryButtonClicked()
                    }, label: {
                        Text(String(localized: "repository"))
                    })
                    
                    Button(action: {
                        viewModel.onRateThisAppClicked()
                    }, label: {
                        Text(String(localized: "rate_this_app"))
                    })
                    
                } header: {
                    Text(viewModel.headerString)
                } footer: {
                    Text(viewModel.versionString)
                    
                }
                
                
                
            }
        }
    }
}

