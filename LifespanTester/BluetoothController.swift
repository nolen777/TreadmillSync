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

func fromHexString(_ str: String) -> Data? {
    var md = Data(capacity: str.count / 2)
    var currentByte: UInt8?
    for c in str {
        guard let nibble = c.hexDigitValue else {
            print("Uh oh!")
            return nil
        }
        
        if let existingByte = currentByte {
            md.append(existingByte | UInt8(nibble))
            currentByte = nil
        } else {
            currentByte = UInt8(nibble) << 4
        }
    }
    guard currentByte == nil else {
        print("Bad nibble!")
        return nil
    }
    return md
}

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }
    
    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }
}

class BluetoothController: NSObject {
    private var centralManager: CBCentralManager!
    private var peripheralManager: CBPeripheralManager!
    private let virtualPeripheral = LifeSpanPeripheral()
    
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
    
    class LifeSpanPeripheral: NSObject, CBPeripheralManagerDelegate {
        var mainCharacteristic: CBMutableCharacteristic!
        var secondCharacteristic: CBMutableCharacteristic!
        
        func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
            print("HERE")
            
            peripheral.add(CBMutableService(type: CBUUID(string: "180A"), primary: true))
            peripheral.add(CBMutableService(type: CBUUID(string: "49535343-5D82-6099-9348-7AAC4D5FBC51"), primary: true))
            peripheral.add(CBMutableService(type: CBUUID(string: "49535343-C9D0-CC83-A44A-6FE238D06D33"), primary: true))
            let mainService = CBMutableService(type: CBUUID(string: "FFF0"), primary: true)
            mainCharacteristic = CBMutableCharacteristic(type:CBUUID(string:"FFF1"), properties:[.notify, .write, .writeWithoutResponse], value:nil, permissions:[.readable, .writeable])
            secondCharacteristic = CBMutableCharacteristic(type:CBUUID(string:"FFF2"), properties:[.write], value:nil, permissions:[.writeable])
            mainService.characteristics = [mainCharacteristic, secondCharacteristic]
            
            peripheral.add(mainService)
            peripheral.startAdvertising([CBAdvertisementDataLocalNameKey : "LifeSpan"])
        }
        
        func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
            for request in requests {
                print("did receive write for characteristic \(request.characteristic.uuid.uuidString)")
                print("value is \(String(describing: request.value?.hexEncodedString()))")
                if request.characteristic.uuid.uuidString == "FFF2" {
                    guard let value = request.value else {
                        print("No value written")
                        return
                    }
                    switch (value.hexEncodedString()) {
                        case "0200000000":
                            peripheral.respond(to: request, withResult: CBATTError.success)
                            peripheral.updateValue(fromHexString("02aa11180000")!, for: mainCharacteristic, onSubscribedCentrals: [request.central])
                        
                        case "c000000000":
                            peripheral.respond(to: request, withResult: CBATTError.success)
                            peripheral.updateValue(fromHexString("c0ff00000000")!, for: mainCharacteristic, onSubscribedCentrals: [request.central])
                        
                        case "a191000000":
                            peripheral.respond(to: request, withResult: CBATTError.success)
                            peripheral.updateValue(fromHexString("a1aa05000000")!, for: mainCharacteristic, onSubscribedCentrals: [request.central])
                        
                        case "a181000000":
                            peripheral.respond(to: request, withResult: CBATTError.success)
                            peripheral.updateValue(fromHexString("a1aa00000000")!, for: mainCharacteristic, onSubscribedCentrals: [request.central])
                        
                        case "a161000000":
                            peripheral.respond(to: request, withResult: CBATTError.success)
                            peripheral.updateValue(fromHexString("a1ff00000000")!, for: mainCharacteristic, onSubscribedCentrals: [request.central])
                        
                        case "a162000000":
                            peripheral.respond(to: request, withResult: CBATTError.success)
                            peripheral.updateValue(fromHexString("a1aa00000000")!, for: mainCharacteristic, onSubscribedCentrals: [request.central])
                        
                        case "a187000000":
                            peripheral.respond(to: request, withResult: CBATTError.success)
                            peripheral.updateValue(fromHexString("a1aa06700000")!, for: mainCharacteristic, onSubscribedCentrals: [request.central])
                        
                        case "a182000000":
                            peripheral.respond(to: request, withResult: CBATTError.success)
                            peripheral.updateValue(fromHexString("a1aa00000000")!, for: mainCharacteristic, onSubscribedCentrals: [request.central])
                            
                        case "a185000000":
                            peripheral.respond(to: request, withResult: CBATTError.success)
                            peripheral.updateValue(fromHexString("a1aa0d080000")!, for: mainCharacteristic, onSubscribedCentrals: [request.central])
                        
                        case "a188000000":
                            peripheral.respond(to: request, withResult: CBATTError.success)
                            peripheral.updateValue(fromHexString("a1aa09280300")!, for: mainCharacteristic, onSubscribedCentrals: [request.central])
                        
                        case "a18b000000":
                            peripheral.respond(to: request, withResult: CBATTError.success)
                            peripheral.updateValue(fromHexString("a1aa00000000")!, for: mainCharacteristic, onSubscribedCentrals: [request.central])
                        
                        case "a189000000":
                            peripheral.respond(to: request, withResult: CBATTError.success)
                            peripheral.updateValue(fromHexString("a1aa09280300")!, for: mainCharacteristic, onSubscribedCentrals: [request.central])
                        
                        case "a186000000":
                            peripheral.respond(to: request, withResult: CBATTError.success)
                            peripheral.updateValue(fromHexString("a1aa00000000")!, for: mainCharacteristic, onSubscribedCentrals: [request.central])
                        
                        case "a163000000":
                            peripheral.respond(to: request, withResult: CBATTError.success)
                            peripheral.updateValue(fromHexString("a1ff00000000")!, for: mainCharacteristic, onSubscribedCentrals: [request.central])
                        
                        case "a164000000":
                            peripheral.respond(to: request, withResult: CBATTError.success)
                            peripheral.updateValue(fromHexString("a1ff00000000")!, for: mainCharacteristic, onSubscribedCentrals: [request.central])
                            
                        case "e200000000":
                            peripheral.respond(to: request, withResult: CBATTError.success)
                            peripheral.updateValue(fromHexString("e2aa00000000")!, for: mainCharacteristic, onSubscribedCentrals: [request.central])
                        
                        default:
                            peripheral.respond(to: request, withResult: CBATTError.success)
                            peripheral.updateValue(fromHexString("a1ff00000000")!, for: mainCharacteristic, onSubscribedCentrals: [request.central])
                    }
                }
            }
            
        }
        
        func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
            print("did receive read")
        }
        
        func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
            print("did subscribe to \(characteristic.uuid.uuidString)")
        }
    }
    
    class LifeSpanSession: NSObject, CBPeripheralDelegate {
        enum LifeSpanSessionError: Error {
            case invalidSpeed
        }
        
        let queryCommands: [(description: String, command: Data, processor: (Data) -> Any)] = [
            //            ("unknown1", [0xA1, 0x81, 0x00, 0x00, 0x00], toUInt16), // Always 255, 0 ?
            ("unknownFirst", fromHexString("a191000000")!, toUInt16),
            ("unknownSecond", fromHexString("a181000000")!, toUInt16),
            ("unknownThird", fromHexString("a161000000")!, toUInt16),
            ("unknown62", fromHexString("a162000000")!, toUInt16),
            ("speedInMph", fromHexString("a182000000")!, toDecimal),
            //            ("unknown2", [0xA1, 0x83, 0x00, 0x00, 0x00], toUInt16), // Always 0?
            //            ("unknown3", [0xA1, 0x84, 0x00, 0x00, 0x00], toUInt16), // Always 0?
            ("distanceInMiles", fromHexString("a185000000")!, toDecimal),
            //            ("unknown4", [0xA1, 0x86, 0x00, 0x00, 0x00], toUInt16), // Always 0?
            ("calories", fromHexString("a187000000")!, toUInt16),
            ("steps", fromHexString("a188000000")!, toUInt16),
            ("timeInSeconds", fromHexString("a189000000")!, toSeconds),
            ("unknown8B", fromHexString("a18b000000")!, toSeconds),
            ("unknown89", fromHexString("a189000000")!, toSeconds),
            ("unknown86", fromHexString("a186000000")!, toSeconds),
            ("unknown63", fromHexString("a163000000")!, toSeconds),
            ("unknown64", fromHexString("a164000000")!, toSeconds),
            ("reset", fromHexString("e200000000")!, toSeconds),
            //            ("unknown5", [0xA1, 0x8A, 0x00, 0x00, 0x00], toUInt16), // Always 0?
        ]
        
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
        let finishedCallback: (CBPeripheral) -> Void
        let peripheral: CBPeripheral
        var characteristic1: CBCharacteristic!
        var characteristic2: CBCharacteristic!
        
        init(peripheral: CBPeripheral, callback: @escaping (CBPeripheral) -> Void) {
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
            //           peripheral.writeValue(Data(startCommand), for: characteristic!, type: CBCharacteristicWriteType.withResponse)
            if currentCommandIndex < queryCommands.count {
                let command = queryCommands[currentCommandIndex]
                peripheral.writeValue(Data(command.command), for: characteristic1!, type: CBCharacteristicWriteType.withResponse)
            } else {
                let json = try! JSONSerialization.data(withJSONObject: responseDict)
                print("complete dictionary:")
                print("\(String(decoding: json, as: UTF8.self))")
                finishedCallback(peripheral)
            }
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
                        characteristic1 = ch
                        peripheral.setNotifyValue(true, for: ch)
                    } else if ch.uuid.uuidString == "FFF2" {
                        characteristic2 = ch
                        peripheral.writeValue(fromHexString("0200000000")!, for: ch, type: CBCharacteristicWriteType.withResponse)
                    }
                }
            }
        }
        
        func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
            guard let value = characteristic.value else {
                print("unable to fetch data")
                return
            }
            if value == fromHexString("02aa11180000")! {
                peripheral.writeValue(fromHexString("c000000000")!, for: characteristic2, type: CBCharacteristicWriteType.withResponse)
            } else if value == fromHexString("c0ff00000000") {
                startCommands()
            } else {
                let command = queryCommands[currentCommandIndex]
                let key = command.description
                let response = command.processor(value)
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
    
    func sessionFinished(peripheral: CBPeripheral) {
        centralManager.cancelPeripheralConnection(peripheral)
        centralManager.stopScan()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 15, execute: {
            self.centralManager.scanForPeripherals(withServices: nil)
        })
        
        session = nil
    }
}
