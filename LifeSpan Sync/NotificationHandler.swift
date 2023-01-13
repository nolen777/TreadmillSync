//
//  NotificationHandler.swift
//  LifeSpan Sync
//
//  Created by Dan Crosby on 12/8/22.
//

import Foundation
import UserNotifications

class NotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    static let handler = NotificationHandler()
    let formatter = DateComponentsFormatter()
    
    var notificationsAllowed: Bool = true
    
    override init() {
        super.init()
        
        formatter.allowedUnits = [.minute]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropLeading
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization \(error)")
            }
            
            self.notificationsAllowed = granted
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner])
    }
    
    func displayNote(stepCount: Int64, distanceInMiles: Double, calorieCount: Int64, elapsedTime: TimeInterval) {
        if self.notificationsAllowed {
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
            
            let content = UNMutableNotificationContent()
            content.title = "\(stepCount) steps in \(formatter.string(from: elapsedTime)!)"
            content.body = "\(distanceInMiles) miles, \(calorieCount) calories"
            let notification = UNNotificationRequest(identifier: "StepRequest", content: content, trigger: trigger)
            
            let nc = UNUserNotificationCenter.current()
            nc.delegate = self
            
            nc.add(notification) { error in
                if let err = error {
                    print("Error sending notification: \(err)")
                }
            }
        }
    }
}
