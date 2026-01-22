//
//  GetTokenByIdServiceTests.swift
//  UnitTests
//
//  Created by Brian Gonzalez on 1/19/23.
//

import Foundation
import XCTest
import BasisTheoryElements

final class GetTokenByIdServiceTests: XCTestCase {
    private var sessionApiKey: String = ""
    private var createdToken: CreateTokenResponse? = nil
    private final var MY_PROP_NAME: String = "myProp"
    private final var MY_PROP_VALUE: String = "myValue"
    private final var TIMEOUT_EXPECTATION = 3.0
    
    override func setUpWithError() throws {
        BasisTheoryElements.basePath = "https://api.flock-dev.com"
        
        let btApiKey = Configuration.getConfiguration().btApiKey!
        let privateBtApiKey = Configuration.getConfiguration().privateBtApiKey!
        
        let tokenizeExpectation = self.expectation(description: "Create token")
        let body = CreateToken(type: "token", data: [
            MY_PROP_NAME: MY_PROP_VALUE
        ])
        BasisTheoryElements.createToken(body: body, apiKey: btApiKey) { data, error in
            self.createdToken = data
            tokenizeExpectation.fulfill()
        }
        
        var nonce: String = ""
        let createSessionExpectation = self.expectation(description: "Create session")
        BasisTheoryElements.createSession(apiKey: btApiKey) { data, error in
            self.sessionApiKey = data!.sessionKey!
            nonce = data!.nonce!
            createSessionExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
        
        let accessRule = AccessRule(description: "GetTokenById iOS Test", priority: 1, transform: "reveal", conditions: [Condition(attribute: "id", _operator: "equals", value: self.createdToken!.id)], permissions: ["token:read"])
        let authorizeSessionExpectation = self.expectation(description: "Authorize session")
        BasisTheoryElements.authorizeSession(nonce: nonce, rules: [accessRule], apiKey: privateBtApiKey) { data, error in
            if let data = data {
                authorizeSessionExpectation.fulfill()
            } else if let error = error {
                print(error)
            }
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
    
    override func tearDownWithError() throws { }
    
    func testGettingATokenById() throws {
        let getTokenByIdExpectation = self.expectation(description: "Get by id")
        BasisTheoryElements.getTokenById(id: self.createdToken!.id!, apiKey: self.sessionApiKey) { data, error in
            XCTAssertNil(error)
            XCTAssertNotNil(data!.id)
            XCTAssertNotNil(data!.data!.myProp!.elementValueReference)
            
            getTokenByIdExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
    
    func testRetrievedTokenIsSettableOnElement() throws {
        let textField = TextElementUITextField()
        
        var tokenDataResponse: ElementValueReference? = nil
        let getTokenByIdExpectation = self.expectation(description: "Get by id")
        BasisTheoryElements.getTokenById(id: self.createdToken!.id!, apiKey: self.sessionApiKey) { data, error in
            XCTAssertNil(error)
            XCTAssertNotNil(data)
            
            tokenDataResponse = data!.data!.myProp!.elementValueReference
            
            getTokenByIdExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
        
        textField.setValue(elementValueReference: tokenDataResponse)
        
        let body: CreateToken = CreateToken(type: "token", data: [
            "textFieldRef": textField,
        ])
        let tokenizeExpectation = self.expectation(description: "Create Token")
        var createdToken: CreateTokenResponse? = nil
        let btApiKey = Configuration.getConfiguration().btApiKey!
        BasisTheoryElements.createToken(body: body, apiKey: btApiKey) { data, error in
            createdToken = data

            XCTAssertNotNil(createdToken!.id)
            XCTAssertEqual(createdToken!.type!, "token")
            
            tokenizeExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
        
        let idQueryExpectation = self.expectation(description: "Token ID Query")
        let privateApiKey = Configuration.getConfiguration().privateBtApiKey!
        BasisTheoryElements.getTokenById(id: createdToken!.id!, apiKey: privateApiKey) { data, error in
            if let data = data {
                let token = data.data!.value as! [String: Any]

                XCTAssertEqual(token["textFieldRef"] as! String, self.MY_PROP_VALUE)

                idQueryExpectation.fulfill()
            } else if let error = error {
                print(error)
            }
        }

        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
}
