import Foundation
import AnyCodable

internal struct UpdateTokenRequest: Codable {
    var data: AnyCodable?
    var privacy: Privacy?
    var metadata: [String: String]?
    var searchIndexes: [String]?
    var fingerprintExpression: String?
    var mask: AnyCodable?
    var deduplicateToken: Bool?
    var expiresAt: String?
    var containers: [String]?
}
