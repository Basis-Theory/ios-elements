//
//  UpdateTokenTests.swift
//  IntegrationTesterTests
//

import XCTest
import BasisTheoryElements

final class UpdateTokenTests: XCTestCase {
    private final var TIMEOUT_EXPECTATION = 5.0

    override func setUpWithError() throws {
        BasisTheoryElements.basePath = "https://api.flock-dev.com"
    }

    override func tearDownWithError() throws {}

    func testUpdateTokenReturnsErrorFromApplicationCheck() throws {
        let body = UpdateToken(data: [
            "cvc": "123"
        ])

        let updateExpectation = self.expectation(description: "Update token")
        BasisTheoryElements.updateToken(id: "invalid-token-id", body: body, apiKey: "bad api key") { data, error in
            XCTAssertNil(data)
            XCTAssertNotNil(error)

            updateExpectation.fulfill()
        }

        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }

    func testUpdateTokenWithElementRef() throws {
        let btApiKey = Configuration.getConfiguration().btApiKey!

        // First create a token to update
        let createExpectation = self.expectation(description: "Create token")
        var tokenId: String?

        let createBody = CreateToken(type: "card", data: [
            "number": "4242424242424242",
            "expiration_month": 12,
            "expiration_year": 2026,
            "cvc": "123"
        ])

        BasisTheoryElements.createToken(body: createBody, apiKey: btApiKey) { data, error in
            XCTAssertNil(error)
            XCTAssertNotNil(data?.id)
            tokenId = data?.id
            createExpectation.fulfill()
        }

        waitForExpectations(timeout: TIMEOUT_EXPECTATION)

        guard let id = tokenId else {
            XCTFail("Failed to create token for update test")
            return
        }

        // Now update the token with new CVC
        let updateExpectation = self.expectation(description: "Update token")

        let updateBody = UpdateToken(data: [
            "cvc": "456"
        ])

        BasisTheoryElements.updateToken(id: id, body: updateBody, apiKey: btApiKey) { data, error in
            XCTAssertNil(error)
            XCTAssertNotNil(data)
            XCTAssertEqual(data?.id, id)

            updateExpectation.fulfill()
        }

        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }

    func testUpdateTokenWithInvalidId() throws {
        let btApiKey = Configuration.getConfiguration().btApiKey!

        let updateExpectation = self.expectation(description: "Update token with invalid id")

        let updateBody = UpdateToken(data: [
            "cvc": "456"
        ])

        BasisTheoryElements.updateToken(id: "nonexistent-token-id", body: updateBody, apiKey: btApiKey) { data, error in
            XCTAssertNil(data)
            XCTAssertNotNil(error)

            updateExpectation.fulfill()
        }

        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
}
