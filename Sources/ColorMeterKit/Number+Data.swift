//
//  File.swift
//  
//
//  Created by chenlongmingob@gmail.com on 2020/12/30.
//

import Foundation

extension BinaryInteger {
    public var data: Data {
        var copy = self
        return Data(withUnsafeBytes(of: &copy, { $0 }))
    }
}

extension BinaryFloatingPoint {
    public var data: Data {
        var copy = self
        return Data(withUnsafeBytes(of: &copy, { $0 }))
    }
}
