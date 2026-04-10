//
//  CardExpirationDateUITextField.swift
//  IntegrationTesterTests
//
//  Created by Lucas Chociay on 11/30/22.
//

import XCTest
import BasisTheoryElements
import Combine

final class CardExpirationDateUITextFieldTests: XCTestCase {
    override func setUpWithError() throws { }
    
    override func tearDownWithError() throws { }
    
    func getCurrentYear() -> Int {
        let now = Date()
        let dateFormatter = DateFormatter()
        
        // check year
        dateFormatter.dateFormat = "YY"
        let currentYear = Int(dateFormatter.string(from: now))!
        
        return currentYear
    }
    
    func getCurrentMonth() -> Int {
        let now = Date()
        let dateFormatter = DateFormatter()
        
        // check year
        dateFormatter.dateFormat = "MM"
        let currentMonth = Int(dateFormatter.string(from: now))!
        
        return currentMonth
    }
    
    func formatMonth(month: Int) -> String {
        let stringifiedMonth = "0" + String(month)
        
        return String(stringifiedMonth.suffix(2))
    }
    
    func testInvalidExpirationDateEvents() throws {
        let expirationDateTextField = CardExpirationDateUITextField()
        
        let incompleteDateExpectation = self.expectation(description: "Incomplete expiration date")
        let invalidDateYearInThePastExpectation = self.expectation(description: "Invalid expiration date with year in the past")
        let invalidDateMonthInThePastExpectation = self.expectation(description: "Invalid expiration date with month in the past")
        
        var fieldCleared = false
        var incompleteDateExpectationHasBeenFulfilled = false
        var invalidDateYearInThePastExpectationHasBeenFulfilled = false
        
        var cancellables = Set<AnyCancellable>()
        expirationDateTextField.subject.sink { completion in
            print(completion)
        } receiveValue: { message in
            XCTAssertEqual(message.type, "textChange")
            XCTAssertEqual(message.valid, false)
            
            if (fieldCleared) {
                XCTAssertEqual(message.empty, true)
                fieldCleared = false
            } else {
                XCTAssertEqual(message.empty, false)
                
                if (!incompleteDateExpectationHasBeenFulfilled) {
                    XCTAssertEqual(message.complete, false)
                    incompleteDateExpectation.fulfill()
                    incompleteDateExpectationHasBeenFulfilled = true
                } else if (!invalidDateYearInThePastExpectationHasBeenFulfilled) {
                    XCTAssertEqual(message.complete, false)
                    invalidDateYearInThePastExpectation.fulfill()
                    invalidDateYearInThePastExpectationHasBeenFulfilled = true
                } else {
                    XCTAssertEqual(message.complete, false)
                    invalidDateMonthInThePastExpectation.fulfill()
                }
                
            }
        }.store(in: &cancellables)
        
        let pastYear = getCurrentYear() - 1
        let pastMonth = getCurrentMonth() - 1
        
        expirationDateTextField.insertText("1") // incomplete
        fieldCleared = true
        expirationDateTextField.text = ""
        expirationDateTextField.insertText("12/" + String(pastYear)) // year in the past
        fieldCleared = true
        expirationDateTextField.text = ""
        expirationDateTextField.insertText(formatMonth(month: pastMonth) + "/" + String(getCurrentYear())) // month in past
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testValidExpirationDateEvents() throws {
        let expirationDateTextField = CardExpirationDateUITextField()
        
        let validExpDateFutureYearExpectation = self.expectation(description: "Valid expiration date - future year")
        let validExpDateFutureMonthExpectation = self.expectation(description: "Valid expiration date - future month")
        let validExpDateCurrentMonthAndYear = self.expectation(description: "Valid expiration date - current month and year")
        
        var fieldCleared = false
        var futureYearExpectationHasBeenFulfilled = false
        var futureMonthExpectationHasBeenFulfilled = false
        
        var cancellables = Set<AnyCancellable>()
        expirationDateTextField.subject.sink { completion in
            print(completion)
        } receiveValue: { message in
            XCTAssertEqual(message.type, "textChange")
            
            if (fieldCleared) {
                XCTAssertEqual(message.empty, true)
                XCTAssertEqual(message.valid, false)
                fieldCleared = false
            } else {
                XCTAssertEqual(message.empty, false)
                XCTAssertEqual(message.valid, true)
                
                if (!futureYearExpectationHasBeenFulfilled) {
                    XCTAssertEqual(message.complete, true)
                    validExpDateFutureYearExpectation.fulfill()
                    futureYearExpectationHasBeenFulfilled = true
                } else if (!futureMonthExpectationHasBeenFulfilled) {
                    XCTAssertEqual(message.complete, true)
                    validExpDateFutureMonthExpectation.fulfill()
                    futureMonthExpectationHasBeenFulfilled = true
                } else {
                    XCTAssertEqual(message.complete, true)
                    validExpDateCurrentMonthAndYear.fulfill()
                }
            }
        }.store(in: &cancellables)
        
        let futureYear = getCurrentYear() + 1
        var futureMonth = getCurrentMonth() + 1
        if (futureMonth > 12) {
            futureMonth = 12
        }
        
        expirationDateTextField.insertText(formatMonth(month: getCurrentMonth()) + "/" + String(futureYear)) // future year
        fieldCleared = true
        expirationDateTextField.text = ""
        expirationDateTextField.insertText(formatMonth(month: futureMonth) + "/" + String(getCurrentYear())) // future month
        fieldCleared = true
        expirationDateTextField.text = ""
        expirationDateTextField.insertText(formatMonth(month: getCurrentMonth()) + "/" + String(getCurrentYear())) // current month/year
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testWithAndWithoutExpirationDateInputEvents() throws {
        let expirationDateTextField = CardExpirationDateUITextField()
        
        let expDateInputExpectation = self.expectation(description: "Expiration date input")
        let expDateDeleteExpectation = self.expectation(description: "Expiration date delete")
        var cancellables = Set<AnyCancellable>()
        expirationDateTextField.subject.sink { completion in
            print(completion)
        } receiveValue: { message in
            XCTAssertEqual(message.type, "textChange")
            
            if (!message.empty) {
                XCTAssertEqual(message.valid, true)
                XCTAssertEqual(message.complete, true)
                expDateInputExpectation.fulfill()
            } else {
                XCTAssertEqual(message.valid, false)
                XCTAssertEqual(message.complete, false)
                expDateDeleteExpectation.fulfill()
            }
        }.store(in: &cancellables)
        
        let futureYear = getCurrentYear() + 1
        
        expirationDateTextField.insertText(formatMonth(month: getCurrentMonth()) + "/" + String(futureYear))
        expirationDateTextField.text = ""
        expirationDateTextField.insertText("")
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testExpirationDateSpecialtyMethods() throws {
        let expirationDateTextField = CardExpirationDateUITextField()
        let futureYear = getCurrentYear() + 1
        let formattedYear = "20" + String(futureYear)
        expirationDateTextField.text = formatMonth(month: getCurrentMonth()) + "/" + String(futureYear)
        
        let body: [String: Any] = [
            "data": [
                "monthRef": expirationDateTextField.month(),
                "yearRef": expirationDateTextField.year(),
            ],
            "type": "token"
        ]
        
        let publicApiKey = Configuration.getConfiguration().btApiKey!
        let tokenizeExpectation = self.expectation(description: "Tokenize")
        var createdToken: [String: Any] = [:]
        BasisTheoryElements.basePath = "https://api.flock-dev.com"
        BasisTheoryElements.tokenize(body: body, apiKey: publicApiKey) { data, error in
            createdToken = data!.value as! [String: Any]
            
            XCTAssertNotNil(createdToken["id"])
            XCTAssertEqual(createdToken["type"] as! String, "token")
            
            tokenizeExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
        
        let privateApiKey = Configuration.getConfiguration().privateBtApiKey!
        let idQueryExpectation = self.expectation(description: "Token ID Query")
        BasisTheoryElements.getTokenById(id: createdToken["id"] as! String, apiKey: privateApiKey) { data, error in
            if let data = data {
                let token = data.data!.value as! [String: Any]
                XCTAssertEqual(token["monthRef"] as? Int, Int(self.formatMonth(month: self.getCurrentMonth())))
                XCTAssertEqual(token["yearRef"] as? Int, Int(formattedYear))
                
                idQueryExpectation.fulfill()
            } else if let error = error {
                print(error)
            }
        }
        
        waitForExpectations(timeout: 3)
    }
    
    func testExpirationDateCustomFormatter() throws {
        let expirationDateTextField = CardExpirationDateUITextField()
        let expectedYear = "2030"
        let expectedMonth = "06"
        expirationDateTextField.text = "\(expectedMonth)/\(expectedYear.suffix(2))"
        
        let body: [String: Any] = [
            "data": [
                "fullYear": expirationDateTextField.format(dateFormat: "yyyy"),
                "fullYearMonth": expirationDateTextField.format(dateFormat: "yyyyMM"),
                "monthDashFullYear": expirationDateTextField.format(dateFormat: "MM-yyyy"),
                "monthForwardSlashTwoDigitYear": expirationDateTextField.format(dateFormat: "MM/yy"),
                "fullYearDashMonth": expirationDateTextField.format(dateFormat: "yyyy-MM"),
                "singleDigitMonth": expirationDateTextField.format(dateFormat: "M"),
                "dubleDigitMonth": expirationDateTextField.format(dateFormat: "MM"),
            ],
            "type": "token"
        ]
        
        let publicApiKey = Configuration.getConfiguration().btApiKey!
        let tokenizeExpectation = self.expectation(description: "Tokenize")
        var createdToken: [String: Any] = [:]
        BasisTheoryElements.basePath = "https://api.flock-dev.com"
        BasisTheoryElements.tokenize(body: body, apiKey: publicApiKey) { data, error in
            createdToken = data!.value as! [String: Any]
            
            XCTAssertNotNil(createdToken["id"])
            XCTAssertEqual(createdToken["type"] as! String, "token")
            
            tokenizeExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
        
        let privateApiKey = Configuration.getConfiguration().privateBtApiKey!
        let idQueryExpectation = self.expectation(description: "Token ID Query")
        
        BasisTheoryElements.getTokenById(id: createdToken["id"] as! String, apiKey: privateApiKey) { data, error in
            if let data = data {
                let token = data.data!.value as! [String: Any]
                XCTAssertEqual(token["fullYear"] as! String, expectedYear)
                XCTAssertEqual(token["singleDigitMonth"] as! String, "\(expectedMonth.suffix(1))")
                XCTAssertEqual(token["dubleDigitMonth"] as! String, expectedMonth)
                XCTAssertEqual(token["fullYearMonth"] as! String, "\(expectedYear)\(expectedMonth)")
                XCTAssertEqual(token["monthDashFullYear"] as! String, "\(expectedMonth)-\(expectedYear)")
                XCTAssertEqual(token["monthForwardSlashTwoDigitYear"] as! String, "\(expectedMonth)/\(expectedYear.suffix(2))")
                XCTAssertEqual(token["fullYearDashMonth"] as! String, "\(expectedYear)-\(expectedMonth)")
                
                idQueryExpectation.fulfill()
            } else if let error = error {
                print(error)
            }
        }
        
        waitForExpectations(timeout: 3)
    }
    
    func testThrowsWithInvalidCardExpirationDateInput() {
        let expirationDateTextField = CardExpirationDateUITextField()
        let pastYear = getCurrentYear() - 2
        let invalidExpirationDate = formatMonth(month: getCurrentMonth()) + "/" + String(pastYear)
        expirationDateTextField.text = invalidExpirationDate
        
        let body: [String: Any] = [
            "data": [
                "monthRef": expirationDateTextField.month(),
                "yearRef": expirationDateTextField.year(),
            ],
            "type": "token"
        ]
        
        let publicApiKey = Configuration.getConfiguration().btApiKey!
        let tokenizeExpectation = self.expectation(description: "Throws before tokenize")
        BasisTheoryElements.basePath = "https://api.flock-dev.com"
        BasisTheoryElements.tokenize(body: body, apiKey: publicApiKey) { data, error in
            XCTAssertNil(data)
            XCTAssertEqual(error as? TokenizingError, TokenizingError.invalidInput)
            
            tokenizeExpectation.fulfill()
        }
        
        let privateBtApiKey = Configuration.getConfiguration().privateBtApiKey!
        let proxyKey = Configuration.getConfiguration().proxyKey!
        let proxyExpectation = self.expectation(description: "Throws before proxy")
        let proxyHttpRequest = ProxyHttpRequest(method: .post, body: body)
        
        BasisTheoryElements.proxy(
            apiKey: privateBtApiKey,
            proxyKey: proxyKey,
            proxyHttpRequest: proxyHttpRequest)
        { response, data, error in
            XCTAssertNil(data)
            XCTAssertEqual(error as? ProxyError, ProxyError.invalidInput)
            
            proxyExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
    }
    
    func testEnableCopy() throws {
        let expirationDateTextField = CardExpirationDateUITextField()
        try! expirationDateTextField.setConfig(options: TextElementOptions(enableCopy: true))
        
        let rightViewContainer = expirationDateTextField.rightView
        let iconImageView = rightViewContainer?.subviews.compactMap { $0 as? UIImageView }.first
        
        // assert icon exists
        XCTAssertNotNil(expirationDateTextField.rightView)
        XCTAssertNotNil(iconImageView)
    }
    
    func testCopyIconColor() throws {
        let expirationDateTextField = CardExpirationDateUITextField()
        try! expirationDateTextField.setConfig(options: TextElementOptions(enableCopy: true, copyIconColor: UIColor.red))
        
        let rightViewContainer = expirationDateTextField.rightView
        let iconImageView = rightViewContainer?.subviews.compactMap { $0 as? UIImageView }.first
        
        // assert icon exists
        XCTAssertNotNil(iconImageView)
        
        // assert color
        XCTAssertEqual(iconImageView?.tintColor, UIColor.red)
    }
    
    func testCopyEventEmitted() throws {
        let expirationDateTextField = CardExpirationDateUITextField()
        try! expirationDateTextField.setConfig(options: TextElementOptions(enableCopy: true))
        
        let copyEventExpectation = self.expectation(description: "Copy event emitted")
        var cancellables = Set<AnyCancellable>()
        
        let futureYear = getCurrentYear() + 1
        expirationDateTextField.insertText(formatMonth(month: getCurrentMonth()) + "/" + String(futureYear))
        
        expirationDateTextField.subject.sink { completion in
            print(completion)
        } receiveValue: { message in
            if message.type == "copy" {
                XCTAssertEqual(message.type, "copy")
                XCTAssertEqual(message.complete, true)
                XCTAssertEqual(message.empty, false)
                XCTAssertEqual(message.valid, true)
                copyEventExpectation.fulfill()
            }
        }.store(in: &cancellables)
        
        expirationDateTextField.perform(#selector(expirationDateTextField.copyText))
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testCopyEventWithIncompleteDate() throws {
        let expirationDateTextField = CardExpirationDateUITextField()
        try! expirationDateTextField.setConfig(options: TextElementOptions(enableCopy: true))
        
        let copyEventExpectation = self.expectation(description: "Copy event with incomplete date")
        var cancellables = Set<AnyCancellable>()
        
        expirationDateTextField.insertText("12")
        
        expirationDateTextField.subject.sink { completion in
            print(completion)
        } receiveValue: { message in
            if message.type == "copy" {
                XCTAssertEqual(message.type, "copy")
                XCTAssertEqual(message.complete, false)
                XCTAssertEqual(message.empty, false)
                XCTAssertEqual(message.valid, false)
                XCTAssertEqual(message.maskSatisfied, false)
                copyEventExpectation.fulfill()
            }
        }.store(in: &cancellables)
        
        expirationDateTextField.perform(#selector(expirationDateTextField.copyText))
        
        waitForExpectations(timeout: 1, handler: nil)
    }
}
