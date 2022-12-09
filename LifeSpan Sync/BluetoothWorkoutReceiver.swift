//
//  BluetoothWorkoutReceiver.swift
//  LifeSpan Sync
//
//  Created by Dan Crosby on 12/7/22.
//

import Foundation
import CoreBluetooth

class BluetoothWorkoutReceiver: NSObject {
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private let workoutConstructor = WorkoutConstructor()
    
    func setUp() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
}

extension BluetoothWorkoutReceiver: CBCentralManagerDelegate, CBPeripheralDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            centralManager.scanForPeripherals(withServices: [PhoneSyncService.serviceUUID])
            
        case .unknown:
            print("")
            
        case .resetting:
            print("")
            
        case .unsupported:
            print("")
            
        case .unauthorized:
            print("")
            
        case .poweredOff:
            print("")
            
        @unknown default:
            print("")
            
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        self.peripheral = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected!")
        centralManager.stopScan()
        peripheral.discoverServices([PhoneSyncService.serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected!")
        centralManager.scanForPeripherals(withServices: [PhoneSyncService.serviceUUID])
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services, let service = services.first(where: { $0.uuid == PhoneSyncService.serviceUUID }) {
            peripheral.discoverCharacteristics([PhoneSyncService.characteristicUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics, let ch = characteristics.first(where: { $0.uuid == PhoneSyncService.characteristicUUID }) {
            peripheral.setNotifyValue(true, for: ch)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let value = characteristic.value else {
            print("unable to fetch data")
            return
        }
        guard let dict = try? JSONSerialization.jsonObject(with: value) as? [String: Any] else {
            if let str = String(data: value, encoding: .utf8) {
                print("Got string \(str); canceling connection")
            } else {
                print("Unable to decode JSON or string; canceling connection")
            }
            
            centralManager.cancelPeripheralConnection(peripheral)
            return
        }
        print("Phone client received dictionary: \(dict)")
        workoutConstructor.handle(dictionary: dict)
    }
}

