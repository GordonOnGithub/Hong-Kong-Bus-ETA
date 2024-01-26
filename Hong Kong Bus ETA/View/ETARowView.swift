//
//  ETARowView.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 26/1/2024.
//

import Foundation
import SwiftUI

struct ETARowView : View {
    
    let eta : BusETAModel
    
    var body: some View {
        
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
}
