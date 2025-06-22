//
//  AppDelegate.swift
//  Pastie
//
//  Created by Tanner Bennett on 3/8/24.
//

import UIKit
import notify

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var pastieController: PastieController?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let pc = PastieController()
        
        self.pastieController = pc
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = pc
        self.window?.makeKeyAndVisible()

        var token: Int32 = 0
        notify_register_dispatch("com.apple.pasteboard.changed", &token, DispatchQueue.main, { _ in
            pc.pasteTables?.forEach { $0.reloadData(true) }
        })
        
        // Check if app was launched from opening a file
        if let url = launchOptions?[.url] as? URL {
            self.application(application, open: url)
        }
        
        return true
    }
    
    @discardableResult
    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return self.pastieController?.selectedTable?.tryOpenDatabase(url) ?? false
    }
}

extension PastieController {
    var pasteTables: [PBViewController]? {
        viewControllers?.map { $0 as! PBViewController }
    }
    
    var selectedTable: PBViewController? {
        selectedViewController as? PBViewController
    }
}
