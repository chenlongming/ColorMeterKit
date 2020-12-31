//
//  File.swift
//  
//
//  Created by chenlongmingob@gmail.com on 2020/12/22.
//
import Foundation

public class MeasureData: CustomStringConvertible {
    public var mode: MeasureMode!
    public var from: DataFrom?
    public var valid = false
    
    /// if `LABOnly` equal true, reflects properties is invalid
    public var LABOnly = false
    
    
    // MARK: - reflects
    public var waveStart: UInt16 = 0
    public var waveInterval: UInt8 = 0
    public var waveCount: UInt8 = 0
    public var refs: [Float32] = []
    
    
    // MARK: - CIE_Lab
    public var CIE_L: Float32?
    public var CIE_a: Float32?
    public var CIE_b: Float32?
    
    
    // MARK: - light source
    public var lightSource: LightSource?
    
    public var name: String?
    
    public var data: [UInt8] {
        var data: [UInt8] = Array(repeating: 0, count: 250)
        data[0] = 0xbb
        data[1] = 0x16
        data[2] = 0x0a
        data[5] = 0x11
        data[7] = mode.rawValue
        data[8] = LABOnly ? 1 : 0
        data[9] = UInt8(waveStart / 10)
        data[10] = waveInterval
        data[11] = waveCount
        if let name = name?.data(using: .utf8), name.count < 18 {
            data.replaceSubrange(12...12 + name.count - 1, with: name)
        }
        
        
        
        if LABOnly, let angle = lightSource?.angle, let category = lightSource?.category, let l = CIE_L?.data, let a = CIE_a?.data, let b = CIE_b?.data {
            data[6] = (angle.rawValue << 7) + category.rawValue
            data.replaceSubrange(33...36, with: l)
            data.replaceSubrange(37...40, with: a)
            data.replaceSubrange(41...44, with: b)
        } else if refs.count > 0 {
            var reflectBytes = Data()
            for ref in refs {
                reflectBytes.append(contentsOf: UInt16(ref * 100).data)
            }
            let start = mode == .SCI ? 45 : 131
            data.replaceSubrange(start...start + reflectBytes.count - 1, with: reflectBytes)
        }
        
        let timestamp = UInt32(Date().timeIntervalSince1970).data
        data.replaceSubrange(221...224, with: timestamp)
        
        data[248] = 0xff
        
        return data
    }
    
    
    public init(mode: MeasureMode, waveStart: UInt16, waveInterval: UInt8, waveCount: UInt8, refs: [Float32], from: DataFrom? = nil, name: String? = nil) {
        self.mode = mode
        self.waveStart = waveStart
        self.waveInterval = waveInterval
        self.waveCount = waveCount
        self.refs = refs
        self.from = from
        _ = self.setName(name)
    }
    
    
    public init(CIE_L l: Float32, CIE_a a: Float32, CIE_b b: Float32, lightSourceCategory category: LightSource.Category = .D65, lightSourceAngle angle: LightSource.Angle = .deg10, from: DataFrom? = nil, name: String? = nil) {
        self.CIE_L = l
        self.CIE_a = a
        self.CIE_b = b
        self.lightSource = LightSource(angle: angle, category: category)
        self.LABOnly = true
        self.from = from
        _ = self.setName(name)
    }
    
    
    public init(data: Data, from: DataFrom) {
        if from == .measure {
            resolveMeasureData(data: data)
        } else {
            try? resolvePeripheralStorage(data: data)
        }
        self.from = from
    }
    
    
    public func setName(_ name: String?) -> Bool {
        if let nameBytes = name?.data(using: .utf8), nameBytes.count < 18 {
            self.name = name
            return true
        }
        return false
    }
    
    
    private func resolveMeasureData(data: Data) {
        if (data.count == 200) {
            mode = MeasureMode(rawValue: data[2] - 0x10)
            waveStart = (UInt16(data[4]) << 8) + UInt16(data[5])
            waveInterval = data[6]
            waveCount = data[7]
            var n = 8
            while n < 8 + Int(waveCount) * 4 {
                refs.append(data.subdata(in: n ..< (n + 4)).float32)
                n += 4
            }
            valid = true
        }
    }
    
    
    private func resolvePeripheralStorage(data: Data) throws {
        if (data.count == 250) {
            if data[5] == 2 {
                throw CMError.storageIndexOutOfRange
            } else if data[5] == 1 {
                throw CMError.getStorageFailure
            } else {
                mode = MeasureMode(rawValue: data[8])
                lightSource = LightSource(byte: data[7])
                var nameBytes = [UInt8]()
                for byte in data.subdata(in: 13 ..< 31) {
                    if byte == 0 { break }
                    nameBytes.append(byte)
                }
                name = String(bytes: nameBytes, encoding: .utf8)
                if data[9] == 0 {
                    // has reflects
                    waveStart = UInt16(data[10]) * 10
                    waveInterval = data[11]
                    waveCount = data[12]
                    var n = mode == .SCI ? 46 : 132
                    let end = Int(waveCount) * 2 + (mode == .SCI ? 46 : 132)
                    while n < end {
                        refs.append(Float32(data.subdata(in: n ..< (n + 4)).uint16) / 100)
                        n += 2
                    }
                } else {
                    // only lab data
                    LABOnly = true
                    CIE_L = data.subdata(in: 34 ..< 38).float32
                    CIE_a = data.subdata(in: 38 ..< 42).float32
                    CIE_b = data.subdata(in: 42 ..< 46).float32
                }
            }
        }
    }
    
    
    public var description: String {
        return "valid: \(valid), LABOnly: \(LABOnly), mode: \(mode.string) dataFrom: \(from) \n" + { () -> String in
            if LABOnly {
                return "L: \(CIE_L), a: \(CIE_a), b: \(CIE_b), light source: \(lightSource?.category.string) \(lightSource?.angle.string)"
            } else {
                return """
                    wave start: \(waveStart), interval: \(waveInterval), count: \(waveCount)
                    reflects: \(refs)
                    """
            }
        }()
    }
}


extension MeasureData {
    public enum DataFrom: UInt8 {
        /// data from measure
        case measure
        
        /// data from peripheral storage
        case storage
    }
    
    public enum MeasureMode: UInt8 {
        case SCI,
             SCE,
             M0,
             M1,
             M2,
             M3
        
        public var string: String {
            switch self {
            case .SCI:
                return "SCI"
            case .SCE:
                return "SCE"
            case .M0:
                return "M0"
            case .M1:
                return "M1"
            case .M2:
                return "M2"
            case .M3:
                return "M3"
            }
        }
    }
}
