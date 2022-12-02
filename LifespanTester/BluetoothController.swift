//
//  BluetoothController.swift
//  LifespanTester
//
//  Created by Dan Crosby on 11/30/22.
//

import Foundation
import CoreBluetooth

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

class LifeSpanSession: NSObject, CBPeripheralDelegate {
    let commands: [(description: String, command: [UInt8], processor: (Data) -> Any)] = [
        ("speedInMph", [0xA1, 0x82, 0x00, 0x00, 0x00], toDecimal),
        ("distanceInMiles", [0xA1, 0x85, 0x00, 0x00, 0x00], toDecimal),
        ("calories", [0xA1, 0x87, 0x00, 0x00, 0x00], toUInt16),
        ("steps", [0xA1, 0x88, 0x00, 0x00, 0x00], toUInt16),
        ("timeInSeconds", [0xA1, 0x89, 0x00, 0x00, 0x00], toSeconds),
    ]
    
    var currentCommandIndex: Int = 0
    var responseDict = [String : Any]()
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
            peripheral.writeValue(Data(command.command), for: characteristic, type: CBCharacteristicWriteType.withResponse)
        } else {
            let json = try! JSONSerialization.data(withJSONObject: responseDict)
            print("complete dictionary:")
            print("\(String(decoding: json, as: UTF8.self))")
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
        let key = command.description
        let response = command.processor(value)
        responseDict[key] = response
        currentCommandIndex = currentCommandIndex + 1
        sendNextCommand()
    }
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
    }
}

class BluetoothController: NSObject {
    private var centralManager: CBCentralManager!
    
    let service0CBUUID: CBUUID = CBUUID(string: "180A")
    let serviceCBUUID: CBUUID = CBUUID(data: Data(bytes:[255, 240], count: 2))
    let service2CBUUID: CBUUID = CBUUID(string: "49535343-5D82-6099-9348-7AAC4D5FBC51")
    let service3CBUUID: CBUUID = CBUUID(string: "49535343-026E-3A9B-954C-97DAEF17E26E")
    let service4CBUUID: CBUUID = CBUUID(string: "93D7427A-DA79-EC65-48AD-201EBE53A848")
    
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
            //centralManager.scanForPeripherals(withServices: [serviceCBUUID])
            //centralManager.scanForPeripherals(withServices: [service4CBUUID, service0CBUUID, serviceCBUUID, service2CBUUID, service3CBUUID])
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
        peripheral.discoverServices(nil)//[serviceCBUUID])
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for ch in characteristics {
                
                if ch.uuid.uuidString == "FFF1" {
                    session = LifeSpanSession(peripheral: peripheral, characteristic: ch)
                    session?.startCommands()
                }
            }
        }
    }
    
}
