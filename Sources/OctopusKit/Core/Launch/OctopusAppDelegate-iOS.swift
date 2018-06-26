//
//  OctopusAppDelegate-iOS.swift
//  OctopusKit
//
//  Created by ShinryakuTako@invadingoctopus.io on 2014-10-22
//  Copyright © 2018 Invading Octopus. Licensed under Apache License v2.0 (see LICENSE.txt)
//

import SpriteKit
import CoreData

#if canImport(UIKit) // CHECK: Include tvOS?

/// The intermediary between the `UIApplication` provided by the operating system and your OctopusKit game.
///
/// - Important: Your project must have an `AppDelegate` class (prefixed by `@UIApplicationMain`) that inherits from `OctopusAppDelegate`, to serve as the launching point for your game.
///
/// Your `AppDelegate` should only implement `applicationWillLaunchOctopusKit()` as all other system events are handled by `OctopusAppDelegate`.
///
/// Your `applicationWillLaunchOctopusKit()` method must call `OctopusKit(appName:gameController:)` to initialize the `OctopusKit.shared` singleton instance, specifying a `OctopusGameController` or its subclass, with a list of `OctopusGameState`s and their associated scenes.
class OctopusAppDelegate: UIResponder, UIApplicationDelegate {
    
    // Apple Documentation: https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1623056-window
    /// This property contains the window used to present the app’s visual content on the device’s main screen.
    ///
    /// Implementation of this property is required if your app’s `Info.plist` file contains the `UIMainStoryboardFile` key.
    ///
    /// The Xcode project templates usually include a synthesized declaration of the property automatically for the app delegate. The default value of this synthesized property is `nil`, which causes the app to create a generic `UIWindow` object and assign it to the property. If you want to provide a custom window for your app, you must implement the getter method of this property and use it to create and return your custom window.
    var window: UIWindow?
    
    #if swift(>=4.2)
    // TODO: Remove this temporary alias and incorporate changes into main code after Swift 4.2 launches.
    public typealias UIApplicationLaunchOptionsKey = UIApplication.LaunchOptionsKey
    #endif
    
    /// Override point for customization after game launch.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        OctopusKit.logForFramework.add()
        
        // CHECK: `registerUserDefaultsFromSettingsBundle()`?
        self.applicationWillLaunchOctopusKit()
        OctopusKit.verifyConfiguration()

        return true
    }
    
    /// The launching point for the OctopusKit.
    ///
    /// - IMPORTANT: Override this in your app-specific subclass of `OctopusAppDelegate` and call `OctopusKit(appName:gameController:)` to setup the engine.
    func applicationWillLaunchOctopusKit() {
        fatalError("OctopusKit: OctopusAppDelegate.applicationWillLaunchOctopusKit() not implemented.")
    }
    
    // MARK: - Pause/Unpause
    
    /// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    func applicationWillEnterForeground(_ application: UIApplication) {
        OctopusKit.logForFramework.add()
        
        if let scene = OctopusKit.shared?.currentScene {
            scene.applicationWillEnterForeground()
        }
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        /// Restart any tasks that were paused (or not yet started) while the game was inactive. If the game was previously in the background, optionally refresh the user interface.
        
        OctopusKit.logForFramework.add()
        
        // NOTE: Call `scene.applicationDidBecomeActive()` before `enterInitialState()` so we don't issue a superfluous unpause event to the very first scene of the game.
        
        // CHECK: Compare launch performance between calling `OctopusSceneController.enterInitialState()` from `OctopusAppDelegate.applicationDidBecomeActive(_:)`! versus `OctopusSceneController.viewWillLayoutSubviews()`
        
        if let scene = OctopusKit.shared?.currentScene {
            scene.applicationDidBecomeActive()
        }
        else if
            let sceneController = OctopusKit.shared?.sceneController,
            !sceneController.didEvokeGameControllerInitialState
        {
            sceneController.enterInitialState()
        }
        
    }
    
    /// Sent when the game is about to move from active to inactive state.
    ///
    /// This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the player quits the game and it begins the transition to the background state.
    ///
    /// Use this method to pause the gameplay, disable timers, and invalidate graphics rendering callbacks.
    func applicationWillResignActive(_ application: UIApplication) {
        OctopusKit.logForFramework.add()
        
        if let scene = OctopusKit.shared?.currentScene {
            scene.applicationWillResignActive()
        }
    }
    
    /// Use this method to release shared resources, save player data, invalidate timers, and store enough game state information to restore your application to its current state in case it is terminated later.
    ///
    /// If your game supports background execution, this method is called instead of `applicationWillTerminate:` when the player quits.
    func applicationDidEnterBackground(_ application: UIApplication) {
        OctopusKit.logForFramework.add()
        
        if let scene = OctopusKit.shared?.currentScene {
            scene.applicationDidEnterBackground()
        }
    }
    
    /// Called when the game is about to terminate. Save data if appropriate. See also `applicationDidEnterBackground:`.
    func applicationWillTerminate(_ application: UIApplication) {
        OctopusKit.logForFramework.add()
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    
    // MARK: - Core Data stack
    
    public lazy var persistentContainer: NSPersistentContainer = {
        
        guard let appName = OctopusKit.shared?.appName else {
            fatalError("OctopusKit.appName not set")
        }
        
        // The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        
        let container = NSPersistentContainer(name: appName)
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                // Typical reasons for an error here include:
                // The parent directory does not exist, cannot be created, or disallows writing.
                // The persistent store is not accessible, due to permissions or data protection when the device is locked.
                // The device is out of space.
                // The store could not be migrated to the current model version.
                // Check the error message to determine what the actual problem was.
                 
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
    
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    public func saveContext () {
        
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // `fatalError()` causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

#endif