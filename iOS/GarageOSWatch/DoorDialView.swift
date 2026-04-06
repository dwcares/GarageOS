//
//  DoorDialView.swift
//  GarageOSWatch
//
//  Created by David Washington.
//  Copyright © 2025 David Washington. All rights reserved.
//

import SwiftUI
import WatchKit

struct DoorDialView: View {
    let doorName: String
    let doorKey: String

    @EnvironmentObject var garage: GarageManager

    @State private var crownValue: Double = 0.0
    @State private var ringLevel: Double = 0.0
    @State private var triggered: Bool = false
    @State private var resetting: Bool = false
    @State private var pendingState: Bool? = nil
    @State private var decayTimer: DispatchWorkItem? = nil
    @State private var decaying: Bool = false
    @State private var ringOpacity: Double = 1.0

    @State private var hitHalf: Bool = false
    @State private var hitThreeQuarter: Bool = false

    private let threshold: Double = 12.0
    private let maxValue: Double = 100.0
    private let decayDelay: Double = 1.0

    private let accentBlue = Color.blue

    private var isOpen: Bool {
        if let pending = pendingState { return pending }
        return doorKey == "small" ? garage.smallDoorOpen : garage.bigDoorOpen
    }

    private var realIsOpen: Bool {
        doorKey == "small" ? garage.smallDoorOpen : garage.bigDoorOpen
    }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)

                // Status ring (idle) — always present, opacity controlled
                Circle()
                    .trim(from: 0, to: isOpen ? 0.0 : 1.0)
                    .stroke(
                        accentBlue.opacity(0.3),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .opacity(ringLevel < 0.01 && !resetting && !decaying && !isOpen ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.6), value: ringLevel < 0.01 && !resetting && !decaying)
                    .animation(.easeInOut(duration: 0.8), value: isOpen)

                // Progress ring — always present, opacity controlled
                Circle()
                    .trim(from: 0, to: min(ringLevel, 1.0))
                    .stroke(
                        accentBlue,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .opacity(ringOpacity)

                // Glow near trigger
                if ringLevel > 0.75 && !triggered {
                    Circle()
                        .stroke(accentBlue.opacity(0.4), lineWidth: 20)
                        .scaleEffect(1.0 + (ringLevel - 0.75) * 0.5)
                        .blur(radius: 3)
                }

                VStack(spacing: 4) {
                    Image(systemName: isOpen ? "door.garage.open" : "door.garage.closed")
                        .font(.system(size: 30))
                        .foregroundColor(garage.isLoading ? .gray.opacity(0.4) : .white)
                        .scaleEffect(triggered ? 1.3 : 1.0)
                        .contentTransition(.symbolEffect(.replace))
                        .animation(.spring(response: 0.3, dampingFraction: 0.4), value: triggered)
                        .animation(.easeInOut(duration: 0.5), value: garage.isLoading)
                        .animation(.easeInOut(duration: 0.8), value: isOpen)

                    if triggered {
                        Text(isOpen ? "Opened" : "Closed")
                            .font(.caption2)
                            .foregroundColor(accentBlue)
                    } else if !garage.isLoading {
                        Text(isOpen ? "Open" : "Closed")
                            .font(.caption2)
                            .foregroundColor(isOpen ? accentBlue : .gray)
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.8), value: isOpen)
                            .animation(.easeInOut(duration: 0.5), value: garage.isLoading)
                    }
                }
            }
            .frame(width: 120, height: 120)

            Text(doorName)
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .focusable()
        .digitalCrownRotation(
            $crownValue,
            from: -maxValue,
            through: maxValue,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .scrollIndicators(.hidden)
        .onChange(of: crownValue) {
            guard !resetting else { return }

            if decaying {
                if crownValue != 0 {
                    decaying = false
                    ringOpacity = 1.0
                } else {
                    return
                }
            }

            // Cancel any pending decay
            decayTimer?.cancel()

            let newLevel = max(crownValue / threshold, 0.0)
            ringLevel = min(newLevel, 1.0)

            // Haptic feedback at milestones
            if ringLevel >= 0.5 && !hitHalf {
                hitHalf = true
                WKInterfaceDevice.current().play(.click)
            }
            if ringLevel >= 0.75 && !hitThreeQuarter {
                hitThreeQuarter = true
                WKInterfaceDevice.current().play(.click)
            }
            if ringLevel < 0.5 {
                hitHalf = false
                hitThreeQuarter = false
            } else if ringLevel < 0.75 {
                hitThreeQuarter = false
            }

            if ringLevel >= 1.0 && !triggered {
                triggered = true
                resetting = true
                WKInterfaceDevice.current().play(.success)
                pendingState = !isOpen
                garage.toggleDoor(doorKey)

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    crownValue = 0
                    ringLevel = 0
                    hitHalf = false
                    hitThreeQuarter = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        triggered = false
                        resetting = false
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
                    pendingState = nil
                }
            } else {
                // Schedule decay after idle
                let work = DispatchWorkItem {
                    decaying = true
                    crownValue = 0
                    // Delay so onChange settles first
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation(.easeOut(duration: 0.8)) {
                            ringLevel = 0
                            ringOpacity = 0
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                        decaying = false
                        ringOpacity = 1.0
                    }
                }
                decayTimer = work
                DispatchQueue.main.asyncAfter(deadline: .now() + decayDelay, execute: work)
            }
        }
        .onChange(of: realIsOpen) {
            pendingState = nil
        }
    }
}
