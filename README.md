# BLEHelper

BLEHelper is an elegant way to deal with your Bluetooth Low Energy device. It supports your iDevice to manipulate multiple BLE devices simultaneously.

[![Travis CI](https://travis-ci.org/HarveyHu/BLEHelper.svg?branch=master)](https://travis-ci.org/HarveyHu/BLEHelper)[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

## Installation

###CocoaPods

Specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

pod 'BLEHelper', '~> 1.0'
```

Then, run the following command:

```bash
$ pod install
```
###Carthage

Just add the following to your project Cartfile:

```ruby
github "HarveyHu/BLEHelper" ~> 1.0.0
```
Then, run the following command:

```bash
$ carthage update --platform iOS
```

## Usage
Use by including the following import:

```swift
import BLEHelper
```
And init it as a property of your class:

```swift
let bleHelper = BLECentralHelper()
```

#### Scan

To scan devices nearby, and the completion is on the end:

```swift
bleHelper.scan(1.0, serviceUUID: nil) { (devices) -> (Void) in
            //TODO: show your devices
        }
```
#### Connect

To connect with a device by object:

```swift
bleHelper.connect(yourPeripheral) { (peripheral, error) -> (Void) in
            //TODO: do something when connected
        }
```

To connect with a device by deviceUUID string (peripheral.identifier):

```swift
self.bleHelper.retrieve(deviceUUIDs: [deviceUUIDString], completion: {(peripheral, error) -> (Void) in
            if error != nil {
                prettyLog("error: \(error?.description)")
                completion?(success: false)
                return
            }
            prettyLog("connect with \(peripheral)")
        })
```

#### Operation

To read:

```swift
bleHelper.readValue("yourDeviceUUID", serviceUUID: "yourServiceUUID", characteristicUUID: "youCharacteristicUUID") { (success) -> (Void) in
            prettyLog("is read success: \(success)")
    }
```

To enable notification:

```swift
bleHelper.enableNotification(true, deviceUUID: "yourDeviceUUID", serviceUUID: "yourServiceUUID", characteristicUUID: "youCharacteristicUUID") { (success) -> (Void) in
        prettyLog("set notify success: \(success)")
    }
```

To write:

```swift
let command = "yourCommand"
if let data = command.dataUsingEncoding(NSUTF8StringEncoding) {
        bleHelper.writeValue(data, deviceUUID: "yourDeviceUUID", serviceUUID: "yourServiceUUID", characteristicUUID: "youCharacteristicUUID", withResponse: true) { (success) -> (Void) in
            prettyLog("is write success: \(success)")
        }
    }
```

#### Delegate

There are only two functions of its delegate. In the beginning, you must declare your class obeying the protocal: "BLECentralHelperDelegate."

Being called when disconnected from peripheral:

```swift
func bleDidDisconnectFromPeripheral(peripheral: CBPeripheral) {
	//TODO: do something...
}
```
Being called when received data from peripheral:

```swift
func bleCentralDidReceiveData(data: NSData?, peripheral: CBPeripheral, characteristic: CBCharacteristic) {
	//TODO: do something...
}
```
## Example

Open BLEHelper.xcworkspace with your xcode, and select the Scheme named "BLEHelperExample." 

Run it on your iPhone or iPad!

## License

BLEHelper is released under a MIT License. See LICENSE file for details.