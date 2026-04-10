//
//  UpdateToken.swift
//
//
//  Created by Cascade on 02/11/26.
//

import AnyCodable

public struct UpdateToken {
    public var data: [String: Any]
    public var privacy: Privacy?
    public var metadata: [String: String]?
    public var searchIndexes: [String]?
    public var fingerprintExpression: String?
    public var mask: String?
    public var deduplicateToken: Bool?
    public var expiresAt: String?
    public var containers: [String]?

    public init(data: [String: Any], privacy: Privacy? = nil, metadata: [String: String]? = nil, searchIndexes: [String]? = nil, fingerprintExpression: String? = nil, mask: String? = nil, deduplicateToken: Bool? = nil, expiresAt: String? = nil, containers: [String]? = nil) {
        self.data = data
        self.privacy = privacy
        self.metadata = metadata
        self.searchIndexes = searchIndexes
        self.fingerprintExpression = fingerprintExpression
        self.mask = mask
        self.deduplicateToken = deduplicateToken
        self.expiresAt = expiresAt
        self.containers = containers
    }

    func toUpdateTokenRequest() -> UpdateTokenRequest {
        UpdateTokenRequest(
            data: AnyCodable(self.data),
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
