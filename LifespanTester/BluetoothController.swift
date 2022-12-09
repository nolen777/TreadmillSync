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
    let virtualPeripheral = PhoneSyncPeripheral()
    
    var session: LifeSpanSession?
    var listening: Bool = false {
        didSet {
            guard listening != oldValue else {
                return
            }
            if listening {
                if centralManager.state == .poweredOn && !centralManager.isScanning {
                    print("Starting scan")
                    centralManager.scanForPeripherals(withServices: nil)
                }
            } else {
                if centralManager.isScanning {
                    print("Stopping scan")
                    centralManager.stopScan()
                }
            }
        }
    }
    
    func setUp() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: virtualPeripheral, queue: nil)
    }
    
    class LifeSpanSession: NSObject, CBPeripheralDelegate {
        var currentCommandIndex: Int = 0
        var responseDict = [String : Any]()
        let finishedCallback: (CBPeripheral, [String: Any]) -> Void
        let abortedCallback: (CBPeripheral) -> Void
        let peripheral: CBPeripheral
        var characteristic1: CBCharacteristic!
        var characteristic2: CBCharacteristic!
        
        init(peripheral: CBPeripheral, finishedCallback: @escaping (CBPeripheral, [String: Any]) -> Void, abortedCallback: @escaping (CBPeripheral) -> Void) {
            self.peripheral = peripheral
            self.finishedCallback = finishedCallback
            self.abortedCallback = abortedCallback
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
                peripheral.writeValue(LifeSpanCommands.resetCommand.commandData, for: characteristic1!, type: CBCharacteristicWriteType.withResponse)
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
            } else if value == Data(hexString: "e2aa00000000") {
                // response to the reset command
                finishedCallback(peripheral, responseDict)
            } else {
                let command = LifeSpanCommands.queryCommands[currentCommandIndex]
                let key = command.description
                let response = command.responseProcessor(value)
                
                // HACK: the reset doesn't happen correctly if the treadmill is running, so we don't have
                // a reliable way to avoid deduplicating data. So if we see the speed is >0, abort, which won't sync
                // to the phone. Alternatively, we could maintain previous state and subtract steps/distance we
                // already know about.
                if key == "speedInMph" {
                    if let speedInMph = response as? Decimal, speedInMph > 0 {
                        print("treadmill is running, not syncing")
                        abortedCallback(peripheral)
                        return
                    }
                }
                
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
            if listening {
                centralManager.scanForPeripherals(withServices: nil)
            }
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
            session = LifeSpanSession(peripheral: peripheral, finishedCallback: sessionFinished, abortedCallback: sessionAborted)
            centralManager.connect(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected!")
        session?.run()
    }
    
    func sessionAborted(peripheral: CBPeripheral) {
        centralManager.cancelPeripheralConnection(peripheral)
        centralManager.stopScan()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 15, execute: {
            if self.listening {
                self.centralManager.scanForPeripherals(withServices: nil)
            }
        })
        
        session = nil
    }
    
    func sessionFinished(peripheral: CBPeripheral, dict: [String: Any]) {
        virtualPeripheral.send(newValue: dict)
        centralManager.cancelPeripheralConnection(peripheral)
        centralManager.stopScan()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 15, execute: {
            if self.listening {
                self.centralManager.scanForPeripherals(withServices: nil)
            }
        })
        
        session = nil
    }
}
