//
//  BluetoothController.swift
//  LifespanTester
//
//  Created by Dan Crosby on 11/30/22.
//

import Foundation
import CoreBluetooth

class BluetoothController: NSObject {
    private var centralManager: CBCentralManager!
    private var peripheralManager: CBPeripheralManager!
    private let virtualPeripheral = PhoneSyncPeripheral()
    
    let service0CBUUID: CBUUID = CBUUID(string: "180A")
    let serviceCBUUID: CBUUID = CBUUID(data: Data(bytes:[255, 240], count: 2))
    let service2CBUUID: CBUUID = CBUUID(string: "49535343-5D82-6099-9348-7AAC4D5FBC51")
    let service3CBUUID: CBUUID = CBUUID(string: "49535343-026E-3A9B-954C-97DAEF17E26E")
    let service4CBUUID: CBUUID = CBUUID(string: "93D7427A-DA79-EC65-48AD-201EBE53A848")
    
    var lifespanUUID: UUID?
    var currentName: String?
    var session: LifeSpanSession?
    
    func setUp() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: virtualPeripheral, queue: nil)
    }
    
    class LifeSpanSession: NSObject, CBPeripheralDelegate {
        enum LifeSpanSessionError: Error {
            case invalidSpeed
        }
        
        let startCommand: [UInt8] = [0xE1, 0x00, 0x00, 0x00, 0x00]
        let stopCommand: [UInt8] = [0xE0, 0x00, 0x00, 0x00, 0x00]
        func speedCommand(speed: Float) throws -> [UInt8] {
            guard (speed > 4.0 || speed < 0.4) else {
                throw LifeSpanSessionError.invalidSpeed
            }
            let speedHundredths = UInt16(speed * 100.0)
            let unitsByte = UInt8(speedHundredths >> 8)
            let fractionByte = UInt8(speedHundredths & 0xFF)
            return [0xd0, unitsByte, fractionByte, 0x00, 0x00]
        }
        
        var currentCommandIndex: Int = 0
        var responseDict = [String : Any]()
        let finishedCallback: (CBPeripheral, [String: Any]) -> Void
        let peripheral: CBPeripheral
        var characteristic1: CBCharacteristic!
        var characteristic2: CBCharacteristic!
        
        init(peripheral: CBPeripheral, callback: @escaping (CBPeripheral, [String: Any]) -> Void) {
            self.peripheral = peripheral
            self.finishedCallback = callback
            super.init()
            peripheral.delegate = self
        }
        
        func startCommands() -> Void {
            currentCommandIndex = 0
            sendNextCommand()
        }
        
        func run() -> Void {
            peripheral.discoverServices(nil)
        }
        
        func sendNextCommand() {
            if currentCommandIndex < LifeSpanCommands.queryCommands.count {
                let command = LifeSpanCommands.queryCommands[currentCommandIndex]
                peripheral.writeValue(command.commandData, for: characteristic1!, type: CBCharacteristicWriteType.withResponse)
            } else {
                print("complete dictionary:")
                print("\(responseDict)")
                finishedCallback(peripheral, responseDict)
            }
        }
        
        func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
            responseDict["timestamp"] = PhoneSyncService.dateFormatter.string(from: Date.now)
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
                        characteristic1 = ch
                        peripheral.setNotifyValue(true, for: ch)
                    } else if ch.uuid.uuidString == "FFF2" {
                        characteristic2 = ch
                        peripheral.writeValue(Data(hexString: "0200000000")!, for: ch, type: CBCharacteristicWriteType.withResponse)
                    }
                }
            }
        }
        
        func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
            guard let value = characteristic.value else {
                print("unable to fetch data")
                return
            }
            if value == Data(hexString: "02aa11180000")! {
                peripheral.writeValue(Data(hexString: "c000000000")!, for: characteristic2, type: CBCharacteristicWriteType.withResponse)
            } else if value == Data(hexString: "c0ff00000000") {
                startCommands()
            } else {
                let command = LifeSpanCommands.queryCommands[currentCommandIndex]
                let key = command.description
                let response = command.responseProcessor(value)
                responseDict[key] = response
                currentCommandIndex = currentCommandIndex + 1
                sendNextCommand()
            }
        }
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
        if peripheral.name == "LifeSpan" {
            lifespanUUID = peripheral.identifier
            session = LifeSpanSession(peripheral: peripheral, callback: sessionFinished)
            centralManager.connect(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected!")
        session?.run()
    }
    
    func sessionFinished(peripheral: CBPeripheral, dict: [String: Any]) {
        virtualPeripheral.values.append(dict)
        centralManager.cancelPeripheralConnection(peripheral)
        centralManager.stopScan()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 15, execute: {
            self.centralManager.scanForPeripherals(withServices: nil)
        })
        
        session = nil
    }
}
