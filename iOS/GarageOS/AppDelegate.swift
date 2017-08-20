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
    var vc = ViewController()
    
    var deviceToken:Data?
    var notificationHub:SBNotificationHub?
    var launchedShortcutItem: UIApplicationShortcutItem?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            launchedShortcutItem = shortcutItem
        }
        
        registerSettingsBundle()

        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { (granted, error) in
            application.registerForRemoteNotifications()
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
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
   
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {

    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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
                print("Error registering for notification: \(error)")
            }
        })
        
    }

    
    func handleShortCutItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        var handled = false
        
        guard let shortCutType = shortcutItem.type as String? else { return false }
        
        switch (shortCutType) {
        case "com.TheRobot.GarageOS.Door1":
            vc.toggleDoor(true)
            handled = true
            break
        case "com.TheRobot.GarageOS.Door2":
            vc.toggleDoor(false)
            handled = true
            break
        default:
            break
        }
        
        return handled
    }
    
    
}

