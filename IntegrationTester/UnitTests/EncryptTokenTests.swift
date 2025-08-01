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

        let encryptTokenRequest = EncryptTokenRequest(tokenRequests: cardTokenRequest, publicKey: publicKey, keyId: keyId)

        let encryptResponse = try BasisTheoryElements.encryptToken(input: encryptTokenRequest)
    
        print(encryptResponse)
        
        // Verify single token response with structured type
        switch encryptResponse {
        case .single(let encryptedToken):
            XCTAssertEqual(encryptedToken.type, "card")
            XCTAssertFalse(encryptedToken.encrypted.isEmpty)
            XCTAssertTrue(encryptedToken.encrypted.contains(".")) // Should contain JWE separators
            
        case .multiple(_):
            XCTFail("Expected single token response")
        }
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

        let encryptTokenRequest = EncryptTokenRequest(tokenRequests: multipleTokenRequests, publicKey: publicKey, keyId: keyId)

        let encryptResponse = try BasisTheoryElements.encryptToken(input: encryptTokenRequest)

        // Verify multiple token response with structured types
        switch encryptResponse {
        case .single(_):
            XCTFail("Expected multiple token response")
            
        case .multiple(let encryptedTokens):
            XCTAssertEqual(encryptedTokens.count, 3)
            
            // Check each token with structured type
            for (tokenName, encryptedToken) in encryptedTokens {
                XCTAssertFalse(encryptedToken.encrypted.isEmpty)
                XCTAssertTrue(encryptedToken.encrypted.contains(".")) // Should contain JWE separators
                
                // Verify token names and types
                switch tokenName {
                case "creditCard":
                    XCTAssertEqual(encryptedToken.type, "card")
                case "bankAccount":
                    XCTAssertEqual(encryptedToken.type, "bank")
                case "personalInfo":
                    XCTAssertEqual(encryptedToken.type, "token")
                default:
                    XCTFail("Unexpected token name: \(tokenName)")
                }
            }
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
        let encryptTokenRequest = EncryptTokenRequest(tokenRequests: cardTokenRequest, publicKey: "invalid-key", keyId: keyId)

        XCTAssertThrowsError(try BasisTheoryElements.encryptToken(input: encryptTokenRequest)) { error in
            XCTAssertEqual(error as? JWEEncryption.JWEError, JWEEncryption.JWEError.invalidPublicKey)
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
        let encryptTokenRequest = EncryptTokenRequest(tokenRequests: cardTokenRequest, publicKey: "", keyId: keyId)

        XCTAssertThrowsError(try BasisTheoryElements.encryptToken(input: encryptTokenRequest)) { error in
            XCTAssertEqual(error as? JWEEncryption.JWEError, JWEEncryption.JWEError.invalidPublicKey)
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
        let encryptTokenRequest = EncryptTokenRequest(tokenRequests: cardTokenRequest, publicKey: publicKey, keyId: "")

         XCTAssertThrowsError(try BasisTheoryElements.encryptToken(input: encryptTokenRequest)) { error in
            XCTAssertEqual(error as? JWEEncryption.JWEError, JWEEncryption.JWEError.invalidKeyId)
        }
    }
    
    func testEncryptTokenWithMissingType() throws {
        let tokenRequestWithoutType: [String: Any] = [
            "data": [
                "number": "4242424242424242"
            ]
            // Missing "type" field
        ]

        let encryptTokenRequest = EncryptTokenRequest(tokenRequests: tokenRequestWithoutType, publicKey: publicKey, keyId: keyId)

        XCTAssertThrowsError(try BasisTheoryElements.encryptToken(input: encryptTokenRequest)) { error in
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

        let encryptTokenRequest = EncryptTokenRequest(tokenRequests: tokenRequestWithoutData, publicKey: publicKey, keyId: keyId)

        XCTAssertThrowsError(try BasisTheoryElements.encryptToken(input: encryptTokenRequest)) { error in
            XCTAssertTrue(error is TokenizingError)
            if case TokenizingError.invalidInput = error {
                // Expected error
            } else {
                XCTFail("Expected TokenizingError.invalidInput")
            }
        }
    }
    
}
