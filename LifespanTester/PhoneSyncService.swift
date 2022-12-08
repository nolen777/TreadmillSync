//
//  PhoneSyncService.swift
//  LifespanTester
//
//  Created by Dan Crosby on 12/6/22.
//

import CoreBluetooth

struct PhoneSyncService {
    static let serviceUUID = CBUUID(string: "b0779ed8-f74a-44f5-a9bf-eeb0c76a502e")
    static let characteristicUUID = CBUUID(string: "1bc63fa8-b79d-461c-8cf3-839fc5fba809")
    
    static let dateFormatter = ISO8601DateFormatter()
}
