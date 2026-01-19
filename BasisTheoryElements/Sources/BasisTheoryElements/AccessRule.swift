import Foundation

public struct AccessRule: Codable {
    public var description: String?
    public var priority: Int?
    public var container: String?
    public var transform: String?
    public var conditions: [Condition]?
    public var permissions: [String]?

    public init(description: String? = nil, priority: Int? = nil, container: String? = nil, transform: String? = nil, conditions: [Condition]? = nil, permissions: [String]? = nil) {
        self.description = description
        self.priority = priority
        self.container = container
        self.transform = transform
        self.conditions = conditions
        self.permissions = permissions
    }
}

public struct Condition: Codable {
    public var attribute: String?
    public var _operator: String?
    public var value: String?
    
    enum CodingKeys: String, CodingKey {
        case attribute
        case _operator = "operator"
        case value
    }

    public init(attribute: String? = nil, _operator: String? = nil, value: String? = nil) {
        self.attribute = attribute
        self._operator = _operator
        self.value = value
    }
}
