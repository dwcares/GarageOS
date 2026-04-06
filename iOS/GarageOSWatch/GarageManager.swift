//
//  GarageManager.swift
//  GarageOSWatch
//
//  Created by David Washington.
//  Copyright © 2025 David Washington. All rights reserved.
//

import Foundation

@MainActor
class GarageManager: ObservableObject {
    static let shared = GarageManager()

    @Published var smallDoorOpen: Bool = false
    @Published var bigDoorOpen: Bool = false
    @Published var isLoading: Bool = true

    private var pollTask: Task<Void, Never>?

    init() {
        pollTask = Task {
            await refreshStatus()
            await pollLoop()
        }
    }

    func refreshStatus() async {
        let status = await ParticleAPI.shared.getDoorStatus()
        smallDoorOpen = status.smallOpen
        bigDoorOpen = status.bigOpen
        isLoading = false
        print("Status: small=\(status.smallOpen ? "OPEN" : "closed") big=\(status.bigOpen ? "OPEN" : "closed")")
    }

    func toggleDoor(_ doorKey: String) {
        let isDoor1 = (doorKey == "big")
        Task {
            do {
                try await ParticleAPI.shared.toggleDoor(isDoor1: isDoor1)
                print("Door toggled: \(doorKey)")
                // Refresh after door has time to actuate
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                await refreshStatus()
            } catch {
                print("Failed to toggle door: \(error)")
            }
        }
    }

    private func pollLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 10_000_000_000)  // 10 seconds
            guard !Task.isCancelled else { break }
            await refreshStatus()
        }
    }

    deinit {
        pollTask?.cancel()
    }
}
