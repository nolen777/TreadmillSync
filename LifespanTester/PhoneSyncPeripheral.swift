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
    
    var broadcasting: Bool = false
    
    let valuesToSendQueue = DispatchQueue(label: "phone_sync_values_queue")
    
    private var valuesToSend = [[String : Any]]()
    
    func send(newValue: [String: Any]) {
        valuesToSendQueue.async {
            self.valuesToSend.append(newValue)
            
            DispatchQueue.main.async {
                self.startAdvertising()
            }
        }
    }
    
    private func startAdvertising() {
        if let peripheral = peripheralManager, peripheral.state == .poweredOn, broadcasting, !peripheral.isAdvertising {
            print("Starting to advertise")
            
            peripheral.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [transferService.uuid]])
        }
    }
    
    private func stopAdvertising() {
        if let peripheral = peripheralManager, peripheral.isAdvertising {
            print("Stopping advertisement")
            peripheralManager.stopAdvertising()
        }
    }
    
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
        
        valuesToSendQueue.async {
            while let nextValue = self.valuesToSend.first {
                let jsonData = try! JSONSerialization.data(withJSONObject: nextValue)
                
                if self.peripheralManager.updateValue(jsonData, for: transferCharacteristic, onSubscribedCentrals: nil) {
                    print("successfully sent data")
                    self.valuesToSend.removeFirst()
                }
            }
            // Send EOM when we have no values remaining
            self.peripheralManager.updateValue("EOM".data(using: .utf8)!, for: transferCharacteristic, onSubscribedCentrals: nil)
            
            self.stopAdvertising()
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
        if !valuesToSend.isEmpty {
            startAdvertising()
        }
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
