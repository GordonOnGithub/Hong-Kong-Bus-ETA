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
              .foregroundColor(.gray)
          }

          Spacer()
        }.frame(width: 20)

        Text(eta.getReadableHourAndMinute())
          .font(.title3)
          .foregroundStyle(.gray)
        Spacer()
        Text(eta.remainingTime.description)
          .font(.title3)
          .foregroundStyle(.gray)

      case .imminent:
        HStack(spacing: 0) {
          if isFetching {
            ProgressView().frame(height: 20)
          } else {
            Image(systemName: "clock.badge.exclamationmark")
              .symbolEffect(.bounce, options: .repeat(5), value: animateEffectToggle)
              .frame(height: 20)
              .foregroundColor(.primary)
          }
          Spacer()
        }.frame(width: 20)
        Text(eta.getReadableHourAndMinute())
          .font(.title3)
          .fontWeight(.semibold)
        Spacer()

        Text(eta.remainingTime.description)
          .font(.title3)
          .fontWeight(.semibold)

      case .minutes:
        HStack(spacing: 0) {
          if isFetching {
            ProgressView().frame(height: 20)
          } else {
            Image(systemName: "clock")
              .frame(height: 20)
              .foregroundColor(.primary)
          }
          Spacer()
        }.frame(width: 20)
        Text(eta.getReadableHourAndMinute())
          .font(.title3)
        Spacer()
        Text(eta.remainingTime.description)
          .font(.title3)
      }

    }.onAppear(perform: {
      animateEffectToggle += 1
    })

  }
}
