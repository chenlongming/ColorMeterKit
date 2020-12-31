# ColorMeterKit: ColorMeter SDK For Swift

[中文](README.md)

Encapsulates the Bluetooth commands of the ColorMeter device, such as: measurement, calibration, reading instrument information, setting the display parameters and tolerance parameters of the instrument, etc. It also provides the function of simple color mode conversion, providing `RGB`, `Lab`, How to convert between `XYZ` modes

Since Bluetooth communication is a relatively complex asynchronous operation, the related Bluetooth commands are all encapsulated into observable objects using the [RxSwift](https://github.com/ReactiveX/RxSwift) library, which is easy to operate

## Requirements

- Xcode 12.x

- Swift 5.x

  

## Installation

Currently only supports the installation method of Swift Package Manager



## usage

```
import UIKit
import ColorMeterKit
import RxSwift
import CoreBluetooth

class ViewController: UIViewController {
	let cm = CMKit()
	var scanDisposable: Disposable?
	var peripherals: [CBPeripheral] = []
	
	// Scan for devices and add discovered devices to the peripherals array
	func scan() {
		if !cm.isScanning {
			peripherals = []
			cm.startScan()
			scanDisposable = cm.observeScanned().subscribe(onNext: { [weak self] state in
      	if let strongSelf = self, let peripheral = state.peripheral {
      		// scanned peripheral
      		strongSelf.peripherals.append(peripheral)
      	}
      })
		}
	}
	
	// Stop scanning
	func stopScan() {
		if cm.isScanning {
			scanDisposable?.dispose()
			cm.stopScan()
		}
	}
	
	// Connect to peripheral
	func connect(index: Int) {
		_ = cm.connect(peripherals[index]).subscribe(onNext: { state in
    	// todo success
    })
	}
	
	func measure() {
		_ = cm.measureWithResponse().subscribe { data in
			if let data = data {
				// todo success
			}
		} onError: { error in
			// todo failure
		}
	}
}
```

Demo: [ColorMeterKitDemo](https://github.com/chenlongming/ColorMeterKitDemo)

