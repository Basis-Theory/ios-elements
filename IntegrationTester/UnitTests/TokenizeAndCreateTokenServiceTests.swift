//
//  ElementServiceTests.swift
//  IntegrationTesterTests
//
//  Created by Brian Gonzalez on 11/10/22.
//

import XCTest
import BasisTheoryElements

final class TokenizeAndCreateTokenServiceTests: XCTestCase {
    private final var TIMEOUT_EXPECTATION = 5.0
    
    override func setUpWithError() throws {
        BasisTheoryElements.basePath = "https://api.flock-dev.com"
    }
    
    override func tearDownWithError() throws { }
 
    func testTokenizeReturnsErrorFromApplicationCheck() throws {
        let body: [String: Any] = [
            "myProp": "myValue"
        ]
        
        let tokenizeExpectation = self.expectation(description: "Tokenize")
        BasisTheoryElements.tokenize(body: body, apiKey: "bad api key") { data, error in
            XCTAssertNil(data)
            XCTAssertNotNil(error)
            
            tokenizeExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }

    func testCreateReturnsErrorFromApplicationCheck() throws {
        let body = CreateToken(type: "token", data: [
            "myProp": "myValue"
        ])
        
        let tokenizeExpectation = self.expectation(description: "Tokenize")
        BasisTheoryElements.createToken(body: body, apiKey: "bad api key") { data, error in
            XCTAssertNil(data)
            XCTAssertNotNil(error)
            
            tokenizeExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
}
