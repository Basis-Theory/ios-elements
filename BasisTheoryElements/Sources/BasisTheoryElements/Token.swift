import Foundation
import AnyCodable

internal struct Token: Codable {
    private static let dateFormatter = ISO8601DateFormatter()
    
    var id: String?
    var type: String?
    var tenantId: String?
    var data: AnyCodable?
    var metadata: [String: String]?
    var encryption: EncryptionMetadata?
    var createdBy: String?
    var createdAt: String?
    var modifiedBy: String?
    var modifiedAt: String?
    var fingerprint: String?
    var fingerprintExpression: String?
    var mask: AnyCodable?
    var privacy: Privacy?
    var searchIndexes: [String]?
    var expiresAt: String?
    var containers: [String]?
    
    func toGetTokenByIdResponse(data: JSON) -> GetTokenByIdResponse {
        
        return GetTokenByIdResponse(
            id: self.id,
            type: self.type,
            tenantId: self.tenantId.flatMap { UUID(uuidString: $0) },
            data: data,
            metadata: self.metadata,
            encryption: self.encryption,
            createdBy: self.createdBy.flatMap { UUID(uuidString: $0) },
            createdAt: self.createdAt.flatMap { Self.dateFormatter.date(from: $0) },
            modifiedBy: self.modifiedBy.flatMap { UUID(uuidString: $0) },
            modifiedAt: self.modifiedAt.flatMap { Self.dateFormatter.date(from: $0) },
            fingerprint: self.fingerprint,
            fingerprintExpression: self.fingerprintExpression,
            mask: self.mask,
            privacy: self.privacy,
            searchIndexes: self.searchIndexes,
            expiresAt: self.expiresAt.flatMap { Self.dateFormatter.date(from: $0) },
            containers: self.containers
        )
    }
}
