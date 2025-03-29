//
//  HongKongBusETALiveActivityLiveActivity.swift
//  HongKongBusETALiveActivity
//
//  Created by Ka Chun Wong on 24/3/2025.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct HongKongBusETALiveActivityAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    // Dynamic stateful properties about your activity go here!
    var eta: Date?
  }

  // Fixed non-changing properties about your activity go here!
  var code: String
  var destination: String
  var company: String
  var stop: String

}

struct HongKongBusETALiveActivityLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: HongKongBusETALiveActivityAttributes.self) { context in
      // Lock screen/banner UI goes here
      HStack {

        VStack(alignment: .leading) {
          Text("\(context.attributes.company.uppercased()) \(context.attributes.code)").font(.title)
            .lineLimit(
              1)
          HStack {
            Text(context.attributes.destination).font(.headline)
          }
        }
        Spacer()

        if let eta = context.state.eta {

          VStack(alignment: .trailing) {

            let hour = Calendar.current.component(.hour, from: eta)
            let minute = Calendar.current.component(.minute, from: eta)

            var hourString = hour >= 10 ? "\(hour)" : "0\(hour)"
            var minuteString = minute >= 10 ? "\(minute)" : "0\(minute)"

            Label("\(hourString):\(minuteString)", systemImage: "clock").font(.title)

            Text(timerInterval: Date()...eta, showsHours: false).font(.headline).frame(maxWidth: 80)
          }
        } else {
          Label(String(localized: "no_live_activity_data"), systemImage: "clock.badge.questionmark")
            .font(.headline)
        }

      }
      .padding(16)
      .foregroundStyle(context.attributes.company == "KMB" ? .white : .blue)
      .activityBackgroundTint(context.attributes.company == "KMB" ? .red : .yellow)
      .activitySystemActionForegroundColor(Color.black)

    } dynamicIsland: { context in
      DynamicIsland {
        // Expanded UI goes here.  Compose the expanded UI through
        // various regions, like leading/trailing/center/bottom
        DynamicIslandExpandedRegion(.leading) {
          Label("\(context.attributes.code)", systemImage: "bus.fill")
        }
        DynamicIslandExpandedRegion(.trailing) {
          if let eta = context.state.eta {
            HStack {
              Image(systemName: "timer")
              Text(timerInterval: Date()...eta, showsHours: false).font(.subheadline).frame(
                width: 50)
            }

          } else {
            Label(
              String(localized: "no_live_activity_data"), systemImage: "clock.badge.questionmark")
          }
        }
        DynamicIslandExpandedRegion(.bottom) {
          // more content
          if let eta = context.state.eta {

            let hour = Calendar.current.component(.hour, from: eta)
            let minute = Calendar.current.component(.minute, from: eta)

            var hourString = hour >= 10 ? "\(hour)" : "0\(hour)"
            var minuteString = minute >= 10 ? "\(minute)" : "0\(minute)"
            HStack {
              Label(context.attributes.destination, systemImage: "arrowshape.right")
              Spacer()
              Label("\(hourString):\(minuteString)", systemImage: "clock")
              Spacer().frame(width: 8)
            }.foregroundStyle(.secondary)
              .font(.caption)
              .padding(3)

          } else {
            Text(
              "Open the app to refresh data for \(context.attributes.company.uppercased()) \(context.attributes.code)"
            ).font(.caption).foregroundStyle(.secondary)
              .padding(3)

          }
        }
      } compactLeading: {
        Label("\( context.attributes.code)", systemImage: "bus.fill")
      } compactTrailing: {
        if let eta = context.state.eta {
          HStack {
            Image(systemName: "timer")
            Text(timerInterval: Date()...eta, showsHours: false).font(.subheadline).frame(width: 50)
          }

        } else {
          Label(String(localized: "no_live_activity_data"), systemImage: "clock.badge.questionmark")
        }
      } minimal: {
        Image(systemName: "bus.fill")
      }
      .keylineTint(Color.red)
    }
  }
}
