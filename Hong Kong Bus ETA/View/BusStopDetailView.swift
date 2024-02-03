//
//  BusStopDetailView.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 22/1/2024.
//

import Foundation
import SwiftUI
import MapKit


struct BusStopDetailView : View {
    
    @Environment(\.dismiss) var dismiss
    
    @StateObject
    var viewModel: BusStopDetailViewModel<DataStorage<BusStopETA>>
    
    var body: some View {
        NavigationView {
            VStack (alignment: .leading, spacing: 10){
                
                if viewModel.busStopDetail != nil {
                    Text(viewModel.getBusStopName()).font(.title)
                }
                
                Text("\(viewModel.busStopETA.company) \(viewModel.busStopETA.route)").font(.headline)
                
                if viewModel.busRoute != nil {
                    Text(viewModel.getDestinationDescription()).font(.subheadline)
                }
                if let busETAList = viewModel.busETAList {
                    
                    List {
                        
                        Section {
                            ForEach(busETAList) { eta in
                                ETARowView(eta: eta)
                            }
                            
                        } header: {
                            if busETAList.isEmpty {
                                Text("No information on estimated time of arrival.").listRowInsets(EdgeInsets())
                            } else {
                                Text("Estimated Time of Arrival: ").listRowInsets(EdgeInsets())
                            }
                        } footer: {
                            if let lastUpdatedTimestamp = viewModel.lastUpdatedTimestamp {
                                Section {
                                    Text("Last update: \(lastUpdatedTimestamp.ISO8601Format())").listRowInsets(EdgeInsets())
                                }
                            }
                        }
   
                    }
                    
                } else {
                    
                    ProgressView().frame(height: 300)
                }
                
                if let busStopDetail = viewModel.busStopDetail,
                   let latitude = Double(busStopDetail.position?.0 ?? ""),
                   let longitude = Double(busStopDetail.position?.1 ?? ""){
                    
                    let position = MapCameraPosition.region(
                        MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                        )
                    )
                    
                    Map(initialPosition: position) {
                        Marker(viewModel.getBusStopName(), coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                    }
                        .frame(height: 200)
                    
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
                    Button( action: {
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
