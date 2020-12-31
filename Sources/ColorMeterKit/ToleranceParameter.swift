//
//  File.swift
//  
//
//  Created by chenlongmingob@gmail.com on 2020/12/30.
//

import Foundation

public struct ToleranceParameter {
    public var L: Float32
    public var a: Float32
    public var b: Float32
    public var c: Float32
    public var H: Float32
    public var dE_ab: Float32
    public var dE_ch: Float32
    public var dE_cmc: Float32
    public var dE_94: Float32
    public var dE_00: Float32
    
    public var data: [UInt8] {
        var data: [UInt8] = Array(repeating: 0, count: 100)
        data[0] = 0xbb
        data[1] = 0x1b
        data[2] = 0x01
        data.replaceSubrange(6...9, with: L.data)
        data.replaceSubrange(10...13, with: a.data)
        data.replaceSubrange(14...17, with: b.data)
        data.replaceSubrange(18...21, with: c.data)
        data.replaceSubrange(22...25, with: H.data)
        data.replaceSubrange(26...29, with: dE_ab.data)
        data.replaceSubrange(30...33, with: dE_ch.data)
        data.replaceSubrange(34...37, with: dE_cmc.data)
        data.replaceSubrange(38...41, with: dE_94.data)
        data.replaceSubrange(42...45, with: dE_00.data)
        data[98] = 0xff
        return data
    }
    
    
    public init(L: Float32, a: Float32, b: Float32, c: Float32, H: Float32, dE_ab: Float32, dE_ch: Float32, dE_cmc: Float32, dE_94: Float32, dE_00: Float32) {
        self.L = L
        self.a = a
        self.b = b
        self.c = c
        self.H = H
        self.dE_ab = dE_ab
        self.dE_ch = dE_ch
        self.dE_cmc = dE_cmc
        self.dE_94 = dE_94
        self.dE_00 = dE_00
    }
}
