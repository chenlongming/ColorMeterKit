//
//  File.swift
//  
//
//  Created by chenlongmingob@gmail.com on 2020/12/25.
//

import Foundation

extension Array where Element == UInt8 {
    public var data: Data {
        Data(bytes: self, count: count)
    }
}


extension Data {
    public func toArray() -> [UInt8] {
        return [UInt8](self)
    }
    
    public func toDescription() -> [String] {
        return self.map { String(format: "%02X", $0) }
    }
    
    public var uint16: UInt16 {
        return self.withUnsafeBytes { $0.load(as: UInt16.self) }
    }
    
    public var uint32: UInt32 {
        return self.withUnsafeBytes { $0.load(as: UInt32.self) }
    }
    
    public var float32: Float32 {
        return self.withUnsafeBytes { $0.load(as: Float32.self) }
    }
    
}

