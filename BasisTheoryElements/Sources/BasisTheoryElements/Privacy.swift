import Foundation

public struct Privacy: Codable {
    public var classification: String?
    public var impactLevel: String?
    public var restrictionPolicy: String?
    
    public init(classification: String? = nil, impactLevel: String? = nil, restrictionPolicy: String? = nil) {
        self.classification = classification
        self.impactLevel = impactLevel
        self.restrictionPolicy = restrictionPolicy
    }
}
