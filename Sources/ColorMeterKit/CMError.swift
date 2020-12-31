//
//  File.swift
//  
//
//  Created by chenlongmingob@gmail.com on 2020/12/22.
//

import Foundation


public enum CMError: Error {
    
    // MARK: - bluetooth errors
    case peripheralDisconnect
    case characteristicNotFound
    case failToConnect
    case invalidResponseData
    case responseTimeout
    case storageIndexOutOfRange
    case getStorageFailure
    
    
    // MARK: - color formatter errors
    case invalidSpectralWaveInterval
    
    case unknown
}
