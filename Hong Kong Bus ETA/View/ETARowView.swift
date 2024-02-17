//
//  ETARowView.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 26/1/2024.
//

import Foundation
import SwiftUI

struct ETARowView: View {

  let eta: BusETAModel

  var body: some View {

    HStack {

      Image("clock", bundle: .main)
        .renderingMode(.template).resizable().scaledToFit().frame(height: 20)
        .foregroundColor(.primary)

      switch eta.remainingTime {
      case .expired:
        Text(eta.getReadableHourAndMinute())
          .font(.system(size: 18))
          .foregroundStyle(.gray)
        Spacer()
        Text(eta.remainingTime.description)
          .font(.system(size: 18))
          .foregroundStyle(.gray)

      case .imminent:
        Text(eta.getReadableHourAndMinute())
          .font(.system(size: 18))
          .bold()
        Spacer()

        Text(eta.remainingTime.description)
          .font(.system(size: 18))
          .bold()

      case .minutes:
        Text(eta.getReadableHourAndMinute())
          .font(.system(size: 18))
        Spacer()
        Text(eta.remainingTime.description)
          .font(.system(size: 18))
      }

    }

  }
}
