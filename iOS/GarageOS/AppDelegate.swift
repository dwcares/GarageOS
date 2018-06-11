//
//  AppDelegate.swift
//  GarageOS
//
//  Created by David Washington on 12/22/15.
//  Copyright © 2015 David Washington. All rights reserved.
//

import UIKit
import UserNotifications


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    var deviceToken:Data?
    var notificationHub:SBNotificationHub?
    var launchedShortcutItem: UIApplicationShortcutItem?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            launchedShortcutItem = shortcutItem
        }
        
        registerSettingsBundle()

        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { (granted, error) in
            if (granted) {
                DispatchQueue.main.async { // Correct
                    application.registerForRemoteNotifications()
                }
            } else {
                print("Register for notifications error: \(error)")
            }
        }
        
        BITHockeyManager.shared().configure(withIdentifier: "33d30f9d73cb41c8816289c0344623c9")
        BITHockeyManager.shared().start()
        BITHockeyManager.shared().authenticator.authenticateInstallation()
        
        return true
        
    }

    
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register with error: \(error)");
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        self.notificationHub = SBNotificationHub(connectionString: Secrets.AzureNotificationHubConnection, notificationHubPath:Secrets.AzureNotificationHubPath)
        self.deviceToken = deviceToken
        
        print("Device Token: \(deviceToken)")

        registerNotificationTags()
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        let handledShortCutItem = handleShortCutItem(shortcutItem)
        
        completionHandler(handledShortCutItem)
    }
    
    
    func registerSettingsBundle() {
        let appDefaults = [String:AnyObject]()
        UserDefaults.standard.register(defaults: appDefaults)
 
    }
    
    func registerNotificationTags() {
        var tags = Set<String>()
        
        if (UserDefaults.standard.bool(forKey: "settingsDoorAlert")) { tags.insert("doorAlert") }
        if (UserDefaults.standard.bool(forKey: "settingsDoorStatus")) { tags.insert("doorStatus") }
        
        self.notificationHub?.registerNative(withDeviceToken: deviceToken, tags:tags, completion: { (error) in
            if (error != nil) {
                print("Error registering for notification: \(error!)")
            }
        })
        
    }

    
    func handleShortCutItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        var handled = false
        
        guard let shortCutType = shortcutItem.type as String? else { return false }
        
        switch (shortCutType) {
        case "com.TheRobot.GarageOS.Door1":
            GarageClient.sharedInstance.doToggleDoor(true)
            handled = true
            break
        case "com.TheRobot.GarageOS.Door2":
            GarageClient.sharedInstance.doToggleDoor(false)
            handled = true
            break
        default:
            break
        }
        
        return handled
    }
    
    
}

