//
//  LifeSpanCommands.swift
//  LifespanTester
//
//  Created by Dan Crosby on 12/6/22.
//

import Foundation

class LifeSpanCommand {
    let description: String
    let commandData: Data
    let responseProcessor: (Data) -> Any
    
    init(description: String, commandData: Data, responseProcessor: @escaping (Data) -> Any) {
        self.description = description
        self.commandData = commandData
        self.responseProcessor = responseProcessor
    }
    
    convenience init?(description: String, commandHexString: String, responseProcessor: @escaping (Data) -> Any) {
        guard let commandData = Data(hexString: commandHexString) else {
            return nil
        }
        self.init(description: description, commandData: commandData, responseProcessor: responseProcessor)
    }
}

struct LifeSpanCommands {
    enum LifeSpanCommandError: Error {
        case invalidSpeed
    }
    
    static let queryCommands: [LifeSpanCommand] = [
        LifeSpanCommand(description: "unknown91", commandHexString: "a191000000", responseProcessor: LifeSpanDataConversions.toData)!,
        LifeSpanCommand(description: "unknown81", commandHexString: "a181000000", responseProcessor: LifeSpanDataConversions.toData)!,
        LifeSpanCommand(description: "unknown61", commandHexString: "a161000000", responseProcessor: LifeSpanDataConversions.toData)!,
        LifeSpanCommand(description: "unknown62", commandHexString: "a162000000", responseProcessor: LifeSpanDataConversions.toData)!,
        LifeSpanCommand(description: "speedInMph", commandHexString: "a182000000", responseProcessor: LifeSpanDataConversions.toDecimal)!,
        LifeSpanCommand(description: "distanceInMiles", commandHexString: "a185000000", responseProcessor: LifeSpanDataConversions.toDecimal)!,
        LifeSpanCommand(description: "calories", commandHexString: "a187000000", responseProcessor: LifeSpanDataConversions.toUInt16)!,
        LifeSpanCommand(description: "steps", commandHexString: "a188000000", responseProcessor: LifeSpanDataConversions.toUInt16)!,
        LifeSpanCommand(description: "timeInSeconds", commandHexString: "a189000000", responseProcessor: LifeSpanDataConversions.toSeconds)!,
        LifeSpanCommand(description: "unknown8B", commandHexString: "a18b000000", responseProcessor: LifeSpanDataConversions.toData)!,
        LifeSpanCommand(description: "unknown86", commandHexString: "a186000000", responseProcessor: LifeSpanDataConversions.toData)!,
        LifeSpanCommand(description: "unknown63", commandHexString: "a163000000", responseProcessor: LifeSpanDataConversions.toData)!,
        LifeSpanCommand(description: "unknown64", commandHexString: "a164000000", responseProcessor: LifeSpanDataConversions.toData)!,
    ]
    
    static let resetCommand = LifeSpanCommand(description: "reset", commandHexString: "e200000000", responseProcessor: LifeSpanDataConversions.toData)!
    
    // Currently unused
    static let startCommand = LifeSpanCommand(description: "startTreadmill", commandHexString: "e100000000", responseProcessor: LifeSpanDataConversions.toData)!
    
    // Currently unused
    static let stopCommand = LifeSpanCommand(description: "stopTreadmill", commandHexString: "e000000000", responseProcessor: LifeSpanDataConversions.toData)!
    
    // Currently unused
    static func speedCommand(speed: Float) throws -> LifeSpanCommand {
        guard (speed > 4.0 || speed < 0.4) else {
            throw LifeSpanCommandError.invalidSpeed
        }
        let speedHundredths = UInt16(speed * 100.0)
        let unitsByte = UInt8(speedHundredths >> 8)
        let fractionByte = UInt8(speedHundredths & 0xFF)
        
        let data = Data(bytes: [0xd0, unitsByte, fractionByte, 0x00, 0x00], count: 5)
        return LifeSpanCommand(description: "adjustSpeed", commandData: data, responseProcessor: LifeSpanDataConversions.toData)
    }
}
