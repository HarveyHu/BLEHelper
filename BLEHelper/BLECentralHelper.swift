//
//  BLECentralHelper.swift
//  BLEHelper
//
//  Created by HarveyHu on 2/27/16.
//  Copyright © 2016 HarveyHu. All rights reserved.
//

import Foundation
import CoreBluetooth

public protocol BLECentralHelperDelegate {
    func bleDidDisconnectFromPeripheral(peripheral: CBPeripheral)
    func bleCentralDidReceiveData(data: NSData?, peripheral: CBPeripheral,characteristic: CBCharacteristic)
}

public class BLECentralHelper {
    public var delegate: BLECentralHelperDelegate?
    let centralManager: BLECentralManager
    var peripheralScanList = [CBPeripheral] ()
    public internal(set) var connectedPeripherals = [String: CBPeripheral] ()
    var timer: NSTimer?
    var scanCompletion: ((peripheralList: [CBPeripheral])->(Void))?
    
    public init() {
        // Set centralManager
        let bleCentralQueue: dispatch_queue_t = dispatch_queue_create("forBLECentralManagerOnly", DISPATCH_QUEUE_SERIAL)
        centralManager = BLECentralManager(queue: bleCentralQueue)
        centralManager.didReceiveDataHandler = {[weak self] (data: NSData?, peripheral: CBPeripheral ,characteristic: CBCharacteristic) -> (Void) in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self?.delegate?.bleCentralDidReceiveData(data ,peripheral: peripheral, characteristic: characteristic)
            })
        }
        centralManager.didDisconnectPeripheralCompletion = {[weak self] (peripheral, error) -> (Void) in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self?.delegate?.bleDidDisconnectFromPeripheral(peripheral)
            })
        }
    }
    
    deinit {
        self.delegate = nil
        self.timer?.invalidate()
        self.timer = nil
        self.scanCompletion = nil
    }
    
    dynamic func scanTimeout() {
        prettyLog("Scan Timeout")
        self.centralManager.stopScan()
        scanCompletion?(peripheralList: self.peripheralScanList)
    }
    
    //MARK - BLE Scan
    public func scan(seconds: Double, serviceUUID: String?, handler:((devices: [CBPeripheral]) -> (Void))?) {
        prettyLog()
        self.timer?.invalidate()
        centralManager.stopScan()
        
        scanCompletion = handler
        
        self.timer = NSTimer.scheduledTimerWithTimeInterval(seconds, target: self, selector: #selector(BLECentralHelper.scanTimeout), userInfo: nil, repeats: false)
        
        centralManager.scanWithServiceUUID(serviceUUID) {[weak self] (peripheral, advertisementData, RSSI) -> (Void) in
            if self?.peripheralScanList.filter({$0.identifier.UUIDString == peripheral.identifier.UUIDString}).count == 0 || self?.peripheralScanList.count == 0 {
                self?.peripheralScanList.append(peripheral)
            }
        }
    }
    
    //MARK - BLE Connect
    public func connect(peripheral: CBPeripheral, completion: ((peripheral: CBPeripheral, error: NSError?) -> (Void))?) {
        prettyLog("connect with peripheral: \(peripheral.identifier.UUIDString)")
        self.timer?.invalidate()
        centralManager.stopScan()
        
        centralManager.connect(peripheral, completion: {[weak self] (peripheral: CBPeripheral, error: NSError?) in
            
            if let strongSelf = self {
                strongSelf.connectedPeripherals.updateValue(peripheral, forKey: peripheral.identifier.UUIDString)
            }
            completion?(peripheral: peripheral, error: error)
        })
    }
    
    public func retrieve(deviceUUIDs deviceUUIDStrings: [String], completion: ((peripheral: CBPeripheral, error: NSError?) -> (Void))?) {
        prettyLog()
        self.timer?.invalidate()
        centralManager.stopScan()
        
        let deviceUUIDs = deviceUUIDStrings.map { (uuidString) -> NSUUID in
            return NSUUID.init(UUIDString: uuidString)!
        }
        
        //must scan to get peripheral instance
        self.scan(1.0, serviceUUID: nil) {[weak self] (devices) -> (Void) in
            self?.centralManager.retrievePeripheralByDeviceUUID(deviceUUIDs, completion: {[weak self] (peripheral: CBPeripheral, error: NSError?) in
                if let strongSelf = self {
                    strongSelf.connectedPeripherals.updateValue(peripheral, forKey: peripheral.identifier.UUIDString)
                }
                completion?(peripheral: peripheral, error: error)
            })
        }
    }
    
    public func disconnect(deviceUUID: String?) {
        prettyLog("deviceUUID: \(deviceUUID)")
        if let uuid = deviceUUID {
            if let p = self.connectedPeripherals[uuid] {
                centralManager.disconnect(p)
                self.connectedPeripherals.removeValueForKey(uuid)
            }
        } else {
            for (_, p) in self.connectedPeripherals {
                centralManager.disconnect(p)
            }
            self.connectedPeripherals.removeAll()
        }
        self.peripheralScanList.removeAll()
    }
    
    public func isConnected(deviceUUID: String) -> Bool {
        if self.connectedPeripherals[deviceUUID]?.state == CBPeripheralState.Connected {
            return true
        }
        return false
    }
    
    //MARK: - BLE Operation
    //read
    public func readValue(deviceUUID: String, serviceUUID: String, characteristicUUID: String, response: (success: Bool)-> (Void)) {
        guard let peripheral = self.connectedPeripherals[deviceUUID] else {
            prettyLog("error: peripheral = nil")
            return
        }
        prettyLog("deviceUUID: \(deviceUUID)")
        
        centralManager.fetchCharacteristic(peripheral, serviceUUID: serviceUUID, characteristicUUID: characteristicUUID) {[weak self] (characteristic) -> (Void) in
            self?.centralManager.readValueFromCharacteristic(peripheral, characteristic: characteristic, completion: response)
        }
    }
    
    //notify
    public func enableNotification(enable: Bool, deviceUUID: String, serviceUUID: String, characteristicUUID: String, response:(success: Bool) -> (Void)) {
        guard let peripheral = self.connectedPeripherals[deviceUUID] else {
            prettyLog("error: peripheral = nil")
            return
        }
        prettyLog("deviceUUID: \(deviceUUID)")
        
        centralManager.fetchCharacteristic(peripheral, serviceUUID: serviceUUID, characteristicUUID: characteristicUUID) {[weak self] (characteristic) -> (Void) in
            self?.centralManager.setNotificationState(peripheral, turnOn: enable, characteristic: characteristic, response: response)
        }
    }
    
    //write
    public func writeValue(data: NSData, deviceUUID: String, serviceUUID: String, characteristicUUID: String, withResponse: Bool, response:(success: Bool) -> (Void)) {
        guard let peripheral = self.connectedPeripherals[deviceUUID] else {
            prettyLog("error: peripheral = nil")
            return
        }
        prettyLog("deviceUUID: \(deviceUUID)")
        
        centralManager.fetchCharacteristic(peripheral, serviceUUID: serviceUUID, characteristicUUID: characteristicUUID) {[weak self] (characteristic) -> (Void) in
            self?.centralManager.writeValueWithData(peripheral, characteristic: characteristic, data: data, withResponse: withResponse, response: response)
        }
    }
}


