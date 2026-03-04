//
//  notesappApp.swift
//  notesapp
//
//  Created by Adam on 29/1/26.
//

import SwiftUI

#if canImport(UIKit)
import UIKit

/// Runs before any SwiftUI view — launch screen is still showing,
/// so the ~200ms keyboard load is invisible to the user.
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Temporary window to host a UITextField for keyboard pre-warm
        let window = UIWindow(frame: UIScreen.main.bounds)
        let vc = UIViewController()
        window.rootViewController = vc
        window.makeKeyAndVisible()

        let tf = UITextField(frame: .zero)
        tf.autocorrectionType = .no
        tf.alpha = 0
        vc.view.addSubview(tf)
        tf.becomeFirstResponder()
        tf.resignFirstResponder()
        tf.removeFromSuperview()

        window.isHidden = true

        // Also prepare haptic engines
        UIImpactFeedbackGenerator(style: .medium).prepare()
        UIImpactFeedbackGenerator(style: .heavy).prepare()

        return true
    }
}
#endif

@main
struct notesappApp: App {
    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
