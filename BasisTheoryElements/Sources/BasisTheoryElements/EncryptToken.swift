import Foundation

public struct EncryptToken {
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
    
    /// Get the token requests as a dictionary for processing
    /// - Returns: Dictionary representation of token requests
    public func getTokenRequestsAsDictionary() -> [String: Any] {
        switch tokenRequests {
        case .single(let singleRequest):
            return singleRequest
        case .multiple(let multipleRequests):
            return multipleRequests
        }
    }
    
    /// Check if this is a single token request
    /// - Returns: True if single token request, false if multiple
    public var isSingleTokenRequest: Bool {
        switch tokenRequests {
        case .single:
            return true
        case .multiple:
            return false
        }
    }
    
    /// Get the single token request (only valid if isSingleTokenRequest is true)
    /// - Returns: Single token request dictionary or nil
    public var singleTokenRequest: [String: Any]? {
        switch tokenRequests {
        case .single(let request):
            return request
        case .multiple:
            return nil
        }
    }
    
    /// Get the multiple token requests (only valid if isSingleTokenRequest is false)
    /// - Returns: Multiple token requests dictionary or nil
    public var multipleTokenRequests: [String: [String: Any]]? {
        switch tokenRequests {
        case .single:
            return nil
        case .multiple(let requests):
            return requests
        }
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