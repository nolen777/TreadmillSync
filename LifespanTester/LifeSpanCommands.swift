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
    
    let resetCommand = LifeSpanCommand(description: "reset", commandHexString: "e200000000", responseProcessor: LifeSpanDataConversions.toData)!
}
