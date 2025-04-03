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

  @Binding
  var isFetching: Bool

  @State
  private var animateEffectToggle = 0

  var body: some View {

    HStack(spacing: 0) {

      switch eta.remainingTime {
      case .expired:
        HStack(spacing: 0) {
          if isFetching {
            ProgressView().frame(height: 20)
          } else {
            Image(systemName: "clock.badge.xmark")
              .frame(height: 20)
              .foregroundColor(.secondary)
          }

          Spacer()
        }.frame(width: 20)

        Text(eta.getReadableHourAndMinute())
          .foregroundStyle(.secondary)
        Spacer()
        Text(eta.remainingTime.description)
          .foregroundStyle(.secondary)

      case .imminent:
        HStack(spacing: 0) {
          if isFetching {
            ProgressView().frame(height: 20)
          } else {
            Image(systemName: "clock.badge.exclamationmark")
              .symbolEffect(.bounce, options: .repeat(5), value: animateEffectToggle)
              .frame(height: 20)
          }
          Spacer()
        }.frame(width: 20)
        Text(eta.getReadableHourAndMinute())
          .fontWeight(.semibold)
        Spacer()

        Text(eta.remainingTime.description)
          .fontWeight(.semibold)

      case .minutes:
        HStack(spacing: 0) {
          if isFetching {
            ProgressView().frame(height: 20)
          } else {
            Image(systemName: "clock")
              .frame(height: 20)
          }
          Spacer()
        }.frame(width: 20)
        Text(eta.getReadableHourAndMinute())
        Spacer()
        Text(eta.remainingTime.description)
      }

    }.onAppear(perform: {
      animateEffectToggle += 1
    })

  }
}
