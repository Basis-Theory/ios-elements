//
//  ProxyServiceTests.swift
//  UnitTests
//
//  Created by Brian Gonzalez on 12/28/22.
//

import XCTest
import BasisTheoryElements

final class ProxyServiceTests: XCTestCase {
    private final var TIMEOUT_EXPECTATION = 5.0
    
    override func setUpWithError() throws {
        BasisTheoryElements.basePath = "https://api.flock-dev.com"
    }
    
    override func tearDownWithError() throws { }
    
    func testProxyRequest() throws {
        let privateBtApiKey = Configuration.getConfiguration().privateBtApiKey!
        let publicApiKey = Configuration.getConfiguration().btApiKey!
        let proxyKey = Configuration.getConfiguration().proxyKey!
        let textField = TextElementUITextField()
        textField.insertText("testElementValue")
        
        let proxyExpectation = self.expectation(description: "Proxy")
        var proxyResponseData: JSON = JSON.dictionaryValue([:])
        let proxyHttpRequest = ProxyHttpRequest(method: .post, body: [
            "testProp": "testValue",
            "testElement": textField,
            "objProp": [
                "nestedTestProp": "nestedTestValue",
                "nestedElement": textField
            ]
        ])
        BasisTheoryElements.proxy(
            apiKey: privateBtApiKey,
            proxyKey: proxyKey,
            proxyHttpRequest: proxyHttpRequest)
        { response, data, error in
            XCTAssertNil(error)
            XCTAssertEqual(response?.url?.absoluteString, "https://api.flock-dev.com/proxy")
            
            let httpResponse = response as! HTTPURLResponse
            
            XCTAssertEqual(httpResponse.statusCode, 200)
            
            proxyResponseData = data!
            proxyExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
        
        let createTokenExpectation = self.expectation(description: "Create token")
        var createdToken: CreateTokenResponse? = nil
        let body = CreateToken(type: "token", data: [
            "proxyProperty": proxyResponseData.json?.testProp?.elementValueReference,
            "nestedProxyProperty": proxyResponseData.json?.objProp?.nestedTestProp?.elementValueReference,
            "proxyElementProperty": proxyResponseData.json?.testElement?.elementValueReference,
            "nestedProxyElementProperty": proxyResponseData.json?.objProp?.nestedElement?.elementValueReference,
        ])
        BasisTheoryElements.createToken(body: body, apiKey: publicApiKey) { data, error in
            XCTAssertNil(error)
            
            createdToken = data!
            
            XCTAssertNotNil(createdToken!.id)
            XCTAssertEqual(createdToken!.type, "token")
            
            createTokenExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
        
        let idQueryExpectation = self.expectation(description: "Token ID Query")
        BasisTheoryElements.getTokenById(id: createdToken!.id!, apiKey: privateBtApiKey) { data, error in
            let token = data!.data!.value as! [String: Any]
            
            XCTAssertEqual(token["proxyProperty"] as! String, "testValue")
            XCTAssertEqual(token["nestedProxyProperty"] as! String, "nestedTestValue")
            XCTAssertEqual(token["proxyElementProperty"] as! String, "testElementValue")
            XCTAssertEqual(token["nestedProxyElementProperty"] as! String, "testElementValue")
            
            idQueryExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
    
    func testProxyReturnsNilValuesFromResponse() throws {
        let privateBtApiKey = Configuration.getConfiguration().privateBtApiKey!
        let proxyKey = Configuration.getConfiguration().proxyKey!
        
        let proxyExpectation = self.expectation(description: "Proxy")
        var proxyResponseData: JSON = JSON.dictionaryValue([:])
        let proxyHttpRequest = ProxyHttpRequest(method: .post, body: [
            "testProp": "testValue",
            "objProp": [
                "nestedTestProp": "nestedTestValue"
            ]
        ])
        BasisTheoryElements.proxy(
            apiKey: privateBtApiKey,
            proxyKey: proxyKey,
            proxyHttpRequest: proxyHttpRequest)
        { response, data, error in
            XCTAssertNil(error)
            XCTAssertEqual(response?.url?.absoluteString, "https://api.flock-dev.com/proxy")
            
            let httpResponse = response as! HTTPURLResponse
            
            XCTAssertEqual(httpResponse.statusCode, 200)
            
            proxyResponseData = data!
            proxyExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
        
        XCTAssertNotNil(proxyResponseData.json?.testProp?.elementValueReference)
        XCTAssertNotNil(proxyResponseData.json?.objProp)
        XCTAssertNil(proxyResponseData.json?.objProp?.elementValueReference)
        XCTAssertNotNil(proxyResponseData.json?.objProp?.nestedTestProp?.elementValueReference)
    }
    
    func testProxyWithArrayInBody() {
        let privateBtApiKey = Configuration.getConfiguration().privateBtApiKey!
        let publicApiKey = Configuration.getConfiguration().btApiKey!
        let proxyKey = Configuration.getConfiguration().proxyKey!
        
        let proxyExpectation = self.expectation(description: "Proxy")
        var proxyResponseData: JSON = JSON.dictionaryValue([:])
        let proxyHttpRequest = ProxyHttpRequest(method: .post, body: [
            "testProp": [1, 2, 3],
        ])
        BasisTheoryElements.proxy(
            apiKey: privateBtApiKey,
            proxyKey: proxyKey,
            proxyHttpRequest: proxyHttpRequest)
        { response, data, error in
            XCTAssertNil(error)
            XCTAssertEqual(response?.url?.absoluteString, "https://api.flock-dev.com/proxy")
            
            let httpResponse = response as! HTTPURLResponse
            
            XCTAssertEqual(httpResponse.statusCode, 200)
            
            proxyResponseData = data!
            proxyExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
        
        let createTokenExpectation = self.expectation(description: "Create token")
        var createdToken: CreateTokenResponse? = nil
        let body = CreateToken(type: "token", data: [
            "proxyProperty1": proxyResponseData.json?.testProp?[0]?.elementValueReference,
            "proxyProperty2": proxyResponseData.json?.testProp?[1]?.elementValueReference,
            "proxyProperty3": proxyResponseData.json?.testProp?[2]?.elementValueReference,
        ])
        BasisTheoryElements.createToken(body: body, apiKey: publicApiKey) { data, error in
            XCTAssertNil(error)
            
            createdToken = data!
            
            XCTAssertNotNil(createdToken!.id)
            XCTAssertEqual(createdToken!.type, "token")
            
            createTokenExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
        
        let idQueryExpectation = self.expectation(description: "Token ID Query")
        BasisTheoryElements.getTokenById(id: createdToken!.id!, apiKey: privateBtApiKey) { data, error in
            let token = data!.data!.value as! [String: Any]
            
            XCTAssertEqual(token["proxyProperty1"] as! String, "1")
            XCTAssertEqual(token["proxyProperty2"] as! String, "2")
            XCTAssertEqual(token["proxyProperty3"] as! String, "3")
            
            idQueryExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
    
    func testProxyWithoutABody() {
        let privateBtApiKey = Configuration.getConfiguration().privateBtApiKey!
        let proxyKey = Configuration.getConfiguration().proxyKey!
        
        let proxyExpectation = self.expectation(description: "Proxy")
        let proxyHttpRequest = ProxyHttpRequest(method: .post)
        BasisTheoryElements.proxy(
            apiKey: privateBtApiKey,
            proxyKey: proxyKey,
            proxyHttpRequest: proxyHttpRequest)
        { response, data, error in
            XCTAssertNil(error)
            XCTAssertEqual(response?.url?.absoluteString, "https://api.flock-dev.com/proxy")
            
            let httpResponse = response as! HTTPURLResponse
            
            XCTAssertEqual(httpResponse.statusCode, 200)
            
            proxyExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
    
    func testProxyWithAProxyUrl() {
        let privateBtApiKey = Configuration.getConfiguration().privateBtApiKey!
        
        let proxyExpectation = self.expectation(description: "Proxy")
        let proxyHttpRequest = ProxyHttpRequest(method: .post, body: [
            "testProp": "testValue",
            "objProp": [
                "nestedTestProp": "nestedTestValue"
            ]
        ])
        BasisTheoryElements.proxy(
            apiKey: privateBtApiKey,
            proxyUrl: "https://echo.basistheory.com/post",
            proxyHttpRequest: proxyHttpRequest)
        { response, data, error in
            XCTAssertNil(error)
            XCTAssertEqual(response?.url?.absoluteString, "https://api.flock-dev.com/proxy")
            
            let httpResponse = response as! HTTPURLResponse
            
            XCTAssertEqual(httpResponse.statusCode, 200)
            
            proxyExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
    
    func testProxyWithValidUrlForRequest() throws {
        let privateBtApiKey = Configuration.getConfiguration().privateBtApiKey!
        let proxyKey = Configuration.getConfiguration().proxyKey!
        
        let proxyExpectation = self.expectation(description: "Proxy")
        let proxyHttpRequest = ProxyHttpRequest(url: "https://api.flock-dev.com/proxy", method: .post, body: [
            "testProp": "testValue",
            "objProp": [
                "nestedTestProp": "nestedTestValue"
            ]
        ])
        BasisTheoryElements.proxy(
            apiKey: privateBtApiKey,
            proxyKey: proxyKey,
            proxyHttpRequest: proxyHttpRequest)
        { response, data, error in
            XCTAssertNil(error)
            XCTAssertEqual(response?.url?.absoluteString, "https://api.flock-dev.com/proxy")
            
            let httpResponse = response as! HTTPURLResponse
            
            XCTAssertEqual(httpResponse.statusCode, 200)
            
            proxyExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
    
    func testProxyWithAnInvalidUrlForRequest() {
        let privateBtApiKey = Configuration.getConfiguration().privateBtApiKey!
        let proxyKey = Configuration.getConfiguration().proxyKey!
        
        let proxyExpectation = self.expectation(description: "Proxy")
        let proxyHttpRequest = ProxyHttpRequest(url: "badprotocol://badhost.com/badpath", method: .post, body: [
            "testProp": "testValue",
            "objProp": [
                "nestedTestProp": "nestedTestValue"
            ]
        ])
        BasisTheoryElements.proxy(
            apiKey: privateBtApiKey,
            proxyKey: proxyKey,
            proxyHttpRequest: proxyHttpRequest)
        { response, data, error in
            XCTAssertEqual(error as! ProxyError, ProxyError.invalidRequest)
            XCTAssertNil(data)
            XCTAssertNil(response)
            
            proxyExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
    
    func testProxyWithCustomHeader() throws {
        let privateBtApiKey = Configuration.getConfiguration().privateBtApiKey!
        let publicApiKey = Configuration.getConfiguration().btApiKey!
        let proxyKey = Configuration.getConfiguration().proxyKey!
        
        var proxyResponseData: JSON = JSON.dictionaryValue([:])
        let proxyExpectation = self.expectation(description: "Proxy")
        let proxyHttpRequest = ProxyHttpRequest(method: .post, headers: [
            "X-Custom-Header": "headerValue",
        ])
        BasisTheoryElements.proxy(
            apiKey: privateBtApiKey,
            proxyKey: proxyKey,
            proxyHttpRequest: proxyHttpRequest)
        { response, data, error in
            XCTAssertNil(error)
            XCTAssertEqual(response?.url?.absoluteString, "https://api.flock-dev.com/proxy")
            
            let httpResponse = response as! HTTPURLResponse
            
            XCTAssertEqual(httpResponse.statusCode, 200)
            
            proxyResponseData = data!
            proxyExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
        
        let createTokenExpectation = self.expectation(description: "Create token")
        var createdToken: CreateTokenResponse? = nil
        let body = CreateToken(type: "token", data: [
            "customHeader": proxyResponseData.headers?["X-Custom-Header"]?.elementValueReference
        ])
        BasisTheoryElements.createToken(body: body, apiKey: publicApiKey) { data, error in
            XCTAssertNil(error)
            
            createdToken = data!
            
            XCTAssertNotNil(createdToken!.id)
            XCTAssertEqual(createdToken!.type, "token")
            
            createTokenExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
        
        let idQueryExpectation = self.expectation(description: "Token ID Query")
        BasisTheoryElements.getTokenById(id: createdToken!.id!, apiKey: privateBtApiKey) { data, error in
            let token = data!.data!.value as! [String: Any]
            
            XCTAssertEqual(token["customHeader"] as! String, "headerValue")
            
            idQueryExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
    
    func testProxyWithoutApiKey() throws {
        let proxyKeyNoAuth = Configuration.getConfiguration().proxyKeyNoAuth!
        
        let proxyExpectation = self.expectation(description: "Proxy")
        let proxyHttpRequest = ProxyHttpRequest(method: .get)
        BasisTheoryElements.proxy(
            proxyKey: proxyKeyNoAuth,
            proxyHttpRequest: proxyHttpRequest)
        { response, data, error in
            XCTAssertNil(error)
            XCTAssertEqual(response?.url?.absoluteString, "https://api.flock-dev.com/proxy")
            
            let httpResponse = response as! HTTPURLResponse
            
            XCTAssertEqual(httpResponse.statusCode, 200)
            
            proxyExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
    
    func testProxyWithRawResponse() {
        let privateBtApiKey = Configuration.getConfiguration().privateBtApiKey!
        let proxyKeyWithRawResponse = "Dxh8Wutij8hNwsxxkFd9Jc"
        
        let proxyExpectation = self.expectation(description: "Proxy")
        let proxyHttpRequest = ProxyHttpRequest(method: .post, body: [
            "testProp": "testValue",
        ])
        BasisTheoryElements.proxy(
            apiKey: privateBtApiKey,
            proxyKey: proxyKeyWithRawResponse,
            proxyHttpRequest: proxyHttpRequest)
        { response, data, error in
            
            XCTAssertEqual(data?.json?.testProp?.rawValue as! String, "testValue")
            XCTAssertNil(error)
            
            proxyExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
    
    func testProxyResponseInElement() throws {
        let proxyKeyNoAuth = Configuration.getConfiguration().proxyKeyNoAuth!
        let publicApiKey = Configuration.getConfiguration().btApiKey!
        let privateApiKey = Configuration.getConfiguration().privateBtApiKey!
        
        let proxyExpectation = self.expectation(description: "Proxy")
        var proxyResponseData: JSON = JSON.dictionaryValue([:])
        let proxyHttpRequest = ProxyHttpRequest(method: .get)
        BasisTheoryElements.proxy(
            proxyKey: proxyKeyNoAuth,
            proxyHttpRequest: proxyHttpRequest)
        { response, data, error in
            XCTAssertNil(error)
            XCTAssertEqual(response?.url?.absoluteString, "https://api.flock-dev.com/proxy")
            
            let httpResponse = response as! HTTPURLResponse
            
            XCTAssertEqual(httpResponse.statusCode, 200)
            
            proxyResponseData = data!
            proxyExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
        
        let textElement = TextElementUITextField()
        textElement.setValue(elementValueReference: proxyResponseData.url?.elementValueReference)
        
        let body: [String: Any] = [
            "data": ["textFieldRef": textElement],
            "type": "token"
        ]
        let tokenizeExpectation = self.expectation(description: "Tokenize")
        var createdToken: [String: Any] = [:]
        BasisTheoryElements.basePath = "https://api.flock-dev.com"
        BasisTheoryElements.tokenize(body: body, apiKey: publicApiKey) { data, error in
            createdToken = data!.value as! [String: Any]
            
            XCTAssertNotNil(createdToken["id"])
            XCTAssertEqual(createdToken["type"] as! String, "token")
            
            tokenizeExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 3)
        
        let idQueryExpectation = self.expectation(description: "Token ID Query")
        BasisTheoryElements.getTokenById(id: createdToken["id"] as! String, apiKey: privateApiKey) { data, error in
            if let data = data {
                let token = data.data!.value as! [String: Any]
                
                XCTAssertEqual(token["textFieldRef"] as! String, "http://echo.basistheory.com/get")
                
                idQueryExpectation.fulfill()
            } else if let error = error {
                print(error)
            }
        }
        
        waitForExpectations(timeout: 3)
    }
}
