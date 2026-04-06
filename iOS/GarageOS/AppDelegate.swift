//
//  AppDelegate.swift
//  GarageOS
//
//  Created by David Washington on 12/22/15.
//  Copyright © 2015 David Washington. All rights reserved.
//

import UIKit
import UserNotifications


@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var launchedShortcutItem: UIApplicationShortcutItem?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if let shortcutItem = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            launchedShortcutItem = shortcutItem
        }

        registerSettingsBundle()

        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { (granted, error) in
            if (granted) {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }

        return true
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(handleShortCutItem(shortcutItem))
    }

    func registerSettingsBundle() {
        let appDefaults = [String: AnyObject]()
        UserDefaults.standard.register(defaults: appDefaults)
    }

    func handleShortCutItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        switch shortcutItem.type {
        case "com.TheRobot.GarageOS.Door1":
            GarageClient.sharedInstance.doToggleDoor(true)
            return true
        case "com.TheRobot.GarageOS.Door2":
            GarageClient.sharedInstance.doToggleDoor(false)
            return true
        default:
            return false
        }
    }
}
