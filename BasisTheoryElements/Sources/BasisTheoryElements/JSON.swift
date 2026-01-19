//
//  JSON.swift
//  
//
//  Created by Brian Gonzalez on 12/21/22.
//

import Foundation

@dynamicMemberLookup
public enum JSON {
    case elementValueReference(ElementValueReference)
    case arrayValue(Array<JSON?>)
    case dictionaryValue(Dictionary<String, JSON>)
    case rawValue(Any)
    
    public var elementValueReference: ElementValueReference? {
        if case .elementValueReference(let elementValueRef) = self {
            return elementValueRef
        }
        return nil
    }
    
    public var rawValue: Any? {
        if case .rawValue(let rawValue) = self {
            return rawValue
        }
        return nil
    }

    public var value: Any? {
        switch self {
        case .elementValueReference(let ref):
            return ref.getValue() ?? ""
        case .arrayValue(let arr):
            return arr.map { $0?.value }
        case .dictionaryValue(let dict):
            var result: [String: Any] = [:]
            for (key, jsonValue) in dict {
                result[key] = jsonValue.value
            }
            return result
        case .rawValue(let val):
            return val
        }
    }
    
    public subscript(index: Int) -> JSON? {
        get {
            if case .arrayValue(let arr) = self {
                return index < arr.count ? arr[index] : nil
            }
            return nil
        }
        
        mutating set {
            if case .arrayValue(var arr) = self {
                if arr.capacity < index + 1 {
                    arr.reserveCapacity(index + 1)
                    arr.insert(newValue, at: index)
                } else {
                    arr[index] = newValue
                }
                self = JSON.arrayValue(arr)
            }
        }
    }
    
    public subscript(key: String) -> JSON? {
        get {
            if case .dictionaryValue(let dict) = self {
                return dict[key]
            }
            return nil
        }
        
        mutating set {
            if case .dictionaryValue(var dict) = self {
                dict[key] = newValue
                self = JSON.dictionaryValue(dict)
            }
        }
    }
    
    public subscript(dynamicMember member: String) -> JSON? {
        if case .dictionaryValue(let dict) = self {
            return dict[member]
        }
        return nil
    }
    
    static func createElementValueReference(_ value: Any) -> JSON {
        return JSON.elementValueReference(ElementValueReference(valueMethod: {
            String(describing: value)
        }, isComplete: true))
    }
}
