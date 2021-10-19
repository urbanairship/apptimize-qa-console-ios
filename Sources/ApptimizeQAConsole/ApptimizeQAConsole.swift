//
//  ApptimizeQAConsole.swift
//  ApptimizeQAConsole
//
//  Copyright © 2021 Urban Airship Inc., d/b/a Airship.
//

import UIKit
import Apptimize

public class ApptimizeQAConsole {
    fileprivate static let shared = ApptimizeQAConsole()
    
    private var _isViewControllerPresented = false
    private var rootViewController: UIViewController?
    
    public static var isShakeGestureEnabled: Bool = true
    public static var isViewControllerPresented: Bool {
        get { shared._isViewControllerPresented }
    }
    
    private init() {}
    
    public static func display() {
        guard let controller = UIApplication.topViewController(), !shared._isViewControllerPresented else {
            return
        }
        
        let root = ConsoleViewController.loadFromNib()
        root.onClosed = {
            shared._isViewControllerPresented = false
            shared.rootViewController = nil
        }
        shared.rootViewController = root

        let navigation = UINavigationController(rootViewController: root)
        controller.present(navigation, animated: true, completion: nil)
        shared._isViewControllerPresented = true
    }
    
    public static func hide() {
        guard let controller = shared.rootViewController else {
            return
        }
        
        controller.dismiss(animated: true)
    }
}

private extension UIApplication {
    class func topViewController() -> UIViewController? {
        let window: UIWindow?
        
        if #available(iOS 13, *) {
            window = UIApplication.shared.connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .map { $0 as? UIWindowScene }
                .compactMap { $0 }
                .first?.windows
                .filter { $0.isKeyWindow }
                .first
        } else {
            window = UIApplication.shared.keyWindow
        }
        
        return window?.rootViewController
    }
}

public extension UIWindow {
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if !ApptimizeQAConsole.isShakeGestureEnabled || ApptimizeQAConsole.isViewControllerPresented {
            return
        }
        
        if motion == .motionShake {
            ApptimizeQAConsole.display()
        }
    }
}
