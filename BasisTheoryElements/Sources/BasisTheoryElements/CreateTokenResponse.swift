import Foundation
import AnyCodable

public struct CreateTokenResponse: Codable {
    public var id: String?
    public var type: String?
    public var tenantId: String?
    public var data: AnyCodable?
    public var metadata: [String: String]?
    public var encryption: EncryptionMetadata?
    public var createdBy: String?
    public var createdAt: String?
    public var modifiedBy: String?
    public var modifiedAt: String?
    public var fingerprint: String?
    public var fingerprintExpression: String?
    public var mask: AnyCodable?
    public var privacy: Privacy?
    public var searchIndexes: [String]?
    public var expiresAt: String?
    public var containers: [String]?
}
