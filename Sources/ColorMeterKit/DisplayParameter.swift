//
//  File.swift
//  
//
//  Created by chenlongmingob@gmail.com on 2020/12/30.
//

import Foundation

public struct DisplayParameter {
    public var firstLightSource: LightSource
    public var secondLightSource: LightSource
    public var measureMode: MeasureData.MeasureMode
    public var colorMode: ColorMode
    public var differenceFormula: DifferenceFormula
    
    public var data: [UInt8] {
        return [
            0xbb,
            0x1a,
            firstLightSource.category.rawValue,
            firstLightSource.angle.rawValue,
            measureMode.rawValue,
            colorMode.rawValue,
            differenceFormula.rawValue,
            secondLightSource.byte,
            0xff,
            0
        ]
    }
    
    public init(firstLightSource: LightSource, secondLightSource: LightSource, measureMode: MeasureData.MeasureMode, colorMode: ColorMode, differenceFormula: DifferenceFormula) {
        self.firstLightSource = firstLightSource
        self.secondLightSource = secondLightSource
        self.measureMode = measureMode
        self.colorMode = colorMode
        self.differenceFormula = differenceFormula
    }
}

