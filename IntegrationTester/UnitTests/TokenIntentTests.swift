import BasisTheory
import BasisTheoryElements
import XCTest

final class TokenIntentTests: XCTestCase {
    private final var TIMEOUT_EXPECTATION = 5.0

    override func setUpWithError() throws {
        BasisTheoryAPI.basePath = "https://api.flock-dev.com"
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

  
}
