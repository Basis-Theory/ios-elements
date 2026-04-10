import Foundation

public struct AuthorizeSessionResponse: Codable {
    public var nonce: String?
    public var expiresAt: String?
    
    public init(nonce: String? = nil, expiresAt: String? = nil) {
        self.nonce = nonce
        self.expiresAt = expiresAt
    }
}
