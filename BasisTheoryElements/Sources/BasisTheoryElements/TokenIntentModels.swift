import Foundation

public struct CreateTokenIntentRequest: Encodable {
    public var type: String
    public var data: [String: Any]

    public init(type: String, data: [String: Any]) {
        self.type = type
        self.data = data
    }

    private struct DynamicKey: CodingKey {
        var stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { nil }
        init?(intValue: Int) { nil }
    }

    private enum CodingKeys: String, CodingKey {
        case type, data
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        var dataContainer = container.nestedContainer(keyedBy: DynamicKey.self, forKey: .data)
        for (key, value) in data {
            guard let codingKey = DynamicKey(stringValue: key) else { continue }
            switch value {
            case let v as String:
                try dataContainer.encode(v, forKey: codingKey)
            case let v as Int:
                try dataContainer.encode(v, forKey: codingKey)
            case let v as Double:
                try dataContainer.encode(v, forKey: codingKey)
            case let v as Bool:
                try dataContainer.encode(v, forKey: codingKey)
            case let v as [String: Any]:
                var nestedContainer = dataContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: codingKey)
                for (nestedKey, nestedValue) in v {
                    guard let nestedCodingKey = DynamicKey(stringValue: nestedKey) else { continue }
                    switch nestedValue {
                    case let s as String:
                        try nestedContainer.encode(s, forKey: nestedCodingKey)
                    case let i as Int:
                        try nestedContainer.encode(i, forKey: nestedCodingKey)
                    case let d as Double:
                        try nestedContainer.encode(d, forKey: nestedCodingKey)
                    case let b as Bool:
                        try nestedContainer.encode(b, forKey: nestedCodingKey)
                    default:
                        throw EncodingError.invalidValue(
                            nestedValue,
                            EncodingError.Context(
                                codingPath: nestedContainer.codingPath,
                                debugDescription: "Unsupported nested dictionary value: \(Swift.type(of: nestedValue))"
                            )
                        )
                    }
                }
            case let v as [Any]:
                var nestedUnkeyed = dataContainer.nestedUnkeyedContainer(forKey: codingKey)
                for element in v {
                    switch element {
                    case let s as String:
                        try nestedUnkeyed.encode(s)
                    case let i as Int:
                        try nestedUnkeyed.encode(i)
                    case let d as Double:
                        try nestedUnkeyed.encode(d)
                    case let b as Bool:
                        try nestedUnkeyed.encode(b)
                    default:
                        throw EncodingError.invalidValue(
                            element,
                            EncodingError.Context(
                                codingPath: nestedUnkeyed.codingPath,
                                debugDescription: "Unsupported array element: \(Swift.type(of: element))"
                            )
                        )
                    }
                }
            default:
                throw EncodingError.invalidValue(
                    value,
                    EncodingError.Context(
                        codingPath: dataContainer.codingPath,
                        debugDescription: "Unsupported value type: \(Swift.type(of: value))"
                    )
                )
            }
        }
    }
}


// MARK: - Token Intent Response Models

public struct TokenIntent: Codable {
    public let id: String
    public let tenantId: String
    public let type: String
    public let card: CardDetails?
    public let bank: BankDetails?
    public let networkToken: CardDetails?
    public let authentication: AuthenticationDetails?
    public let fingerprint: String
    public let expiresAt: String
    public let createdBy: String
    public let createdAt: String
    public let extras: ExtrasObject?

    private enum CodingKeys: String, CodingKey {
        case id
        case tenantId = "tenant_id"
        case type
        case card
        case bank
        case networkToken = "network_token"
        case authentication
        case fingerprint
        case expiresAt = "expires_at"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case extras = "_extras"
    }
}

public struct CardDetails: Codable {
    public let bin: String?
    public let last4: String?
    public let expirationMonth: Int?
    public let expirationYear: Int?
    public let brand: String?
    public let funding: String?
    public let issuerCountry: IssuerCountry?
    public let authentication: String?

    private enum CodingKeys: String, CodingKey {
        case bin
        case last4
        case expirationMonth = "expiration_month"
        case expirationYear = "expiration_year"
        case brand
        case funding
        case issuerCountry = "issuer_country"
        case authentication
    }
}

public struct BankDetails: Codable {
    public let routingNumber: String?
    public let accountNumber: String?
    public let accountType: String?
    public let bankName: String?

    private enum CodingKeys: String, CodingKey {
        case routingNumber = "routing_number"
        case accountNumber = "account_number"
        case accountType = "account_type"
        case bankName = "bank_name"
    }
}

public struct IssuerCountry: Codable {
    public let alpha2: String?
    public let name: String?
    public let numeric: String?
}

public struct AuthenticationDetails: Codable {
    // Add authentication-specific fields as needed based on your requirements
    public let cryptogram: String?
    public let eci: String?

    private enum CodingKeys: String, CodingKey {
        case cryptogram
        case eci
    }
}

public struct ExtrasObject: Codable {
    public let networkTokenIds: [String]?

    private enum CodingKeys: String, CodingKey {
        case networkTokenIds = "network_token_ids"
    }
}
