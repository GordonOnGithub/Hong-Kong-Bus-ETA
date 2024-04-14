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
    .camera(
      .init(
        centerCoordinate: CLLocationCoordinate2D(latitude: 22.345, longitude: 114.12),
        distance: 150000))
  }

}

extension MapCameraBounds {

  static var boundsOfHongKong: MapCameraBounds {
    .init(
      centerCoordinateBounds: .init(
        MKMapRect(
          origin: .init(
            CLLocationCoordinate2D(
              latitude: 22.58,
              longitude: 113.8)),
          size: .init(width: 360000, height: 360000))), minimumDistance: 500,
      maximumDistance: 150000)
  }

}
