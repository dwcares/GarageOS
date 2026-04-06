//
//  GarageOSWatchApp.swift
//  GarageOSWatch
//
//  Created by David Washington.
//  Copyright © 2025 David Washington. All rights reserved.
//

import SwiftUI

@main
struct GarageOSWatchApp: App {
    @StateObject private var garage = GarageManager.shared

    var body: some Scene {
        WindowGroup {
            TabView {
                DoorDialView(doorName: "Small Door", doorKey: "small")
                DoorDialView(doorName: "Big Door", doorKey: "big")
            }
            .tabViewStyle(.page)
            .environmentObject(garage)
        }
    }
}
