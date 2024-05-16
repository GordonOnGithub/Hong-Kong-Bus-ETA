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

  @State
  private var animateEffectToggle = 0

  var body: some View {

    HStack {

      switch eta.remainingTime {
      case .expired:
        Image(systemName: "clock")
          .frame(height: 20)
          .foregroundColor(.gray)
        Text(eta.getReadableHourAndMinute())
          .font(.system(size: 18))
          .foregroundStyle(.gray)
        Spacer()
        Text(eta.remainingTime.description)
          .font(.system(size: 18))
          .foregroundStyle(.gray)

      case .imminent:
        Image(systemName: "clock")
          .symbolEffect(.bounce, options: .repeat(5), value: animateEffectToggle)
          .frame(height: 20)
          .foregroundColor(.primary)
        Text(eta.getReadableHourAndMinute())
          .font(.system(size: 18))
          .bold()
        Spacer()

        Text(eta.remainingTime.description)
          .font(.system(size: 18))
          .bold()

      case .minutes:
        Image(systemName: "clock")
          .frame(height: 20)
          .foregroundColor(.primary)
        Text(eta.getReadableHourAndMinute())
          .font(.system(size: 18))
        Spacer()
        Text(eta.remainingTime.description)
          .font(.system(size: 18))
      }

    }.onAppear(perform: {
      animateEffectToggle += 1
    })

  }
}
