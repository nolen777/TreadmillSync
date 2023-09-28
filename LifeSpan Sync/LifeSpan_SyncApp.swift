//
//  LifeSpan_SyncApp.swift
//  LifeSpan Sync
//
//  Created by Dan Crosby on 12/7/22.
//

import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    private let workoutConstructor = WorkoutConstructor()
    private let fileManager = FileManager.default
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        application.registerForRemoteNotifications()
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let hexToken = deviceToken.hexEncodedString()
        print("Device token: \(hexToken)")
        
        Task {
            try! await DeviceKeyManager.shared.register(hexToken: hexToken)
        }
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ){
        print("Received a remote notification! \(userInfo)")
        
        let dict = Dictionary(uniqueKeysWithValues: userInfo.compactMap { (key, value) in
            if let keyString = key as? String {
                return (keyString, value)
            } else {
                return nil
            }
        })
        workoutConstructor.handle(dictionary: dict)
        completionHandler(UIBackgroundFetchResult.newData)
    }
}

@main
struct LifeSpan_SyncApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
