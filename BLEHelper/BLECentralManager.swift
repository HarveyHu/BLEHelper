//
//  BLECentralManager.swift
//  BLEHelper
//
//  Created by HarveyHu on 2/26/16.
//  Copyright © 2016 HarveyHu. All rights reserved.
//

import Foundation
import CoreBluetooth


class BLECentralManager: NSObject {
    //MARK: - Blocks Declaration
    typealias DiscoverPeripheralCompletion = (peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) -> (Void)
    typealias ConnectPeripheralCompletion = (peripheral: CBPeripheral, error: NSError?) -> (Void)
    typealias DisconnectPeripheralCompletion = (peripheral: CBPeripheral, error: NSError?) -> (Void)
    typealias DiscoverServicesHandler = (peripheral: CBPeripheral, error: NSError?) -> (Void)
    typealias DiscoverCharacteristicsForServiceHandler = (peripheral: CBPeripheral, service: CBService, error: NSError?) -> (Void)
    typealias FetchCharacteristicCompletion = (characteristic: CBCharacteristic) -> (Void)
    typealias ReceiveDataHandler = (data: NSData?, peripheral: CBPeripheral, characteristic: CBCharacteristic) -> (Void)
    typealias ReadResponse = (success: Bool) -> (Void)
    typealias SetNotifyResponse = (success: Bool) -> (Void)
    typealias WriteResponse = (success: Bool) -> (Void)
    typealias ReadRSSI = (peripheral: CBPeripheral, RSSI: NSNumber, error: NSError?) -> (Void)

    var didDiscoverPeripheralCompletion: DiscoverPeripheralCompletion?
    var didConnectPeripheralCompletion: ConnectPeripheralCompletion?
    var didDisconnectPeripheralCompletion: DisconnectPeripheralCompletion?
    var didDiscoverServicesHandler: DiscoverServicesHandler?
    var didDiscoverCharacteristicsForServiceHandler: DiscoverCharacteristicsForServiceHandler?
    var didFetchCharacteristicCompletion: FetchCharacteristicCompletion?
    var didReceiveDataHandler: ReceiveDataHandler?
    var didReadResponse: ReadResponse?
    var didSetNotifyResponse: SetNotifyResponse?
    var didWriteResponse: WriteResponse?
    var didReadRSSI: ReadRSSI?
    
    //MARK: - Basic Settings
    private var centralManager: CBCentralManager?
    // [deviceUUID : [characteristicUUID: CBCharacteristic]]
    private var deviceCharacteristicMap = [String : [String : CBCharacteristic]]()
    
    required init(queue: dispatch_queue_t) {
        super.init()
        centralManager = CBCentralManager.init(delegate: self, queue: queue)
    }
    
    deinit {
        centralManager = nil
        releaseBlocks()
    }
    
    //MARK: - Private Functions
    private func closeAllNotifications(peripheral: CBPeripheral) {
        if let services = peripheral.services {
            for service in services {
                if let characteristics = service.characteristics {
                    for characteristic in characteristics {
                        if characteristic.isNotifying {
                            peripheral.setNotifyValue(false, forCharacteristic: characteristic)
                        }
                    }
                }
            }
        }
    }
    
    private func releaseBlocks() {
        didDiscoverPeripheralCompletion = nil
        didConnectPeripheralCompletion = nil
        didDisconnectPeripheralCompletion = nil
        didDiscoverServicesHandler = nil
        didDiscoverCharacteristicsForServiceHandler = nil
        didFetchCharacteristicCompletion = nil
        didReceiveDataHandler = nil
        didReadResponse = nil
        didSetNotifyResponse = nil
        didWriteResponse = nil
        didReadRSSI = nil
    }
    
    //MARK: - BLE Discovering
    /*
    *  @Discoverying
    */
    func scanWithServiceUUID(serviceUUID: String?,  discoverPeripheralCompletion: DiscoverPeripheralCompletion) {
        prettyLog()
        self.didDiscoverPeripheralCompletion = discoverPeripheralCompletion
        
        //callack on didDiscoverPeripheral: delegate
        if let uuidString = serviceUUID {
            let uuids = [CBUUID.init(string: uuidString)]
            centralManager?.scanForPeripheralsWithServices(uuids, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        } else {
            centralManager?.scanForPeripheralsWithServices(nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        }
    }
    
    func stopScan() {
        centralManager?.stopScan()
    }
    
    //MARK: - BLE Connecting
    /*
    *  @Connecting
    */
    func connect(peripheral: CBPeripheral, completion: ConnectPeripheralCompletion?) {
        self.didConnectPeripheralCompletion = completion
        centralManager?.connectPeripheral(peripheral, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey : NSNumber(bool: true)])
    }
    
    func retrievePeripheralByDeviceUUID(deviceUUIDs: [NSUUID], completion: ConnectPeripheralCompletion?) {
        self.didConnectPeripheralCompletion = completion
        
        if let peripherals = centralManager?.retrievePeripheralsWithIdentifiers(deviceUUIDs) {
            for peripheral in peripherals
            {
                prettyLog("connect with deviceUUID:\(peripheral.identifier)")
                centralManager?.connectPeripheral(peripheral, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey : NSNumber(bool: true)])
            }
        }
    }
    
    func disconnect(peripheral: CBPeripheral) {
        closeAllNotifications(peripheral)
        self.deviceCharacteristicMap.removeValueForKey(peripheral.identifier.UUIDString)
        centralManager?.cancelPeripheralConnection(peripheral)
    }
    
    
    //MARK - BLE Exploring
    /*!
    *  @Exploring
    */
    func fetchCharacteristic(peripheral:CBPeripheral, serviceUUID: String, characteristicUUID: String, completion: FetchCharacteristicCompletion) {
        prettyLog("deviceUUID: \(peripheral.identifier.UUIDString)")
        
        // if it's found before, use it.
        if let characteristicMap = deviceCharacteristicMap[peripheral.identifier.UUIDString], characteristic = characteristicMap[characteristicUUID] {
            completion(characteristic: characteristic)
            return
        }
        
        //set callback
        self.didFetchCharacteristicCompletion = completion
        self.didDiscoverServicesHandler = {(peripheral: CBPeripheral, error: NSError?) -> (Void) in
            if error != nil {
                prettyLog("error:" + error!.description)
                return
            }
            prettyLog()
            
            if let services = peripheral.services {
                for service in services {
                    prettyLog("[debug] serviceUUID:\(service.UUID.UUIDString) input UUID:\(serviceUUID)")
                    if service.UUID.UUIDString == serviceUUID {
                        peripheral.discoverCharacteristics([CBUUID.init(string: characteristicUUID)], forService: service)
                    } else {
                        break
                    }
                }
            }
        }
        self.didDiscoverCharacteristicsForServiceHandler = {[weak self] (peripheral: CBPeripheral, service: CBService, error: NSError?) in
            if error != nil {
                prettyLog("error:" + error!.description)
                return
            }
            prettyLog()
            
            if let characteristics = service.characteristics {
                for characteristic in characteristics {
                    self?.deviceCharacteristicMap[peripheral.identifier.UUIDString] = [characteristic.UUID.UUIDString: characteristic]
                    if characteristic.UUID.UUIDString == characteristicUUID {
                        self?.didFetchCharacteristicCompletion?(characteristic: characteristic)
                    }
                }
            }
        }
        
        //start from getting services
        peripheral.discoverServices([CBUUID.init(string: serviceUUID)])
    }
    
    //MARK - BLE Interacting
    //reading
    func readValueFromCharacteristic(peripheral:CBPeripheral, characteristic: CBCharacteristic, completion:ReadResponse?) {
        self.didReadResponse = completion
        peripheral.readValueForCharacteristic(characteristic)
    }
    
    //writing
    func writeValueWithData(peripheral:CBPeripheral, characteristic: CBCharacteristic, data: NSData, withResponse: Bool, response: WriteResponse?) {
        self.didWriteResponse = response
        peripheral.writeValue(data, forCharacteristic: characteristic, type: withResponse ? .WithResponse : .WithoutResponse)
    }
    
    //notify
    func setNotificationState(peripheral:CBPeripheral, turnOn onOrOff: Bool, characteristic: CBCharacteristic, response: SetNotifyResponse?) {
        let p = characteristic.isNotifying
        let q = onOrOff
        if (p || q) && !(p && q) {
            self.didSetNotifyResponse = response
            peripheral.setNotifyValue(onOrOff, forCharacteristic: characteristic)
        }
    }
    
    //readRSSI
    func readRSSI(peripheral: CBPeripheral, completion: ReadRSSI) {
        self.didReadRSSI = completion
        peripheral.readRSSI()
    }
}

//MARK: - Extension for CBCentralManagerDelegate
extension BLECentralManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(central: CBCentralManager) {
        prettyLog()
        switch central.state {
        case .Unknown:
            print("Central manager state: Unknown")
            break
            
        case .Resetting:
            print("Central manager state: Resseting")
            break
            
        case .Unsupported:
            print("Central manager state: Unsopported")
            break
            
        case .Unauthorized:
            print("Central manager state: Unauthorized")
            break
            
        case .PoweredOff:
            print("Central manager state: Powered off")
            break
            
        case .PoweredOn:
            print("[Central manager state: Powered on")
            break
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        prettyLog("peripheral:\(peripheral)\nadvertisementData\(advertisementData)\n\(RSSI)")
        didDiscoverPeripheralCompletion?(peripheral: peripheral, advertisementData: advertisementData, RSSI: RSSI)
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        prettyLog()
        peripheral.delegate = self
        didConnectPeripheralCompletion?(peripheral: peripheral, error: nil)
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        didConnectPeripheralCompletion?(peripheral: peripheral, error: error)
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        didDisconnectPeripheralCompletion?(peripheral: peripheral, error: error)
    }
}

//MARK: - Extension for CBPeripheralDelegate
extension BLECentralManager: CBPeripheralDelegate {
    
    func peripheral(peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: NSError?) {
        didReadRSSI?(peripheral: peripheral, RSSI: RSSI, error: error)
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        didDiscoverServicesHandler?(peripheral: peripheral, error: error)
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        didDiscoverCharacteristicsForServiceHandler?(peripheral: peripheral, service: service, error: error)
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if error != nil {
            prettyLog("error:" + error!.description)
            self.didReadResponse?(success: false)
            return
        }
        prettyLog()
        self.didReadResponse?(success: true)
        self.didReadResponse = nil
        self.didReceiveDataHandler?(data: characteristic.value, peripheral: peripheral, characteristic: characteristic)
    }
    
    func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if error != nil {
            prettyLog("error:" + error!.description)
            self.didWriteResponse?(success: false)
            return
        }
        prettyLog()
        self.didWriteResponse?(success: true)
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if error != nil {
            prettyLog("error:" + error!.description)
            self.didSetNotifyResponse?(success: false)
            return
        }
        prettyLog()
        self.didSetNotifyResponse?(success: true)
    }
}