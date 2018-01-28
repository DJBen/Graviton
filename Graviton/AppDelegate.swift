//
//  AppDelegate.swift
//  Graviton
//
//  Created by Ben Lu on 9/13/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import UIKit
import Orbits
import RealmSwift
import SwiftyBeaver

let logger = SwiftyBeaver.self

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        configureLogging()
        migrateRealmIfNeeded()

        UINavigationBar.configureNavigationBarStyles()
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedStringKey.foregroundColor.rawValue: UIColor.white]

        // Disable online fetching in unit tests
        let isInTest = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(2)) {
            EphemerisManager.default.fetch(mode: isInTest ? .localOnly : .mixed)
        }
        RiseTransitSetManager.globalMode = isInTest ? .localOnly : .preferLocal
        CelestialBodyObserverInfoManager.globalMode = isInTest ? .localOnly : .preferLocal
        LocationManager.default.startLocationService()

        DispatchQueue.main.async {
            self.displaySceneKitBrokenWarning()
        }

        return true
    }

    private func displaySceneKitBrokenWarning() {
        let forumUrl = URL(string:"https://forums.developer.apple.com/thread/92671")!
        guard Device.isSceneKitBroken && UIApplication.shared.canOpenURL(forumUrl) && OccationalPrompt.shouldShowPrompt(forKey: "sceneKitBrokenWarning", timeInterval: 86400) else {
            return
        }
        let alertController = UIAlertController(title: "iOS SceneKit Bug", message: "There exists a bug on iOS 11.2 that causes transparent textures not to be rendered. As a result, some nodes will appear square-like. iOS 11.3 fixed this issue. Please update to latest system version whenever you can.", preferredStyle: .alert)
        let openForumAction = UIAlertAction(title: "See Detail", style: .default) { (_) in
            UIApplication.shared.open(forumUrl, options: [:], completionHandler: nil)
        }
        alertController.addAction(openForumAction)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        window?.rootViewController?.present(alertController, animated: true) {
            OccationalPrompt.recordPrompt(forKey: "sceneKitBrokenWarning")
        }
    }

    private func configureLogging() {
        let console = ConsoleDestination()
        console.minLevel = .verbose
        logger.addDestination(console)
    }

    private func migrateRealmIfNeeded() {
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: 1,

            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: { _, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if oldSchemaVersion < 1 {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
        })

        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config

        // Now that we've told Realm how to handle the schema change, opening the file
        // will automatically perform the migration
        _ = try! Realm()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

extension UINavigationController {
    override open var childViewControllerForStatusBarStyle: UIViewController? {
        return self.topViewController
    }
}
