import Foundation

import XCTest
import BasisTheory
import BasisTheoryElements
import Combine

final class JWEEncryptionTests: XCTestCase {
    
    private let publicKey = "UrkhPioARkSiA4XbiS8081KqAbdsPn78HyEz9H0t9l8="
    
    func testEncryption() throws {
        
        let testData = "Encrypted Text!".data(using: .utf8)!
        
        let encryptedString = try JWEEncryption.encrypt(
            data: testData,
            recipientPublicKey: JWEEncryption.createJWK(from: publicKey)
        )
        
        // Verify the encrypted string is not empty and different from original
        XCTAssertFalse(encryptedString.isEmpty)
        XCTAssertNotEqual(encryptedString, String(data: testData, encoding: .utf8))
        
    }
    
}
