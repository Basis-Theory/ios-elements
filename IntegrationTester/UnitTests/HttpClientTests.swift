//
//  HttpClientTests.swift
//  UnitTests
//
//  Created by Brian Gonzalez on 6/20/23.
//

import XCTest
import BasisTheoryElements

final class HttpClientTests: XCTestCase {
    private final var TIMEOUT_EXPECTATION = 5.0
    
    override func setUpWithError() throws { }
    
    override func tearDownWithError() throws { }
    
    func testPostRequest() throws {
        let textElement = TextElementUITextField()
        textElement.insertText("test element value")
        
        let payload = [
            "textElementProp": textElement,
            "plainTextProp": "plaintext value",
            "object" : [
                "nestedProp": "nested value"
            ],
            "array": [1, 2, 3]
        ] as [String : Any]
        let config = Config(headers: [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "X-Test-Header": "test header value"
        ])
        
        let postHttpClientExpectation = self.expectation(description: "POST HTTP client")
        BasisTheoryElements.post(url: "https://echo.basistheory.com/anything", payload: payload, config: config) { request, data, error in
            XCTAssertNil(error)
            XCTAssertEqual(data?.json?.textElementProp?.rawValue as! String, "test element value")
            XCTAssertEqual(data?.json?.plainTextProp?.rawValue as! String, "plaintext value")
            XCTAssertEqual(data?.json?.object?.nestedProp?.rawValue as! String, "nested value")
            XCTAssertEqual(data?.json?.array?[0]?.rawValue as! Int, 1)
            XCTAssertEqual(data?.json?.array?[1]?.rawValue as! Int, 2)
            XCTAssertEqual(data?.json?.array?[2]?.rawValue as! Int, 3)
            XCTAssertEqual(data?.method?.rawValue as! String, "POST")
            XCTAssertEqual(data?.headers?["X-Test-Header"]?.rawValue as! String, "test header value")
            
            postHttpClientExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
    
    func testPostRequest_WithFormUrlEncodedContentType() throws {
        let textElement = TextElementUITextField()
        textElement.insertText("test element value")
        
        let payload = [
            "textElementProp": textElement,
            "object" : [
                "nestedProp": "nested value"
            ],
            "array": [1, 2, 3]
        ] as [String : Any]
        
        let config = Config(headers: [
            "Content-Type": "application/x-www-form-urlencoded",
        ])
        
        let postHttpClientExpectation = self.expectation(description: "POST HTTP client")
        BasisTheoryElements.post(url: "https://echo.basistheory.com/anything", payload: payload, config: config) { request, data, error in
            XCTAssertNil(error)
            
            func getRawValueFromForm(field: String) -> String {
                return data?.form?[field]?.rawValue as! String
            }
            
            XCTAssertNil(error)
        
            XCTAssertEqual(getRawValueFromForm(field: "textElementProp"), "test element value")
            XCTAssertEqual(getRawValueFromForm(field: "object[nestedProp]"), "nested value")
            XCTAssertEqual(getRawValueFromForm(field: "array[0]"), "1")
            XCTAssertEqual(getRawValueFromForm(field: "array[1]"), "2")
            XCTAssertEqual(getRawValueFromForm(field: "array[2]"), "3")
            
            postHttpClientExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
    
    
    func testPutRequest() throws {
        let textElement = TextElementUITextField()
        textElement.insertText("test element value")
        
        let payload = [
            "textElementProp": textElement,
            "plainTextProp": "plaintext value",
            "object" : [
                "nestedProp": "nested value"
            ],
            "array": [1, 2, 3]
        ] as [String : Any]
        let config = Config(headers: [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "X-Test-Header": "test header value"
        ])
        
        let putHttpClientExpectation = self.expectation(description: "PUT HTTP client")
        BasisTheoryElements.put(url: "https://echo.basistheory.com/anything", payload: payload, config: config) { request, data, error in
            XCTAssertNil(error)
            XCTAssertEqual(data?.json?.textElementProp?.rawValue as! String, "test element value")
            XCTAssertEqual(data?.json?.plainTextProp?.rawValue as! String, "plaintext value")
            XCTAssertEqual(data?.json?.object?.nestedProp?.rawValue as! String, "nested value")
            XCTAssertEqual(data?.json?.array?[0]?.rawValue as! Int, 1)
            XCTAssertEqual(data?.json?.array?[1]?.rawValue as! Int, 2)
            XCTAssertEqual(data?.json?.array?[2]?.rawValue as! Int, 3)
            XCTAssertEqual(data?.method?.rawValue as! String, "PUT")
            XCTAssertEqual(data?.headers?["X-Test-Header"]?.rawValue as! String, "test header value")
            
            putHttpClientExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
    
    func testPatchRequest() throws {
        let textElement = TextElementUITextField()
        textElement.insertText("test element value")
        
        let payload = [
            "textElementProp": textElement,
            "plainTextProp": "plaintext value",
            "object" : [
                "nestedProp": "nested value"
            ],
            "array": [1, 2, 3]
        ] as [String : Any]
        let config = Config(headers: [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "X-Test-Header": "test header value"
        ])
        
        let patchHttpClientExpectation = self.expectation(description: "PATCH HTTP client")
        BasisTheoryElements.patch(url: "https://echo.basistheory.com/anything", payload: payload, config: config) { request, data, error in
            XCTAssertNil(error)
            XCTAssertEqual(data?.json?.textElementProp?.rawValue as! String, "test element value")
            XCTAssertEqual(data?.json?.plainTextProp?.rawValue as! String, "plaintext value")
            XCTAssertEqual(data?.json?.object?.nestedProp?.rawValue as! String, "nested value")
            XCTAssertEqual(data?.json?.array?[0]?.rawValue as! Int, 1)
            XCTAssertEqual(data?.json?.array?[1]?.rawValue as! Int, 2)
            XCTAssertEqual(data?.json?.array?[2]?.rawValue as! Int, 3)
            XCTAssertEqual(data?.method?.rawValue as! String, "PATCH")
            XCTAssertEqual(data?.headers?["X-Test-Header"]?.rawValue as! String, "test header value")
            
            patchHttpClientExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
    
    func testGetRequest() throws {
        let config = Config(headers: [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "X-Test-Header": "test header value"
        ])
        
        let getHttpClientExpectation = self.expectation(description: "GET HTTP client")
        BasisTheoryElements.get(url: "https://echo.basistheory.com/anything", config: config) { request, data, error in
            XCTAssertNil(error)
            XCTAssertEqual(data?.method?.rawValue as! String, "GET")
            XCTAssertEqual(data?.headers?["X-Test-Header"]?.rawValue as! String, "test header value")
            
            getHttpClientExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
    
    func testDeleteRequest() throws {
        let config = Config(headers: [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "X-Test-Header": "test header value"
        ])
        
        let deleteHttpClientExpectation = self.expectation(description: "DELETE HTTP client")
        BasisTheoryElements.delete(url: "https://echo.basistheory.com/anything", config: config) { request, data, error in
            XCTAssertNil(error)
            XCTAssertEqual(data?.method?.rawValue as! String, "DELETE")
            XCTAssertEqual(data?.headers?["X-Test-Header"]?.rawValue as! String, "test header value")
            
            deleteHttpClientExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
    
    func testPostRequestWithAnInvalidRequest() throws {
        let config = Config(headers: [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "X-Test-Header": "test header value"
        ])
        
        let getHttpClientExpectation = self.expectation(description: "GET HTTP client")
        BasisTheoryElements.get(url: "badproto://baddomain", config: config) { request, data, error in
            XCTAssertEqual(error as! HttpClientError, HttpClientError.invalidRequest)
            XCTAssertNil(request)
            XCTAssertNil(data)
            
            getHttpClientExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
    
    func testPostRequestWithAnInvalidURL() throws {
        let config = Config(headers: [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "X-Test-Header": "test header value"
        ])
        
        let getHttpClientExpectation = self.expectation(description: "GET HTTP client")
        BasisTheoryElements.get(url: "#$@$#!@#^*&*(()-=0__+badurl?!?!", config: config) { request, data, error in
            XCTAssertEqual(error as! HttpClientError, HttpClientError.invalidURL)
            XCTAssertNil(request)
            XCTAssertNil(data)
            
            getHttpClientExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
}
