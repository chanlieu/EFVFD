//
//  FireLogWidgetBundle.swift
//  FireLogWidget
//
//  Created by Chan Lieu on 3/28/26.
//

import WidgetKit
import SwiftUI

@main
struct FireLogWidgetBundle: WidgetBundle {
    var body: some Widget {
        FireLogWidget()
        FireLogWidgetControl()
        FireLogWidgetLiveActivity()
    }
}
