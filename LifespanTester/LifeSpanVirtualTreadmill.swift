//
//  LifeSpanVirtualTreadmill.swift
//  LifespanTester
//
//  Created by Dan Crosby on 12/5/22.
//

import Foundation
import CoreBluetooth

// Simulates the operation of a LifeSpan treadmill responding to the app

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
