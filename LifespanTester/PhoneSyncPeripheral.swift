//
//  PhoneSyncPeripheral.swift
//  LifespanTester
//
//  Created by Dan Crosby on 12/5/22.
//

import Foundation
import CoreBluetooth

class PhoneSyncPeripheral: NSObject, CBPeripheralManagerDelegate {
    let serviceUUID = CBUUID(string: "b0779ed8-f74a-44f5-a9bf-eeb0c76a502e")
    let characteristicUUID = CBUUID(string: "1bc63fa8-b79d-461c-8cf3-839fc5fba809")
    
    var transferService: CBMutableService!
    var transferCharacteristic: CBMutableCharacteristic!
    var peripheralManager: CBPeripheralManager!
    
    var value: Data? {
        get {
            return transferCharacteristic.value
        }
        set(newValue) {
            transferCharacteristic.value = newValue
            peripheralManager.updateValue(newValue ?? Data(), for: transferCharacteristic, onSubscribedCentrals: nil)
        }
    }
    
    private func setUpPeripheral() {
        let transferCharacteristic = CBMutableCharacteristic(type: characteristicUUID,
                                                             properties: [.notify, .writeWithoutResponse],
                                                             value: nil,
                                                             permissions: [.readable, .writeable])
        
        let transferService = CBMutableService(type: serviceUUID, primary: true)
        transferService.characteristics = [transferCharacteristic]
        peripheralManager.add(transferService)
        
        self.transferService = transferService
        self.transferCharacteristic = transferCharacteristic
    }
    
    private func stopPeripheral() {
        peripheralManager.removeAllServices()
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        self.peripheralManager = peripheral
        
        switch (peripheral.state) {
            
        case .unknown:
            print("updated to Unknown state")
            
        case .resetting:
            print("updated to Resetting state")
            
        case .unsupported:
            print("updated to Unsupported state")
            
        case .unauthorized:
            print("updated to Unauthorized state")
            
        case .poweredOff:
            print("updated to PoweredOff state")
            
        case .poweredOn:
            print("updated to PoweredOn state")
            setUpPeripheral()
            
        @unknown default:
            break
            
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        print("Starting to advertise with error \(String(describing: error))")
        peripheral.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [service.uuid]])
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        print("Started advertising with error \(String(describing: error))")
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
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didOpen channel: CBL2CAPChannel?, error: Error?) {
        print("opened channel")
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        print("ready to update")
    }
}
