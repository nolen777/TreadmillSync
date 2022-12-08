//
//  WorkoutConstructor.swift
//  LifeSpan Sync
//
//  Created by Dan Crosby on 12/7/22.
//

import Foundation
import HealthKit

class WorkoutConstructor {
    let store = HKHealthStore()
    
    init() {
        DispatchQueue.main.async {
            let workoutStatus = self.store.authorizationStatus(for: HKWorkoutType.workoutType())
            let stepStatus = self.store.authorizationStatus(for: HKObjectType.quantityType(forIdentifier: .stepCount)!)
            if workoutStatus == .notDetermined || stepStatus == .notDetermined {
                self.store.requestAuthorization(toShare: [HKWorkoutType.workoutType(), HKObjectType.quantityType(forIdentifier: .stepCount)!], read: nil) { (success, error) -> Void in
                    guard success else {
                        fatalError("Failed to authorize HealthKit access with error \(String(describing: error))")
                    }
                }
            }
        }
    }
    
    func handle(dictionary: [String : Any]) {
        // TODO: don't try this until authorization is granted
        
        guard HKHealthStore.isHealthDataAvailable() else {
            fatalError("HealthKit unavailable")
        }
        
        guard let tsString = dictionary["timestamp"] as? String, let endDate = PhoneSyncService.dateFormatter.date(from: tsString) else {
            print("unable to parse timestamp")
            return
        }
        guard let seconds = dictionary["timeInSeconds"] as? Double else {
            print("unable to parse time in seconds")
            return
        }
        guard let stepCount = dictionary["steps"] as? Int64 else {
            print("Unable to parse steps")
            return
        }
        guard let distanceInMiles = dictionary["distanceInMiles"] as? Double else {
            print("Unable to parse distance")
            return
        }
        guard let calorieCount = dictionary["calories"] as? Int64 else {
            print("Unable to parse calories")
            return
        }
        let startDate = endDate.addingTimeInterval(-seconds)
        let distance = HKQuantity(unit: HKUnit.mile(), doubleValue: distanceInMiles)
        let energyBurned = HKQuantity(unit: HKUnit.largeCalorie(), doubleValue: Double(calorieCount))
        let indoorWalk = HKWorkout(activityType: HKWorkoutActivityType.walking,
                                   start: startDate,
                                   end: endDate,
                                   duration: seconds,
                                   totalEnergyBurned: energyBurned,
                                   totalDistance: distance,
                                   metadata: nil)
        
        store.save(indoorWalk) { (success, error) -> Void in
            guard success else {
                print("Failed to save walk with error \(String(describing: error))")
                return
            }
            
            guard let stepCountType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount) else {
                fatalError("Unable to create a step count type")
            }
            let stepQuantity = HKQuantity(unit: HKUnit.count(), doubleValue: Double(stepCount))
            let stepSample = HKQuantitySample(type: stepCountType, quantity: stepQuantity, start: startDate, end: endDate)
            
            self.store.add([stepSample], to: indoorWalk) { (success, error) -> Void in
                guard success else {
                    print("Failed to add steps with error \(String(describing: error))")
                    return
                }
                
                NotificationHandler.handler.displayNote(stepCount: stepCount, distanceInMiles: distanceInMiles, calorieCount: calorieCount)
            }
        }
    }
}
