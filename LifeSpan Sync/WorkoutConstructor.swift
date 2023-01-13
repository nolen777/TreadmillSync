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
    let stepCountType: HKQuantityType!
    let calorieCountType: HKQuantityType!
    let distanceType: HKQuantityType!
    
    init() {
        guard let stepCountType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount) else {
            fatalError("Unable to create a step count type")
        }
        self.stepCountType = stepCountType
        
        guard let calorieCountType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned) else {
            fatalError("Unable to create calorie count type")
        }
        self.calorieCountType = calorieCountType
        
        guard let distanceType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning) else {
            fatalError("Unable to create distance type")
        }
        self.distanceType = distanceType
        
        DispatchQueue.main.async { [self] in
            let workoutStatus = store.authorizationStatus(for: HKWorkoutType.workoutType())
            let stepStatus = store.authorizationStatus(for: stepCountType)
            let calorieStatus = store.authorizationStatus(for: calorieCountType)
            let distanceStatus = store.authorizationStatus(for: distanceType)
            
            if workoutStatus == .notDetermined ||
                stepStatus == .notDetermined ||
                calorieStatus == .notDetermined ||
                distanceStatus == .notDetermined {
                store.requestAuthorization(toShare: [HKWorkoutType.workoutType(), stepCountType, calorieCountType, distanceType], read: nil) { (success, error) -> Void in
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
        
        store.save(indoorWalk) { [self] (success, error) -> Void in
            guard success else {
                print("Failed to save walk with error \(String(describing: error))")
                return
            }
            
            let stepQuantity = HKQuantity(unit: HKUnit.count(), doubleValue: Double(stepCount))
            let stepSample = HKQuantitySample(type: stepCountType, quantity: stepQuantity, start: startDate, end: endDate)
            
            let activeEnergySample = HKQuantitySample(type: calorieCountType, quantity: energyBurned, start: startDate, end: endDate)
            
            let distanceSample = HKQuantitySample(type: distanceType, quantity: distance, start: startDate, end: endDate)
            
            store.add([stepSample, activeEnergySample, distanceSample], to: indoorWalk) { (success, error) -> Void in
                guard success else {
                    print("Failed to add steps with error \(String(describing: error))")
                    return
                }
                
                NotificationHandler.handler.displayNote(stepCount: stepCount, distanceInMiles: distanceInMiles, calorieCount: calorieCount, elapsedTime: seconds)
            }
        }
    }
}
