//
//  File.swift
//  
//
//  Created by chenlongmingob@gmail.com on 2020/12/23.
//

import Foundation

public class Command {
    /// command response bytes count
    public var responseBytesCount: Int!
    
    /// command response timeout seconds
    public var timeout: Int!
    
    /// command content
    public var bytes: [UInt8]?
    
    /// get command content data
    public var data: Data {
        guard var bytes = bytes else {
            return Data()
        }
        
        var n = 0
        for byte in bytes {
            n += Int(byte)
        }
        bytes[bytes.count - 1] = UInt8(n % 255)
        return Data(bytes: bytes, count: bytes.count)
    }
    
    
    public init(bytes: [UInt8], responseBytesCount: Int = 0, timeout: Int = 2) {
        self.bytes = bytes
        self.responseBytesCount = responseBytesCount
        self.timeout = timeout
    }
    
    /// validate response data
    public static func validate(data: Data) -> Bool {
        var n = 0
        data.subdata(in: 0 ..< data.count - 1).forEach { n += Int($0) }
        return (n % 0x100) == Int(data[data.count - 1])
    }
    
    /// validate response data
    public static func validate(data: [UInt8]) -> Bool {
        let data = Data(bytes: data, count: data.count)
        return self.validate(data: data)
    }
    
    
    public static var measureId: UInt32 = 1
    
    public static let wakeUp = Command(bytes: [0xF0])
    
    public static func measure(_ mode: MeasureData.MeasureMode = .SCI) -> Command {
        let id = measureId.data
        measureId += 1
        var command: [UInt8] = [0xbb, 0x01, mode.rawValue, 0x00, 0xff, 0x00]
        command.insert(contentsOf: id, at: 3)
        return Command(bytes: command, responseBytesCount: 10, timeout: 3)
    }
    
    public static func getMeasureData(_ mode: MeasureData.MeasureMode = .SCI) -> Command {
        return Command(bytes: [0xbb, 0x02, mode.rawValue + 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0x00], responseBytesCount: 200)
    }
    
    public static var blackCalibrate = Command(bytes: [0xbb, 0x10, 0, 0, 0, 0, 0, 0, 0xff, 0], responseBytesCount: 10, timeout: 3)
    
    public static var whiteCalibrate = Command(bytes: [0xbb, 0x11, 0, 0, 0, 0, 0, 0, 0xff, 0], responseBytesCount: 10, timeout: 3)
    
    public static var getStorageCount = Command(bytes: [0xbb, 0x16, 0, 0, 0, 0, 0, 0, 0xff, 0], responseBytesCount: 10)
    
    public static func getStorageData(_ index: UInt16) -> Command {
        var command: [UInt8] = [0xbb, 0x16, 0x01, 0, 0, 0, 0xff, 0]
        command.insert(contentsOf: index.data, at: 3)
        return Command(bytes: command, responseBytesCount: 250, timeout: 3)
    }
    
    public static var clearStorage = Command(bytes: [0xbb, 0x16, 0x04, 0, 0, 0, 0, 0, 0xff, 0], responseBytesCount: 10)
    
    public static func deleteStorage(_ index: UInt16) -> Command {
        var command: [UInt8] = [0xbb, 0x16, 0x02, 0, 0, 0, 0xff, 0]
        command.insert(contentsOf: index.data, at: 3)
        return Command(bytes: command, responseBytesCount: 10)
    }
    
    public static func transferData(_ data: MeasureData) -> Command {
        return Command(bytes: data.data, responseBytesCount: 10)
    }
    
    public static var getPeripheralDetail = Command(bytes: [0xbb, 0x12, 0x01, 0, 0, 0, 0, 0, 0xff, 0], responseBytesCount: 200, timeout: 3)
    
    public static var getCalibrationState = Command(bytes: [0xbb, 0x1e, 0, 0, 0, 0, 0, 0, 0xff, 0], responseBytesCount: 20)
    
    public static func setDisplayParameter(_ parameter: DisplayParameter) -> Command {
        return Command(bytes: parameter.data, responseBytesCount: 10)
    }
    
    public static func setToleranceParameter(_ parameter: ToleranceParameter) -> Command {
        return Command(bytes: parameter.data, responseBytesCount: 10)
    }
    
    public static func setWhiteness(_ whiteness: ColorMode.Whiteness) -> Command {
        return Command(bytes: [0xbb, 0x21, 0, whiteness.rawValue, 0, 0, 0, 0, 0xff, 0], responseBytesCount: 10)
    }
}
