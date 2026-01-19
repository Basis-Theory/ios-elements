//
//  CereateToken.swift
//  
//
//  Created by Amber Torres on 11/21/22.
//

import AnyCodable

public struct CreateToken {
    public var id: String?
    public var type: String?
    public var data: [String: Any]
    public var encryption: EncryptionMetadata?
    public var privacy: Privacy?
    public var metadata: [String: String]?
    public var searchIndexes: [String]?
    public var fingerprintExpression: String?
    public var mask: String?
    public var deduplicateToken: Bool?
    public var expiresAt: String?
    public var containers: [String]?
    
    public init(id: String? = nil, type: String? = nil, data: [String: Any], encryption: EncryptionMetadata? = nil, privacy: Privacy? = nil, metadata: [String: String]? = nil, searchIndexes: [String]? = nil, fingerprintExpression: String? = nil, mask: String? = nil, deduplicateToken: Bool? = nil, expiresAt: String? = nil, containers: [String]? = nil) {
        self.id = id
        self.type = type
        self.data = data
        self.encryption = encryption
        self.privacy = privacy
        self.metadata = metadata
        self.searchIndexes = searchIndexes
        self.fingerprintExpression = fingerprintExpression
        self.mask = mask
        self.deduplicateToken = deduplicateToken
        self.expiresAt = expiresAt
        self.containers = containers
    }
    
    func toCreateTokenRequest () -> CreateTokenRequest {
        CreateTokenRequest(
            id: self.id,
            type: self.type,
            data: AnyCodable(self.data),
            encryption: self.encryption,
            privacy: self.privacy,
            metadata: self.metadata,
            searchIndexes: self.searchIndexes,
            fingerprintExpression: self.fingerprintExpression,
            mask: AnyCodable(self.mask),
            deduplicateToken: self.deduplicateToken,
            expiresAt: self.expiresAt,
            containers: self.containers
        )
    }
}
