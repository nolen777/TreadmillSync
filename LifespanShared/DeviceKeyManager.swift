//
//  DeviceKeyManager.swift
//  LifespanTester
//
//  Created by Dan Crosby on 9/27/23.
//

import Foundation

class DeviceKeyManager {
    public static let shared: DeviceKeyManager = try! DeviceKeyManager()
    
    private let fileManager = FileManager.default
    private let driveURL: URL
    private let keysPath: String
    
    enum DeviceKeyException : Error {
        case iCloudError
    }
    
    private init() throws {
        guard let url = fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") else {
            throw DeviceKeyException.iCloudError
        }
        
        driveURL = url
        
        if (!fileManager.fileExists(atPath: driveURL.path)) {
            try fileManager.createDirectory(at: driveURL, withIntermediateDirectories: false)
        }
    
        let keysURL = driveURL.appendingPathComponent("deviceKeys.txt")
        try fileManager.startDownloadingUbiquitousItem(at: keysURL)
        
        keysPath = keysURL.path
    }
    
    public func getKeys() async -> Set<String> {
        if (fileManager.fileExists(atPath: keysPath)) {
            let keysString = String(bytes: fileManager.contents(atPath: keysPath)!, encoding: .utf8)!
            let keys = keysString.split(separator: "\n")
            return Set(keys.map { String($0) })
        } else {
            return Set()
        }
    }
    
    public func register(hexToken: String) async throws -> Void {
        var existingKeys = await getKeys()
        existingKeys.insert(hexToken)
        
        let keysString = existingKeys.joined(separator: "\n")
        
        print("Registered keys:")
        print(keysString)
        
        try keysString.write(toFile: keysPath, atomically: true, encoding: .utf8)
    }
    
}
