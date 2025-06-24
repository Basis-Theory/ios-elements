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
    }
    
    func testEncryptMultipleTokens() throws {
        let multipleTokenRequests: [String: [String: Any]] = [
            "creditCard": [
                "type": "card",
                "data": [
                    "number": "4242424242424242",
                    "expiration_month": "01",
                    "expiration_year": "2030",
                    "cvc": "123"
                ]
            ],
            "bankAccount": [
                "type": "bank",
                "data": [
                    "routing_number": "021000021",
                    "account_number": "1234567890"
                ]
            ],
            "personalInfo": [
                "type": "token",
                "data": [
                    "name": "John Doe",
                    "email": "john@example.com"
                ]
            ]
        ]

        let encryptTokenRequest = EncryptToken(tokenRequests: multipleTokenRequests, publicKey: publicKey, keyId: keyId)

        let encryptResponse = try BasisTheoryElements.encryptToken(encryptToken: encryptTokenRequest)

        XCTAssertEqual(encryptResponse.count, 3)
        
        // Verify all responses have encrypted data and correct types
        let types = Set(encryptResponse.map { $0.type })
        XCTAssertEqual(types, Set(["card", "bank", "token"]))
        
        for response in encryptResponse {
            XCTAssertFalse(response.encrypted.isEmpty)
            XCTAssertTrue(response.encrypted.contains(".")) // Should contain JWE separators
        }
    }
    
    func testEncryptTokenWithInvalidPublicKey() throws {
        let cardTokenRequest: [String: Any] = [
            "type": "card",
            "data": [
                "number": "4242424242424242"
            ]
        ]

        // Test with invalid base64 public key
        let encryptTokenRequest = EncryptToken(tokenRequests: cardTokenRequest, publicKey: "invalid-key", keyId: keyId)

        XCTAssertThrowsError(try BasisTheoryElements.encryptToken(encryptToken: encryptTokenRequest)) { error in
            XCTAssertEqual(error as? JWEEncryption.JWKError, JWEEncryption.JWKError.invalidPublicKey)
        }
    }
    
    func testEncryptTokenWithEmptyPublicKey() throws {
        let cardTokenRequest: [String: Any] = [
            "type": "card",
            "data": [
                "number": "4242424242424242"
            ]
        ]

        // Test with empty public key
        let encryptTokenRequest = EncryptToken(tokenRequests: cardTokenRequest, publicKey: "", keyId: keyId)

        XCTAssertThrowsError(try BasisTheoryElements.encryptToken(encryptToken: encryptTokenRequest)) { error in
            XCTAssertEqual(error as? JWEEncryption.JWKError, JWEEncryption.JWKError.invalidPublicKey)
        }
    }
    
    func testEncryptTokenWithEmptyKeyId() throws {
        let cardTokenRequest: [String: Any] = [
            "type": "card",
            "data": [
                "number": "4242424242424242"
            ]
        ]

        // Test with empty keyId - should still work but with empty keyId in header
        let encryptTokenRequest = EncryptToken(tokenRequests: cardTokenRequest, publicKey: publicKey, keyId: "")

         XCTAssertThrowsError(try BasisTheoryElements.encryptToken(encryptToken: encryptTokenRequest)) { error in
            XCTAssertEqual(error as? JWEEncryption.JWKError, JWEEncryption.JWKError.invalidKeyId)
        }
    }
    
    func testEncryptTokenWithMissingType() throws {
        let tokenRequestWithoutType: [String: Any] = [
            "data": [
                "number": "4242424242424242"
            ]
            // Missing "type" field
        ]

        let encryptTokenRequest = EncryptToken(tokenRequests: tokenRequestWithoutType, publicKey: publicKey, keyId: keyId)

        XCTAssertThrowsError(try BasisTheoryElements.encryptToken(encryptToken: encryptTokenRequest)) { error in
            XCTAssertTrue(error is TokenizingError)
            if case TokenizingError.invalidInput = error {
                // Expected error
            } else {
                XCTFail("Expected TokenizingError.invalidInput")
            }
        }
    }
    
    func testEncryptTokenWithMissingData() throws {
        let tokenRequestWithoutData: [String: Any] = [
            "type": "card"
            // Missing "data" field
        ]

        let encryptTokenRequest = EncryptToken(tokenRequests: tokenRequestWithoutData, publicKey: publicKey, keyId: keyId)

        XCTAssertThrowsError(try BasisTheoryElements.encryptToken(encryptToken: encryptTokenRequest)) { error in
            XCTAssertTrue(error is TokenizingError)
            if case TokenizingError.invalidInput = error {
                // Expected error
            } else {
                XCTFail("Expected TokenizingError.invalidInput")
            }
        }
    }
    
}
