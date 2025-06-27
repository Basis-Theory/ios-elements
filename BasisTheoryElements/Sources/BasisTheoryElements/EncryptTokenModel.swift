import Foundation

public struct EncryptTokenRequest {
    public let tokenRequests: TokenRequests
    public let publicKey: String
    public let keyId: String
    
    public enum TokenRequests {
        case single([String: Any])
        case multiple([String: [String: Any]])
    }
    
    /// Initializer for single token request format
    /// - Parameters:
    ///   - tokenRequests: Dictionary containing token data, type, etc.
    ///   - publicKey: Base64 encoded PEM file with public key
    ///   - keyId: Key identifier
    public init(
        tokenRequests: [String: Any],
        publicKey: String,
        keyId: String
    ) {
        self.tokenRequests = .single(tokenRequests)
        self.publicKey = publicKey
        self.keyId = keyId
    }
    
    /// Initializer for multiple token requests format
    /// - Parameters:
    ///   - tokenRequests: Dictionary where keys are token names and values are token request dictionaries
    ///   - publicKey: Base64 encoded PEM file with public key
    ///   - keyId: Key identifier
    public init(
        tokenRequests: [String: [String: Any]],
        publicKey: String,
        keyId: String
    ) {
        self.tokenRequests = .multiple(tokenRequests)
        self.publicKey = publicKey
        self.keyId = keyId
    }

}

public struct EncryptTokenResponse {
    public let encrypted: String
    public let type: String
    
    public init(encrypted: String, type: String) {
        self.encrypted = encrypted
        self.type = type
    }
} 
