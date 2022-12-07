//
//  DataHexStringExtension.swift
//  LifespanTester
//
//  Created by Dan Crosby on 12/7/22.
//

import Foundation

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }
    
    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }
    
    init?(hexString str: String) {
        var unprefixedStr: String
        if str.hasPrefix("0x") || str.hasPrefix("0X") {
            unprefixedStr = String(str.dropFirst(2))
        } else if str.hasPrefix("x") || str.hasPrefix("X") {
            unprefixedStr = String(str.dropFirst(1))
        } else {
            unprefixedStr = str
        }
        self.init(capacity: unprefixedStr.count / 2)
        var currentByte: UInt8?
        for c in unprefixedStr {
            guard let nibble = c.hexDigitValue else {
                print("Uh oh!")
                return nil
            }
            
            if let existingByte = currentByte {
                self.append(existingByte | UInt8(nibble))
                currentByte = nil
            } else {
                currentByte = UInt8(nibble) << 4
            }
        }
        guard currentByte == nil else {
            print("Bad nibble!")
            return nil
        }
    }
}
