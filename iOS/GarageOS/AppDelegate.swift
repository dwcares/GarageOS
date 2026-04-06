//
//  AppDelegate.swift
//  GarageOS
//
//  Created by David Washington on 12/22/15.
//  Copyright © 2015 David Washington. All rights reserved.
//

import UIKit
import UserNotifications
import WatchConnectivity


@main
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate {

    var window: UIWindow?

    var launchedShortcutItem: UIApplicationShortcutItem?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if let shortcutItem = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            launchedShortcutItem = shortcutItem
        }

        registerSettingsBundle()

        // Set up WatchConnectivity
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }

        // Send door status to watch whenever it changes
        GarageClient.sharedInstance.onDoorStatusChanged = { [weak self] in
            self?.sendDoorStatusToWatch()
        }

        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { (granted, error) in
            if (granted) {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            } else if let error = error {
                print("Register for notifications error: \(error)")
            }
        }

        return true

    }



    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register with error: \(error)")
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Device Token: \(deviceToken)")
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        let handledShortCutItem = handleShortCutItem(shortcutItem)

        completionHandler(handledShortCutItem)
    }


    func registerSettingsBundle() {
        let appDefaults = [String: AnyObject]()
        UserDefaults.standard.register(defaults: appDefaults)

    }

    func handleShortCutItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        var handled = false

        let shortCutType = shortcutItem.type

        switch (shortCutType) {
        case "com.TheRobot.GarageOS.Door1":
            GarageClient.sharedInstance.doToggleDoor(true)
            handled = true
        case "com.TheRobot.GarageOS.Door2":
            GarageClient.sharedInstance.doToggleDoor(false)
            handled = true
        default:
            break
        }

        return handled
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("WCSession activation: \(activationState.rawValue)")
        // Push current status to watch on activation
        if activationState == .activated {
            sendDoorStatusToWatch()
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
    }

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        guard let action = message["action"] as? String else { return }
        print("WC received message: \(message)")

        switch action {
        case "toggleDoor":
            guard let door = message["door"] as? String else { return }
            let isDoor1 = (door == "big")
            print("Watch requested toggle: \(door) door")
            GarageClient.sharedInstance.doToggleDoor(isDoor1)

        case "requestStatus":
            sendDoorStatusToWatch()

        default:
            break
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        guard let action = message["action"] as? String else {
            replyHandler(["error": "no action"])
            return
        }
        print("WC received message with reply: \(message)")

        switch action {
        case "toggleDoor":
            guard let door = message["door"] as? String else {
                replyHandler(["error": "no door"])
                return
            }
            let isDoor1 = (door == "big")
            print("Watch requested toggle: \(door) door")
            GarageClient.sharedInstance.doToggleDoor(isDoor1)
            replyHandler(["toggled": door])

        case "requestStatus":
            let status: [String: Any] = [
                "action": "doorStatus",
                "smallDoorOpen": GarageClient.sharedInstance.smallDoorOpen,
                "bigDoorOpen": GarageClient.sharedInstance.bigDoorOpen
            ]
            replyHandler(status)

        default:
            replyHandler(["error": "unknown action"])
        }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        guard userInfo["action"] as? String == "toggleDoor",
              let door = userInfo["door"] as? String else { return }

        let isDoor1 = (door == "big")
        print("Watch requested toggle (via userInfo): \(door) door")
        GarageClient.sharedInstance.doToggleDoor(isDoor1)
    }

    // MARK: - Watch Status Updates

    func sendDoorStatusToWatch() {
        guard WCSession.default.activationState == .activated else { return }

        let status: [String: Any] = [
            "action": "doorStatus",
            "smallDoorOpen": GarageClient.sharedInstance.smallDoorOpen,
            "bigDoorOpen": GarageClient.sharedInstance.bigDoorOpen
        ]

        print("Sending door status to watch: \(status)")

        // Always update application context (persists, available on watch launch)
        try? WCSession.default.updateApplicationContext(status)

        // Also send live message if watch is reachable
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(status, replyHandler: nil) { error in
                print("Failed sending status to watch: \(error.localizedDescription)")
            }
        }
    }


}

