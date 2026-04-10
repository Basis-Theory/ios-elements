import Foundation
import AnyCodable

internal struct CreateTokenRequest: Codable {
    var id: String?
    var type: String?
    var data: AnyCodable?
    var encryption: EncryptionMetadata?
    var privacy: Privacy?
    var metadata: [String: String]?
    var searchIndexes: [String]?
    var fingerprintExpression: String?
    var mask: AnyCodable?
    var deduplicateToken: Bool?
    var expiresAt: String?
    var containers: [String]?
}
