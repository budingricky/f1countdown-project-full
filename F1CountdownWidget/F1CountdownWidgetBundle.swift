//
//  F1CountdownWidgetBundle.swift
//  F1CountdownWidget
//
//  Widget bundle containing all F1 countdown widgets
//

import WidgetKit
import SwiftUI

@main
struct F1CountdownWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Home screen widgets
        F1CountdownWidget()
        
        // Lock screen widgets
        LockScreenWidget()
        
        // Live Activity (Dynamic Island)
        F1CountdownWidgetLiveActivity()
    }
}
