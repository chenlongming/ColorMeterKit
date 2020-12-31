//
//  File.swift
//  
//
//  Created by chenlongmingob@gmail.com on 2020/12/30.
//

import Foundation

public struct CalibrationState {
    public var whiteCalibrateTimestamp: UInt32
    public var blackCalibrateTimestamp: UInt32
    
    public var whiteCalibrateDate: Date { Date(timeIntervalSince1970: TimeInterval(whiteCalibrateTimestamp)) }
    public var blackCalibrateDate: Date { Date(timeIntervalSince1970: TimeInterval(blackCalibrateTimestamp)) }
    
    public init(data: Data) {
        whiteCalibrateTimestamp = data.subdata(in: 3 ..< 7).uint32
        blackCalibrateTimestamp = data.subdata(in: 8 ..< 12).uint32
    }
}
