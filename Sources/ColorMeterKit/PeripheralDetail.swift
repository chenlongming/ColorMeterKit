//
//  File.swift
//  
//
//  Created by chenlongmingob@gmail.com on 2020/12/30.
//

import Foundation

public struct PeripheralDetail: Identifiable {
    public var id: String {
        return serial
    }
    
    public var code: UInt16
    public var model: String
    public var serial: String
    public var softwaveVersion: String
    public var hardwaveVersion: String
    
    public var isNeutral: Bool
    
    public init(data: Data) {
        code = data.subdata(in: 5..<7).uint16
        model = String(bytes: data.subdata(in: 37..<67).filter({ $0 != 0 }), encoding: .utf8) ?? ""
        serial = String(bytes: data.subdata(in: 67..<97).filter({ $0 != 0 }), encoding: .utf8) ?? ""
        softwaveVersion = String(bytes: data.subdata(in: 97..<127).filter({ $0 != 0 }), encoding: .utf8) ?? ""
        hardwaveVersion = String(bytes: data.subdata(in: 127..<157).filter({ $0 != 0 }), encoding: .utf8) ?? ""
        isNeutral = data[159] == 1
    }
}
