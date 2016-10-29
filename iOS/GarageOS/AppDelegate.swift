//
//  AppDelegate.swift
//  GarageOS
//
//  Created by David Washington on 12/22/15.
//  Copyright © 2015 David Washington. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var vc = ViewController()

    /// Saved shortcut item used as a result of an app launch, used later when app is activated.
    var launchedShortcutItem: UIApplicationShortcutItem?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
         var shouldPerformAdditionalDelegateHandling = true
        
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsShortcutItemKey] as? UIApplicationShortcutItem {
            
            launchedShortcutItem = shortcutItem
            shouldPerformAdditionalDelegateHandling = false
        }
        
        return shouldPerformAdditionalDelegateHandling
    }
    
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: Bool -> Void) {
        let handledShortCutItem = handleShortCutItem(shortcutItem)
        
        completionHandler(handledShortCutItem)
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        guard let shortcut = launchedShortcutItem else { return }
        
        handleShortCutItem(shortcut)
        
        launchedShortcutItem = nil
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func handleShortCutItem(shortcutItem: UIApplicationShortcutItem) -> Bool {
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

