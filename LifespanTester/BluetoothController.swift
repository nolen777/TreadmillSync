//
//  BluetoothController.swift
//  LifespanTester
//
//  Created by Dan Crosby on 11/30/22.
//

import Foundation
import CoreBluetooth

class LifeSpanSession: NSObject, CBPeripheralDelegate {
    lazy var commands: [(String, [UInt8], (Data) -> Any)] = [
        ("distance", [0xA1, 0x85, 0x00, 0x00, 0x00], toDecimal),
        ("calories", [0xA1, 0x87, 0x00, 0x00, 0x00], toUInt16),
        ("steps", [0xA1, 0x88, 0x00, 0x00, 0x00], toUInt16),
        ("time", [0xA1, 0x89, 0x00, 0x00, 0x00], toSeconds),
    ]
    
    var currentCommandIndex: Int = 0
    let peripheral: CBPeripheral
    let characteristic: CBCharacteristic
                   
    init(peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        self.peripheral = peripheral
        self.characteristic = characteristic
        super.init()
        peripheral.delegate = self
        peripheral.setNotifyValue(true, for: characteristic)
    }
    
    func startCommands() -> Void {
        currentCommandIndex = 0
        sendNextCommand()
    }
    
    func sendNextCommand() {
        if currentCommandIndex < commands.count {
            let command = commands[currentCommandIndex]
            let name = command.0
            let msg = Data(command.1)
            peripheral.writeValue(msg, for: characteristic, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let command = commands[currentCommandIndex]
        guard let value = characteristic.value else {
            print("unable to fetch data for \(command.0)")
            return
        }
        print("key \(commands[currentCommandIndex].0): \(command.2(value))")
        currentCommandIndex = currentCommandIndex + 1
        sendNextCommand()
    }
    
    func toUInt16(_ responseData: Data) -> UInt16 {
        let bytes = responseData.subdata(in: 2..<4)
        return UInt16(bytes[0]) << 8 | UInt16(bytes[1])
    }
    
    func toDecimal(_ responseData: Data) -> Decimal {
        let wholeByte = responseData[2]
        let fracByte = responseData[3]
        
        return Decimal(wholeByte) + Decimal(fracByte) / 100
    }
    
    func toSeconds(_ responseData: Data) -> Int {
        let hours = Int(responseData[2])
        let minutes = Int(responseData[3])
        let seconds = Int(responseData[4])
        
        return 3600 * hours + 60 * minutes + seconds
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
    }
}

class BluetoothController: NSObject {
    private var centralManager: CBCentralManager!
    
    var peripherals = Set<CBPeripheral>()
    var lifespanUUID: UUID?
    var selectedPeripheral: CBPeripheral?
    var currentName: String?
    var session: LifeSpanSession?
    
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
                    session = LifeSpanSession(peripheral: peripheral, characteristic: ch)
                    session?.startCommands()
//                    DispatchQueue.global(qos: DispatchQoS.QoSClass.utility).async {
//                        for command in self.commands {
//                            let name = command.key
//                            let msg = Data(command.value)
//                            peripheral.setNotifyValue(true, for: ch)
//                            if (ch.properties.contains(.write)) {
//                                print("this one is writable")
//                                peripheral.writeValue(msg, for: ch, type: CBCharacteristicWriteType.withResponse)
//                            }
//
//                            //                            if (ch.properties.contains(.writeWithoutResponse)) {
//                            //                                print("this one is writable without response")
//                            //                                peripheral.writeValue(msg, for: ch, type: CBCharacteristicWriteType.withoutResponse)
//                            //                            }
//                        }
//                    }
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

}
