//
//  MapKit+Extension.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 10/2/2024.
//

import Foundation
import MapKit
import _MapKit_SwiftUI

extension MapCameraPosition {

  static var positionOfHongKong: MapCameraPosition {
    MapCameraPosition.region(
      MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 22.3222263, longitude: 114.1568812),
        span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
      )
    )
  }

}

extension MapCameraBounds {

  static var boundsOfHongKong: MapCameraBounds {
    MapCameraBounds.init(minimumDistance: 3000, maximumDistance: 200000)
  }

}
