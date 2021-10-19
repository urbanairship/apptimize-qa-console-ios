//
//  AppDelegate.swift
//  QAConsoleIntegration
//
//  Copyright © 2021 Urban Airship Inc., d/b/a Airship.
//

import UIKit
import Apptimize
#if DEBUG
import ApptimizeQAConsole
#endif

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Set your Apptimize key here.
        Apptimize.start(withApplicationKey: "YourApptimizeApplicationKey")
        ApptimizeQAConsole.isShakeGestureEnabled = false
        ApptimizeQAConsole.display()
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

