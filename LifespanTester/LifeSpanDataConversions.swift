//
//  LifeSpanDataConversions.swift
//  LifespanTester
//
//  Created by Dan Crosby on 12/7/22.
//

import Foundation

struct LifeSpanDataConversions {
    static func toUInt16(_ responseData: Data) -> UInt16 {
        let bytes = responseData.subdata(in: 2..<4)
        return UInt16(bytes[0]) << 8 | UInt16(bytes[1])
    }

    static func toDecimal(_ responseData: Data) -> Decimal {
        let wholeByte = responseData[2]
        let fracByte = responseData[3]
        
        return Decimal(wholeByte) + Decimal(fracByte) / 100
    }

    static func toSeconds(_ responseData: Data) -> Int {
        let hours = Int(responseData[2])
        let minutes = Int(responseData[3])
        let seconds = Int(responseData[4])
        
        return 3600 * hours + 60 * minutes + seconds
    }
    
    static func toData(_ responseData: Data) -> String {
        return responseData.hexEncodedString()
    }
}
