//
//  File.swift
//  
//
//  Created by chenlongmingob@gmail.com on 2020/12/31.
//

import Foundation

public class CMColor {
    public typealias XYZ = (Double, Double, Double)
    public typealias Lab = (Double, Double, Double)
    public typealias CH = (Double, Double)
    public typealias RGB = (UInt8, UInt8, UInt8)
    
    private var filledSpectral: [Double]!
    private var lightSource: LightSource!
    
    public var xyz: XYZ!
    public var lab: Lab!
    public var ch: CH!
    public var rgb: RGB!
    
    
    public init(spectral: [Double], waveStart: Int, lightSource: LightSource) {
        self.lightSource = lightSource
        fillSpectral(spectral: spectral, waveStart: waveStart)
        let xyz = Self.spectral2XYZ(spectral: filledSpectral, lightSource: lightSource)
        let lab = Self.XYZ2Lab(xyz: xyz, lightSource: lightSource)
        let ch = Self.Lab2CH(lab: lab)
        let rgb = Self.Lab2RGB(lab: lab)
        self.xyz = xyz
        self.lab = lab
        self.ch = ch
        self.rgb = rgb
    }
    
    
    private func fillSpectral(spectral: [Double], waveStart: Int) {
        var spectral = spectral
        spectral.insert(contentsOf: Array(repeating: 0, count: (waveStart - 360) / 10), at: 0)
        spectral.append(contentsOf: Array(repeating: 0, count: (43 - spectral.count)))
        filledSpectral = spectral
    }
    
    
    public static func spectral2XYZ(spectral: [Double], lightSource: LightSource) -> XYZ {
        let params = lightSource.category.kl
        var x: Double = 0
        var y: Double = 0
        var z: Double = 0
        let k = lightSource.kal
        
        for i in 0 ..< 43 {
            let light = params.count <= i ? 0 : params[i]
            let kx = lightSource.angle.kx.count <= i ? 0 : lightSource.angle.kx[i]
            let ky = lightSource.angle.ky.count <= i ? 0 : lightSource.angle.ky[i]
            let kz = lightSource.angle.kz.count <= i ? 0 : lightSource.angle.kz[i]
            
            x += spectral[i] * 0.01 * light * kx;
            y += spectral[i] * 0.01 * light * ky;
            z += spectral[i] * 0.01 * light * kz;
        }
    
        return (x * k, y * k, z * k)
    }
    
    
    public static func XYZ2Lab(xyz: XYZ, lightSource: LightSource) -> Lab {
        var l: Double = 0
        var a: Double = 0
        var b: Double = 0
        let (x, y, z) = xyz
        
        var paramX: Double = x / lightSource.kxyz_labch[0]
        var paramY: Double = y / lightSource.kxyz_labch[1]
        var paramZ: Double = z / lightSource.kxyz_labch[2]
        
        if paramX > 0.008856 {
           paramX = pow(paramX, 0.3333333)
        } else {
            paramX = 7.787 * paramX + 0.138
        }
        
        if (paramY > 0.008856) {
            paramY = pow(paramY, 0.3333333);
            l = 116 * paramY - 16;
        } else {
            l = 903.3 * paramY;
            paramY = (7.787 * paramY) + 0.138;
        }
        
        if paramZ > 0.008856 {
           paramZ = pow(paramZ, 0.3333333)
        } else {
            paramZ = 7.787 * paramZ + 0.138
        }
        
        a = 500 * (paramX - paramY)
        b = 200 * (paramY - paramZ)
        
        return (l, a, b)
    }
    
    
    public static func Lab2CH(lab: Lab) -> CH {
        var (l, a, b) = lab
        if l < 0 { l = 0 }
        let c = sqrt(pow(a, 2) + pow(b, 2))
        var h = 0.0
        if a == 0 && b > 0 {
            h = 90
        } else if a == 0 && b < 0 {
            h = 270
        } else if a >= 0 && b == 0 {
            h = 0
        } else if a < 0 && b == 0 {
            h = 180
        } else {
            h = atan(b / a) * 57.3
            if a > 0 && b > 0 {  }
            else if a < 0 {
                h += 180
            } else {
                h += 360
            }
        }
        
        return (c, h)
    }
    
    
    public static func Lab2RGB(lab: Lab) -> RGB {
        let (l, a, b) = lab
        
        var y = (l + 16) / 116
        var x = a / 500 + y
        var z = y - b / 200
        
        y = y > 6 / 29 ? pow(y, 3) : (y - 16 / 116) / 7.787
        x = x > 6 / 29 ? pow(x, 3) : (x - 16 / 116) / 7.787
        z = z > 6 / 29 ? pow(z, 3) : (z - 16 / 116) / 7.787
        
        x *= 0.95047
        z *= 1.08883
        
        var red = 3.2406 * x - 1.5372 * y - 0.4986 * z
        var green = -0.9689 * x + 1.8758 * y + 0.0415 * z
        var blue = 0.0557 * x - 0.2040 * y + 1.0570 * z
        
        red = red > 0.0031308 ? 1.055 * pow(red, 1 / 2.4) - 0.055 : 12.92 * red
        green = green > 0.0031308 ? 1.055 * pow(green, 1 / 2.4) - 0.055 : 12.92 * green
        blue = blue > 0.0031308 ? 1.055 * pow(blue, 1 / 2.4) - 0.055 : 12.92 * blue
        
        return (UInt8(min(red * 255, 255)), UInt8(min(green * 255, 255)), UInt8(min(blue * 255, 255)))
    }
}
