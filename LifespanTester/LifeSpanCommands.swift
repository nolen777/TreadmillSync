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
    
    init(description: String, commandData: Data) {
        self.description = description
        self.commandData = commandData
    }
}

class QueryCommand: LifeSpanCommand {
    let responseProcessor: (Data) -> Any
    
    init(description: String, commandData: Data, responseProcessor: @escaping (Data) -> Any) {
        self.responseProcessor = responseProcessor
        super.init(description: description, commandData: commandData)
    }
    
    convenience init?(description: String, commandHexString: String, responseProcessor: @escaping (Data) -> Any) {
        guard let commandData = Data(hexString: commandHexString) else {
            return nil
        }
        self.init(description: description, commandData: commandData, responseProcessor: responseProcessor)
    }
}

class ImperativeCommand: LifeSpanCommand {
    let expectedResponse: Data
    
    init(description: String, commandData: Data, expectedResponse: Data) {
        self.expectedResponse = expectedResponse
        super.init(description: description, commandData: commandData)
    }
    
    convenience init?(description: String, commandHexString: String, expectedResponseHexString: String) {
        guard let commandData = Data(hexString: commandHexString), let responseData = Data(hexString: expectedResponseHexString) else {
            return nil
        }
        self.init(description: description, commandData: commandData, expectedResponse: responseData)
    }
}

struct LifeSpanCommands {
    enum LifeSpanCommandError: Error {
        case invalidSpeed
    }
    
    // The LifeSpan app sends these commands before the queries below, and their responses look different, but
    // I'm not sure what they do, so they're currently unused
    static let initializationCommands: [ImperativeCommand] = [
        ImperativeCommand(description: "firstInitialization", commandHexString: "0200000000", expectedResponseHexString: "02aa11180000")!,
        ImperativeCommand(description: "secondInitialization", commandHexString: "c000000000", expectedResponseHexString: "c0ff00000000")!,
    ]
    
    // These commands cause the treadmill to write back useful data
    static let queryCommands: [QueryCommand] = [
        QueryCommand(description: "speedInMph", commandHexString: "a182000000", responseProcessor: LifeSpanDataConversions.toDecimal)!,
        QueryCommand(description: "distanceInMiles", commandHexString: "a185000000", responseProcessor: LifeSpanDataConversions.toDecimal)!,
        QueryCommand(description: "calories", commandHexString: "a187000000", responseProcessor: LifeSpanDataConversions.toUInt16)!,
        QueryCommand(description: "steps", commandHexString: "a188000000", responseProcessor: LifeSpanDataConversions.toUInt16)!,
        QueryCommand(description: "timeInSeconds", commandHexString: "a189000000", responseProcessor: LifeSpanDataConversions.toSeconds)!,
    ]
    
    // These look like queries, and their response values do sometimes vary, but I don't know what they mean.
    // So they're currently unused.
    static let unknownCommands: [LifeSpanCommand] = [
        QueryCommand(description: "unknown91", commandHexString: "a191000000", responseProcessor: LifeSpanDataConversions.toHexEncodedString)!,
        QueryCommand(description: "unknown81", commandHexString: "a181000000", responseProcessor: LifeSpanDataConversions.toHexEncodedString)!,
        QueryCommand(description: "unknown61", commandHexString: "a161000000", responseProcessor: LifeSpanDataConversions.toHexEncodedString)!,
        QueryCommand(description: "unknown62", commandHexString: "a162000000", responseProcessor: LifeSpanDataConversions.toHexEncodedString)!,
        QueryCommand(description: "unknown8B", commandHexString: "a18b000000", responseProcessor: LifeSpanDataConversions.toHexEncodedString)!,
        QueryCommand(description: "unknown86", commandHexString: "a186000000", responseProcessor: LifeSpanDataConversions.toHexEncodedString)!,
        QueryCommand(description: "unknown63", commandHexString: "a163000000", responseProcessor: LifeSpanDataConversions.toHexEncodedString)!,
        QueryCommand(description: "unknown64", commandHexString: "a164000000", responseProcessor: LifeSpanDataConversions.toHexEncodedString)!,
    ]
    
    static let resetCommand = ImperativeCommand(description: "reset", commandHexString: "e200000000", expectedResponseHexString: "e2aa00000000")!
    
    // Currently unused
    static let startCommand = ImperativeCommand(description: "startTreadmill", commandHexString: "e100000000", expectedResponseHexString: "")!
    
    // Currently unused
    static let stopCommand = ImperativeCommand(description: "stopTreadmill", commandHexString: "e000000000", expectedResponseHexString: "")!
    
    // Currently unused
    static func speedCommand(speed: Float) throws -> ImperativeCommand {
        guard (speed > 4.0 || speed < 0.4) else {
            throw LifeSpanCommandError.invalidSpeed
        }
        let speedHundredths = UInt16(speed * 100.0)
        let unitsByte = UInt8(speedHundredths >> 8)
        let fractionByte = UInt8(speedHundredths & 0xFF)
        
        let data = Data(bytes: [0xd0, unitsByte, fractionByte, 0x00, 0x00], count: 5)
        return ImperativeCommand(description: "adjustSpeed", commandData: data, expectedResponse: Data())
    }
}
