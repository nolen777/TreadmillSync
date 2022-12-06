//
//  PhoneSyncPeripheral.swift
//  LifespanTester
//
//  Created by Dan Crosby on 12/5/22.
//

import Foundation
import CoreBluetooth

class PhoneSyncPeripheral: NSObject, CBPeripheralManagerDelegate {
    let serviceUuidString = "b0779ed8-f74a-44f5-a9bf-eeb0c76a502e"
    let characteristicUuidString = "1bc63fa8-b79d-461c-8cf3-839fc5fba809"
    
    var mainCharacteristic: CBMutableCharacteristic!
    var peripheral: CBPeripheralManager!
    
    var value: Data? {
        get {
            return mainCharacteristic.value
        }
        set(newValue) {
            mainCharacteristic.value = newValue
            peripheral.updateValue(newValue ?? Data(), for: mainCharacteristic, onSubscribedCentrals: nil)
        }
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("HERE")
        
        let mainService = CBMutableService(type: CBUUID(string: serviceUuidString), primary: true)
        mainCharacteristic = CBMutableCharacteristic(type:CBUUID(string:characteristicUuidString), properties:[.notify, .write, .writeWithoutResponse], value:nil, permissions:[.readable])
        mainService.characteristics = [mainCharacteristic]
        
        peripheral.add(mainService)
        peripheral.startAdvertising(
            [CBAdvertisementDataLocalNameKey : "PSP",
           CBAdvertisementDataServiceUUIDsKey: [serviceUuidString],
  CBAdvertisementDataSolicitedServiceUUIDsKey: [serviceUuidString]])
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            print("did receive write for characteristic \(request.characteristic.uuid.uuidString)")
            print("value is \(String(describing: request.value?.hexEncodedString()))")
        }
        
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("did receive read")
        peripheral.respond(to: request, withResult: .success)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("did subscribe to \(characteristic.uuid.uuidString)")
    }
}
