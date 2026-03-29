//
//  FireLogWidgetLiveActivity.swift
//  FireLogWidget
//
//  Created by Chan Lieu on 3/28/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct FireLogWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct FireLogWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FireLogWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension FireLogWidgetAttributes {
    fileprivate static var preview: FireLogWidgetAttributes {
        FireLogWidgetAttributes(name: "World")
    }
}

extension FireLogWidgetAttributes.ContentState {
    fileprivate static var smiley: FireLogWidgetAttributes.ContentState {
        FireLogWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: FireLogWidgetAttributes.ContentState {
         FireLogWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: FireLogWidgetAttributes.preview) {
   FireLogWidgetLiveActivity()
} contentStates: {
    FireLogWidgetAttributes.ContentState.smiley
    FireLogWidgetAttributes.ContentState.starEyes
}
