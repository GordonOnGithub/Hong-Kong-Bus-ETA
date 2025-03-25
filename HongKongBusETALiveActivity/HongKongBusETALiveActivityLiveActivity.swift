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
          Text("\( context.attributes.code)").font(.title).fontWeight(.medium).lineLimit(
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

            Label("\(hourString):\(minuteString)", systemImage: "clock").font(.title2)

            Text(timerInterval: Date()...eta, showsHours: false).font(.headline).frame(maxWidth: 60)
          }.frame(maxWidth: 100)
        } else {
          Label("No info", systemImage: "clock.badge.questionmark").font(.headline)
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
            Image(systemName: "clock.badge.questionmark")
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
              Text(context.attributes.destination)
              Spacer()
              Label("\(hourString):\(minuteString)", systemImage: "clock")
            }

          } else {

            Label("No info", systemImage: "clock.badge.questionmark")
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
          Label("No info", systemImage: "clock.badge.questionmark")
        }
      } minimal: {
        Image(systemName: "bus.fill")
      }
      .keylineTint(Color.red)
    }
  }
}
