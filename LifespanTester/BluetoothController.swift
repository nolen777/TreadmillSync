//
//  BluetoothController.swift
//  LifespanTester
//
//  Created by Dan Crosby on 11/30/22.
//

import Foundation
import CoreBluetooth

class LifeSpanSession: NSObject, CBPeripheralDelegate {
    let commands: [(String, [UInt8])] = [
        ("steps", [0xA1, 0x88, 0x00, 0x00, 0x00])
    ]
    
    var currentCommand: Int = 0
    let peripheral: CBPeripheral
                   
    init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
    }
    
}

class BluetoothController: NSObject {
    private var centralManager: CBCentralManager!
    
    var peripherals = Set<CBPeripheral>()
    var lifespanUUID: UUID?
    var selectedPeripheral: CBPeripheral?
    var currentName: String?

    
    func setUp() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
}

extension BluetoothController: CBCentralManagerDelegate, CBPeripheralDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            centralManager.scanForPeripherals(withServices: nil)
            
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
        if !peripherals.contains(peripheral) {
            peripherals.insert(peripheral)
            
            if peripheral.name == "LifeSpan" {
                lifespanUUID = peripheral.identifier
                centralManager.connect(peripheral)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected!")
        peripheral.delegate = self
        selectedPeripheral = peripheral
        let services = peripheral.discoverServices(nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("Service: \(service.uuid.uuidString)")
        if let characteristics = service.characteristics {
            print("Characteristics:")
            for ch in characteristics {
                print("UUID: \(ch.uuid)")
                
                if ch.uuid.uuidString == "FFF1" {
                    
                    DispatchQueue.global(qos: DispatchQoS.QoSClass.utility).async {
                        for command in self.commands {
                            let name = command.key
                            let msg = Data(command.value)
                            peripheral.setNotifyValue(true, for: ch)
                            if (ch.properties.contains(.write)) {
                                print("this one is writable")
                                peripheral.writeValue(msg, for: ch, type: CBCharacteristicWriteType.withResponse)
                            }
                            
                            //                            if (ch.properties.contains(.writeWithoutResponse)) {
                            //                                print("this one is writable without response")
                            //                                peripheral.writeValue(msg, for: ch, type: CBCharacteristicWriteType.withoutResponse)
                            //                            }
                        }
                    }
                    //                print(ch.properties)
                    //                if ch.isNotifying {
                    //                    print("this one is notifying")
                    //                }
                    //
                    //                let bytes: [UInt8] = [0xA1, 0x88, 0x00, 0x00, 0x00]
                    //                let msg = Data(bytes)
                    //                if (ch.properties.contains(.write)) {
                    //                    print("this one is writable")
                    //                    peripheral.writeValue(msg, for: ch, type: CBCharacteristicWriteType.withResponse)
                    //                }
                    //                if (ch.properties.contains(.writeWithoutResponse)) {
                    //                    print("this one is writable without response")
                    //                    peripheral.writeValue(msg, for: ch, type: CBCharacteristicWriteType.withoutResponse)
                    //                }
                    //                if (ch.properties.contains(.notify)) {
                    //                    peripheral.setNotifyValue(true, for: ch)
                    //                }
                    //                   }
                    //                } else {
                    //                    peripheral.readValue(for: ch)
                    //                }
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("aha!")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("Got updated value \(characteristic.value) for \(characteristic.uuid)")
        if let value = characteristic.value, value.count == 4 {
            let num = Int(value[0]) << 8 + Int(value[1])
            print("Got \(num)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        //   peripheral.readValue(for: characteristic)
    }
}
