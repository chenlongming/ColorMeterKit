//
//  File.swift
//  
//
//  Created by chenlongmingob@gmail.com on 2020/12/30.
//

import Foundation

public enum ColorMode: UInt8 {
    case CIELab
    case CIELch
    case hunterLab
    case Luv
    case XYZ
    case Yxy
    case RGB
    case metamerism
    case reflect
    case opacity
    case densityA
    case densityT
    case densityE
    case densityM
    case munsell
    case tint
    case whiteness
    case yellowness
    case blackness
    case strength
    case fastness
    case colorClassification555
    case spotInkDensity
    case dotGain
    case trapping
    case contrast
    case hueDifferenceAndGrayness
    
    
    public enum Whiteness: UInt8 {
        case ASTM
        case CIE
        case hunter
        case ganz
        case taube
        case berger
        case AATCC
        case blueLight
        case GB_T
    }
}
