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
    
    init?(fromHexString str: String) {
        self.init(capacity: str.count / 2)
        var currentByte: UInt8?
        for c in str {
            guard let nibble = c.hexDigitValue else {
                print("Uh oh!")
                return nil
            }
            
            if let existingByte = currentByte {
                self.append(existingByte | UInt8(nibble))
                currentByte = nil
            } else {
                currentByte = UInt8(nibble) << 4
            }
        }
        guard currentByte == nil else {
            print("Bad nibble!")
            return nil
        }
    }
}

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
    
    class LifeSpanCommand {
        let description: String
        let commandData: Data
        let responseProcessor: (Data) -> Any
        
        init(description: String, commandData: Data, responseProcessor: @escaping (Data) -> Any) {
            self.description = description
            self.commandData = commandData
            self.responseProcessor = responseProcessor
        }
        
        convenience init?(description: String, commandHexString: String, responseProcessor: @escaping (Data) -> Any) {
            guard let commandData = fromHexString(commandHexString) else {
                return nil
            }
            self.init(description: description, commandData: commandData, responseProcessor: responseProcessor)
        }
    }
    
    class LifeSpanSession: NSObject, CBPeripheralDelegate {
        enum LifeSpanSessionError: Error {
            case invalidSpeed
        }
        
        let queryCommands: [LifeSpanCommand] = [
            LifeSpanCommand(description: "unknown91", commandHexString: "a191000000", responseProcessor: toUInt16)!,
            LifeSpanCommand(description: "unknown81", commandHexString: "a181000000", responseProcessor: toUInt16)!,
            LifeSpanCommand(description: "unknown61", commandHexString: "a161000000", responseProcessor: toUInt16)!,
            LifeSpanCommand(description: "unknown62", commandHexString: "a162000000", responseProcessor: toUInt16)!,
            LifeSpanCommand(description: "speedInMph", commandHexString: "a182000000", responseProcessor: toDecimal)!,
            LifeSpanCommand(description: "distanceInMiles", commandHexString: "a185000000", responseProcessor: toDecimal)!,
            LifeSpanCommand(description: "calories", commandHexString: "a187000000", responseProcessor: toUInt16)!,
            LifeSpanCommand(description: "steps", commandHexString: "a188000000", responseProcessor: toUInt16)!,
            LifeSpanCommand(description: "timeInSeconds", commandHexString: "a189000000", responseProcessor: toSeconds)!,
            LifeSpanCommand(description: "unknown8B", commandHexString: "a18b000000", responseProcessor: toSeconds)!,
            LifeSpanCommand(description: "unknown89", commandHexString: "a189000000", responseProcessor: toSeconds)!,
            LifeSpanCommand(description: "unknown86", commandHexString: "a186000000", responseProcessor: toSeconds)!,
            LifeSpanCommand(description: "unknown63", commandHexString: "a163000000", responseProcessor: toSeconds)!,
            LifeSpanCommand(description: "unknown64", commandHexString: "a164000000", responseProcessor: toSeconds)!,
        ]
        
        let resetCommand = LifeSpanCommand(description: "reset", commandHexString: "e200000000", responseProcessor: toSeconds)!
        
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
        let finishedCallback: (CBPeripheral, Data) -> Void
        let peripheral: CBPeripheral
        var characteristic1: CBCharacteristic!
        var characteristic2: CBCharacteristic!
        
        init(peripheral: CBPeripheral, callback: @escaping (CBPeripheral, Data) -> Void) {
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
            if currentCommandIndex < queryCommands.count {
                let command = queryCommands[currentCommandIndex]
                peripheral.writeValue(command.commandData, for: characteristic1!, type: CBCharacteristicWriteType.withResponse)
            } else {
                let json = try! JSONSerialization.data(withJSONObject: responseDict)
                print("complete dictionary:")
                print("\(String(decoding: json, as: UTF8.self))")
                finishedCallback(peripheral, json)
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
    
    func sessionFinished(peripheral: CBPeripheral, jsonData: Data) {
        virtualPeripheral.value = jsonData
        centralManager.cancelPeripheralConnection(peripheral)
        centralManager.stopScan()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 15, execute: {
            self.centralManager.scanForPeripherals(withServices: nil)
        })
        
        session = nil
    }
}
