import Foundation

internal struct AuthorizeSessionRequest: Codable {
    var nonce: String
    var expiresAt: String?
    var permissions: [String]?
    var rules: [AccessRule]?
    
    enum CodingKeys: String, CodingKey {
        case nonce
        case expiresAt = "expires_at"
        case permissions
        case rules
    }
    
    init(nonce: String, expiresAt: String? = nil, permissions: [String]? = nil, rules: [AccessRule]? = nil) {
        self.nonce = nonce
        self.expiresAt = expiresAt
        self.permissions = permissions
        self.rules = rules
    }
}
