[![Travis CI](https://travis-ci.org/HarveyHu/BLEHelper.svg?branch=master)](https://travis-ci.org/HarveyHu/BLEHelper)

BLEHelper is an open-source framework for iOS, which can help you deal with your Bluetooth Low Energy device in an elegant way.

## Installation

BLEHelper is available on Carthage. Just add the following to your project Cartfile:

```ruby
github "HarveyHu/BLEHelper"
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

### Operation

To scan devices nearby, and the completion is on the end:

```swift
bleHelper.scan(1.0, serviceUUID: nil) { (devices) -> (Void) in
            //TODO: show your devices
        }
```

To connect with a device by object:

```swift
bleHelper.connect(yourPeripheral) { (peripheral, error) -> (Void) in
            //TODO: do something when connected
        }
```

To connect with a device by deviceUUID string (peripheral.identifier):

```swift
self.bleHelper.retrieve(deviceUUID: self.deviceUUIDString!, completion: {(peripheral, error) -> (Void) in
            if error != nil {
                prettyLog("error: \(error?.description)")
                completion?(success: false)
                return
            }
            prettyLog("connect with \(peripheral)")
        })
```

To read:

```swift
bleHelper.readValue("yourServiceUUID", characteristicUUID: "youCharacteristicUUID") { (success) -> (Void) in
            prettyLog("is read success: \(success)")
    }
```

To enable notification:

```swift
bleHelper.enableNotification(true, serviceUUID: "yourServiceUUID", characteristicUUID: "youCharacteristicUUID") { (success) -> (Void) in
        prettyLog("set notify success: \(success)")
    }
```

To write:

```swift
let command = "yourCommand"
if let data = command.dataUsingEncoding(NSUTF8StringEncoding) {
        bleHelper.writeValue(data, serviceUUID: "yourServiceUUID", characteristicUUID: "youCharacteristicUUID") { (success) -> (Void) in
            prettyLog("is write success: \(success)")
        }
    }
```

### Delegate

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

## Future Improving

For now, BLEHelper is only used for single device. I'm going to make it support multi-devices.

## License

BLEHelper is released under a MIT License. See LICENSE file for details.