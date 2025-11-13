//
//  ElementEvents.swift
//  
//
//  Created by Brian Gonzalez on 10/26/22.
//

import Foundation

public struct ElementEventDetails: Encodable {
    public var type: String
    public var message: String
}

public struct ElementEvent: Encodable {
    public var type: String
    public var complete: Bool
    public var empty: Bool
    public var valid: Bool
    public var maskSatisfied: Bool
    public var details: [ElementEventDetails]
    public var binInfo: BinInfo?
    public var selectedNetwork: String?
    
    func encode() throws -> [String: String?] {
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(self)
        if let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
            let event = jsonObject.compactMapValues { value in
                value as? String
            }
            return event
        } else {
            throw ConversionError.invalidJSON
        }
    }
    
    enum ConversionError: Error {
        case invalidJSON
    }
}
