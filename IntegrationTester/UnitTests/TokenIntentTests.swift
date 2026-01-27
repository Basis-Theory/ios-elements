import BasisTheoryElements
import XCTest

final class TokenIntentTests: XCTestCase {
    private final var TIMEOUT_EXPECTATION = 5.0

    override func setUpWithError() throws {
        BasisTheoryElements.basePath = "https://api.flock-dev.com"
    }

    override func tearDownWithError() throws {}
    
    
    func testCreatingATokenIntent() throws {
        let btApiKey = Configuration.getConfiguration().btApiKey!
        
        let createTokenIntentExpectation = self.expectation(description: "Create token intent")
        
        let data: [String: Any] = [
            "number": "4242424242424242",
            "expiration_month": 12,
            "expiration_year": 2026,
            "cvc": "123"
        ]
        
        let req = CreateTokenIntentRequest(type: "card", data: data)
        
        BasisTheoryElements.createTokenIntent(request: req, apiKey: btApiKey) { data, error in
            XCTAssertNil(error)
            XCTAssertNotNil(data?.id)
            XCTAssertEqual(data?.card?.brand, "visa")
            XCTAssertEqual(data?.card?.last4, "4242")
            XCTAssertNotNil(data?.expiresAt)
            
            createTokenIntentExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
    
    func testDeletingTokenIntent() throws {
        let btApiKey = Configuration.getConfiguration().btApiKey!
        
        let createTokenIntentExpectation = self.expectation(description: "Create token intent for deletion")
        let deleteTokenIntentExpectation = self.expectation(description: "Delete token intent")
        
        let data: [String: Any] = [
            "number": "4242424242424242",
            "expiration_month": 12,
            "expiration_year": 2026,
            "cvc": "123"
        ]
        
        let req = CreateTokenIntentRequest(type: "card", data: data)
        var createdTokenIntentId: String?
        
        // First create a token intent
        BasisTheoryElements.createTokenIntent(request: req, apiKey: btApiKey) { data, error in
            XCTAssertNil(error)
            XCTAssertNotNil(data?.id)
            createdTokenIntentId = data?.id
            
            createTokenIntentExpectation.fulfill()
            
            // Then delete it
            if let tokenIntentId = createdTokenIntentId {
                let privateBtApiKey = Configuration.getConfiguration().privateBtApiKey!
                BasisTheoryElements.deleteTokenIntent(id: tokenIntentId, apiKey: privateBtApiKey) { error in
                    // Token intents may be auto-deleted or expired, so 404 is acceptable
                    if let error = error {
                        let nsError = error as NSError
                        if nsError.code == 404 {
                            // Token intent was already deleted/expired - this is expected behavior
                            deleteTokenIntentExpectation.fulfill()
                        } else {
                            XCTFail("Delete token intent failed with unexpected error: \(error)")
                            deleteTokenIntentExpectation.fulfill()
                        }
                    } else {
                        // Successfully deleted
                        deleteTokenIntentExpectation.fulfill()
                    }
                }
            }
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
    
    func testDeletingTokenIntentWithEmptyId() throws {
        let privateBtApiKey = Configuration.getConfiguration().privateBtApiKey!
        
        let deleteTokenIntentExpectation = self.expectation(description: "Delete token intent with empty ID should fail")
        
        BasisTheoryElements.deleteTokenIntent(id: "", apiKey: privateBtApiKey) { error in
            XCTAssertNotNil(error, "Delete token intent should fail with empty ID")
            deleteTokenIntentExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
    
    func testDeletingNonExistentTokenIntent() throws {
        let privateBtApiKey = Configuration.getConfiguration().privateBtApiKey!
        
        let deleteTokenIntentExpectation = self.expectation(description: "Delete non-existent token intent should fail")
        
        BasisTheoryElements.deleteTokenIntent(id: "non-existent-id", apiKey: privateBtApiKey) { error in
            XCTAssertNotNil(error, "Delete token intent should fail for non-existent ID")
            deleteTokenIntentExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
    
    @available(iOS 13.0, *)
    func testTokenIntentAsyncMethods() throws {
        let btApiKey = Configuration.getConfiguration().btApiKey!
        
        let asyncExpectation = self.expectation(description: "Async token intent methods")
        
        Task {
            do {
                // Create token intent async
                let data: [String: Any] = [
                    "number": "4000000000000002",
                    "expiration_month": 12,
                    "expiration_year": 2026,
                    "cvc": "123"
                ]
                
                let req = CreateTokenIntentRequest(type: "card", data: data)
                let tokenIntent = try await BasisTheoryElements.createTokenIntent(request: req, apiKey: btApiKey)
                
                XCTAssertNotNil(tokenIntent.id)
                XCTAssertEqual(tokenIntent.type, "card")
                
                // Delete token intent async
                let privateBtApiKey = Configuration.getConfiguration().privateBtApiKey!
                do {
                    try await BasisTheoryElements.deleteTokenIntent(id: tokenIntent.id, apiKey: privateBtApiKey)
                } catch {
                    let nsError = error as NSError
                    if nsError.code == 404 {
                        // Token intent was already deleted/expired - this is expected behavior
                    } else {
                        throw error
                    }
                }
                
                asyncExpectation.fulfill()
            } catch {
                XCTFail("Async token intent operations failed: \(error)")
                asyncExpectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }

  
}
