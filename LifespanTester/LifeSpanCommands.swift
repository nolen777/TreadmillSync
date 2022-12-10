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

class InitializationCommand: LifeSpanCommand {
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
    
    static let initializationCommands: [InitializationCommand] = [
        InitializationCommand(description: "firstInitialization", commandHexString: "0200000000", expectedResponseHexString: "02aa11180000")!,
        InitializationCommand(description: "secondInitialization", commandHexString: "c000000000", expectedResponseHexString: "c0ff00000000")!,
    ]
    
    static let queryCommands: [QueryCommand] = [
        QueryCommand(description: "speedInMph", commandHexString: "a182000000", responseProcessor: LifeSpanDataConversions.toDecimal)!,
        QueryCommand(description: "distanceInMiles", commandHexString: "a185000000", responseProcessor: LifeSpanDataConversions.toDecimal)!,
        QueryCommand(description: "calories", commandHexString: "a187000000", responseProcessor: LifeSpanDataConversions.toUInt16)!,
        QueryCommand(description: "steps", commandHexString: "a188000000", responseProcessor: LifeSpanDataConversions.toUInt16)!,
        QueryCommand(description: "timeInSeconds", commandHexString: "a189000000", responseProcessor: LifeSpanDataConversions.toSeconds)!,
    ]
    
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
    
    static let resetCommand = InitializationCommand(description: "reset", commandHexString: "e200000000", expectedResponseHexString: "e2aa00000000")!
    
    // Currently unused
    static let startCommand = QueryCommand(description: "startTreadmill", commandHexString: "e100000000", responseProcessor: LifeSpanDataConversions.toHexEncodedString)!
    
    // Currently unused
    static let stopCommand = QueryCommand(description: "stopTreadmill", commandHexString: "e000000000", responseProcessor: LifeSpanDataConversions.toHexEncodedString)!
    
    // Currently unused
    static func speedCommand(speed: Float) throws -> LifeSpanCommand {
        guard (speed > 4.0 || speed < 0.4) else {
            throw LifeSpanCommandError.invalidSpeed
        }
        let speedHundredths = UInt16(speed * 100.0)
        let unitsByte = UInt8(speedHundredths >> 8)
        let fractionByte = UInt8(speedHundredths & 0xFF)
        
        let data = Data(bytes: [0xd0, unitsByte, fractionByte, 0x00, 0x00], count: 5)
        return QueryCommand(description: "adjustSpeed", commandData: data, responseProcessor: LifeSpanDataConversions.toHexEncodedString)
    }
}
