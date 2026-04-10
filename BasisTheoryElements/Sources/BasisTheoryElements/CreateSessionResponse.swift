import Foundation

public struct CreateSessionResponse: Codable {
    public var sessionKey: String?
    public var nonce: String?
    public var expiresAt: String?
    
    public init(sessionKey: String? = nil, nonce: String? = nil, expiresAt: String? = nil) {
        self.sessionKey = sessionKey
        self.nonce = nonce
        self.expiresAt = expiresAt
    }
}
