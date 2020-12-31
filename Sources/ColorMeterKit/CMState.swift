//
//  File.swift
//  
//
//  Created by chenlongmingob@gmail.com on 2020/12/28.
//

import Foundation
import CoreBluetooth


public class CMState {
    public enum State {
        case startScan,
             scanned,
             stopScan,
             connecting,
             connected,
             disconnect,
             notification
    }
    
    public var state: State
    
    /// notification data content, exists if state is `CMState.State.notification`
    public var data: Data?
    
    /// peripheral with state updated
    ///
    /// exists if state in the following:
    /// `CMState.State.scanned` scanned peripheral
    /// `CMState.State.connecting` connecting peripheral
    /// `CMState.State.connected` connected peripheral
    /// `CMState.State.disconnect` disconnect peripheral
    /// `CMState.State.notification` notification peripheral
    ///
    public var peripheral: CBPeripheral?
    
    init(state: State, data: Data? = nil, peripheral: CBPeripheral? = nil) {
        self.state = state
        self.data = data
        self.peripheral = peripheral
    }
}
