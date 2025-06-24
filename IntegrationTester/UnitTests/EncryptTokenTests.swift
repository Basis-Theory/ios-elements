import Foundation

import XCTest
import BasisTheory
import BasisTheoryElements
import Combine

final class JWEEncryptionTests: XCTestCase {
    
    private let publicKey = "-----BEGIN PUBLIC KEY-----\n9n4FlhKXk6FL1VIOJD0l8iXEb317zge+Uc5B53AwWj0=\n-----END PUBLIC KEY-----"
    private let keyId = "3add6cc6-84eb-44f0-a891-bf4fc25bb9e5"

    func testEncryptCardToken() throws {
        let cardTokenRequest: [String: Any] = [
            "type": "card",
            "data": [
                "number": "4242424242424242",
                "expiration_month": "01",
                "expiration_year": "2030",
                "cvc": "123"
            ]
        ]

        let encryptTokenRequest = EncryptToken(tokenRequests: cardTokenRequest, publicKey: publicKey, keyId: keyId)

        let encryptResponse = try BasisTheoryElements.encryptToken(encryptToken: encryptTokenRequest)

        XCTAssertEqual(encryptResponse.count, 1)
        XCTAssertEqual(encryptResponse[0].type, "card")
        XCTAssertFalse(encryptResponse[0].encrypted.isEmpty)
        
        print(encryptResponse)

    }
    
}
