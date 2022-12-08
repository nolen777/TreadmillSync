//
//  PhoneSyncPeripheral.swift
//  LifespanTester
//
//  Created by Dan Crosby on 12/5/22.
//

import Foundation
import CoreBluetooth

class PhoneSyncPeripheral: NSObject, CBPeripheralManagerDelegate {
    var transferService: CBMutableService!
    var transferCharacteristic: CBMutableCharacteristic!
    var peripheralManager: CBPeripheralManager!
    
    var connectedCentral: CBCentral?
    
    var values = [[String : Any]]()
    
    private func setUpPeripheral() {
        let transferCharacteristic = CBMutableCharacteristic(type: PhoneSyncService.characteristicUUID,
                                                             properties: [.notify, .writeWithoutResponse],
                                                             value: nil,
                                                             permissions: [.readable, .writeable])
        
        let transferService = CBMutableService(type: PhoneSyncService.serviceUUID, primary: true)
        transferService.characteristics = [transferCharacteristic]
        peripheralManager.add(transferService)
        
        self.transferService = transferService
        self.transferCharacteristic = transferCharacteristic
    }
    
    private func stopPeripheral() {
        peripheralManager.removeAllServices()
    }
    
    private func sendData() {
        guard let transferCharacteristic = transferCharacteristic else {
            return
        }
        
        if !values.isEmpty {
//        while !values.isEmpty {
            let nextValue = values.first!
            let jsonData = try! JSONSerialization.data(withJSONObject: nextValue)
            peripheralManager.updateValue(jsonData, for: transferCharacteristic, onSubscribedCentrals: nil)
            
            // TODO: Verify that the data was actually sent!
//            values.removeFirst()
        }
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
        
        connectedCentral = central
        
        sendData()
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didOpen channel: CBL2CAPChannel?, error: Error?) {
        print("opened channel")
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        print("ready to update")
        sendData()
    }
}
