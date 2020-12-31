# ColorMeterKit: ColorMeter SDK For Swift

[English Document](README_EN.md)

封装了 ColorMeter 设备的蓝牙命令, 如: 测量, 校准, 读取仪器信息, 设置仪器的显示参数和容差参数等. 同时也提供了简单色彩模式转换的功能, 提供 `RGB`, `Lab`, `XYZ` 模式相互转换的方法

由于蓝牙通信是较为复杂的异步操作, 相关的蓝牙命令都使用 [RxSwift](https://github.com/ReactiveX/RxSwift) 库封装成了可观察对象, 便于操作

## Requirements

- Xcode 12.x

- Swift 5.x

  

## Installation

目前只支持 Swift Package Manager 的安装方式



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
	
	// 扫描设备并将发现的设备添加到 peripherals 数组中
	func scan() {
		if !cm.isScanning {
			peripherals = []
			cm.startScan()
			scanDisposable = cm.observeScanned().subscribe(onNext: { [weak self] state in
      	if let strongSelf = self, let peripheral = state.peripheral {
      		// 发现设备
      		strongSelf.peripherals.append(peripheral)
      	}
      })
		}
	}
	
	// 停止扫描
	func stopScan() {
		if cm.isScanning {
			scanDisposable?.dispose()
			cm.stopScan()
		}
	}
	
	// 连接指定设备
	func connect(index: Int) {
		_ = cm.connect(peripherals[index]).subscribe(onNext: { state in
    	// todo 连接成功
    })
	}
	
	func measure() {
		_ = cm.measureWithResponse().subscribe { data in
			if let data = data {
				// todo 测量成功
			}
		} onError: { error in
			// todo 测量失败
		}
	}
}
```

