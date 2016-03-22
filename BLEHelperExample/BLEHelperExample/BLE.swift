//
//  BLE.swift
//  BLEHelperExample
//
//  Created by HarveyHu on 3/21/16.
//  Copyright © 2016 HarveyHu. All rights reserved.
//


import Foundation
import BLEHelper
import CoreBluetooth


protocol BLEDelegate {
    func didReceivedData(dataString: String)
}

func prettyLog(message: String = "", file:String = #file, function:String = #function, line:Int = #line) {
    
    print("\((file as NSString).lastPathComponent)(\(line)) \(function) \(message)")
}

class BLE: BLECentralHelperDelegate {
    let bleHelper = BLECentralHelper()
    static let sharedInstance = BLE()
    var targetDeviceUUID: String?
    
    var delegate: BLEDelegate?
    var judgeInitSet = Set<String>()
    var bufferString = ""
    
    private init () {
        bleHelper.delegate = self
    }
    
    //MARK: - BLECentralHelperDelegate
    func bleDidDisconnectFromPeripheral(peripheral: CBPeripheral) {
        prettyLog("didDisconnectFromPeripheral:\(peripheral.identifier.UUIDString)")
    }
    
    func bleCentralDidReceiveData(data: NSData?, peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        prettyLog("ReceiveData:\(String(data: data!, encoding: NSUTF8StringEncoding))")
        guard let string = String(data: data!, encoding: NSUTF8StringEncoding) else {
            return
        }
        
        self.delegate?.didReceivedData(string)
    }
    
    //MARK: - Operation
    func scan(completion: (peripheralList: [CBPeripheral]) -> (Void)) {
        bleHelper.scan(1.0, serviceUUID: nil, handler: completion)
    }
    
    func connect(deviceUUID: String, completion: ((success: Bool) -> (Void))?) {
        self.targetDeviceUUID = deviceUUID
        self.bleHelper.retrieve(deviceUUIDs: [self.targetDeviceUUID!], completion: {(peripheral, error) -> (Void) in
            if error != nil {
                prettyLog("error: \(error?.description)")
                completion?(success: false)
                return
            }
            /*
            case Disconnected = 0
            case Connecting
            case Connected
            case Disconnecting
            */
            prettyLog("pheripheral.state: \(peripheral.state)")
            completion?(success: true)
            })
        return
    }
    
    func disconnect(uuid: String?) {
        bleHelper.disconnect(uuid)
    }
    
    func read(sUUID: String, cUUID: String) {
        if !bleHelper.isConnected(targetDeviceUUID!) {
            prettyLog("device is not conncted.")
            return
        }
        bleHelper.readValue(targetDeviceUUID!, serviceUUID: sUUID, characteristicUUID: cUUID) { (success) -> (Void) in
            prettyLog("is read success: \(success)")
        }
    }
    
    func enableNotification(sUUID: String, cUUID: String, completion: ((success: Bool) -> (Void))?) {
        if !bleHelper.isConnected(targetDeviceUUID!) {
            prettyLog("device is not conncted.")
            return
        }
        prettyLog("targetDeviceUUID: \(targetDeviceUUID!)")
        bleHelper.enableNotification(true, deviceUUID: targetDeviceUUID!, serviceUUID: sUUID, characteristicUUID: cUUID) { (success) -> (Void) in
            prettyLog("set notify success: \(success)")
            completion?(success: success)
        }
    }
    
    func write(command: String, sUUID: String, cUUID: String) {
        if !bleHelper.isConnected(targetDeviceUUID!) {
            prettyLog("device is not conncted.")
            return
        }
        
        if let data = command.dataUsingEncoding(NSUTF8StringEncoding) {
            bleHelper.writeValue(data, deviceUUID: targetDeviceUUID!, serviceUUID: sUUID, characteristicUUID: cUUID) { (success) -> (Void) in
                prettyLog("is write success: \(success)")
            }
        }
    }
}