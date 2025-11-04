//
//  CardNumberUITextFieldTests.swift
//  IntegrationTesterTests
//
//  Created by Lucas Chociay on 12/05/22.
//

import XCTest
import BasisTheoryElements
import BasisTheory
import Combine

final class CardNumberUITextFieldTests: XCTestCase {
    private final var TIMEOUT_EXPECTATION = 10.0

    override func setUpWithError() throws {}

    override func tearDownWithError() throws { }
    
    func testInvalidCardNumberEvents() throws {
        let cardNumberTextField = CardNumberUITextField()
        
        let incompleteNumberExpectation = self.expectation(description: "Incomplete card number")
        let luhnInvalidNumberExpectation = self.expectation(description: "Luhn invalid card")
        
        var fieldCleared = false
        var incompleteNumberExpectationHasBeenFulfilled = false
        
        var cancellables = Set<AnyCancellable>()
        cardNumberTextField.subject.sink { completion in
            print(completion)
        } receiveValue: { message in
            XCTAssertEqual(message.type, "textChange")
            XCTAssertEqual(message.valid, false)
            
            if (fieldCleared) {
                XCTAssertEqual(message.empty, true)
                fieldCleared = false
            } else {
                let eventDetails = message.details as [ElementEventDetails]
                let brandDetails = eventDetails[0]
                
                XCTAssertEqual(brandDetails.type, "cardBrand")
                XCTAssertEqual(brandDetails.message, "visa")
                
                // assert metadta
                XCTAssertEqual(cardNumberTextField.metadata.empty, false)
                XCTAssertEqual(cardNumberTextField.metadata.valid, false)
                XCTAssertEqual(cardNumberTextField.cardMetadata.cardBrand, "visa")
                
                if (!incompleteNumberExpectationHasBeenFulfilled) {
                    XCTAssertEqual(message.empty, false)
                    XCTAssertEqual(message.complete, false) // mask incomplete and number is invalid
                    XCTAssertEqual(eventDetails.count, 1)
                    incompleteNumberExpectation.fulfill()
                    incompleteNumberExpectationHasBeenFulfilled = true
                } else {
                    XCTAssertEqual(message.empty, false)
                    XCTAssertEqual(message.complete, false) // mask completed but number invalid
                    XCTAssertEqual(eventDetails.count, 1)
                    
                    luhnInvalidNumberExpectation.fulfill()
                }
            }
            
        }.store(in: &cancellables)
        
        cardNumberTextField.insertText("4129")
        fieldCleared = true
        cardNumberTextField.text = ""
        cardNumberTextField.insertText("4129939187355598") // luhn invalid
        fieldCleared = true
        cardNumberTextField.text = ""
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testValidNumberAndEventDetails() throws {
        let cardNumberTextField = CardNumberUITextField()
        
        let validVisaCardNumberExpectation = self.expectation(description: "Valid visa card number")
        let validMasterCardNumberExpectation = self.expectation(description: "Valid mastercard card number")
        let validAmexCardNumberExpectation = self.expectation(description: "Valid amex card number")
        
        var fieldCleared = false
        var visaExpectationHasBeenFulfilled = false
        var mastercardExpectationHasBeenFulfilled = false
        
        var cancellables = Set<AnyCancellable>()
        cardNumberTextField.subject.sink { completion in
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
                
                // assert metadata
                XCTAssertEqual(cardNumberTextField.metadata.empty, false)
                XCTAssertEqual(cardNumberTextField.metadata.valid, true)
                
                let eventDetails = message.details as [ElementEventDetails]
                let brandDetails = eventDetails[0]
                let last4Details = eventDetails[1]
                let binDetails = eventDetails[2]
                
                XCTAssertEqual(brandDetails.type, "cardBrand")
                XCTAssertEqual(last4Details.type, "cardLast4")
                XCTAssertEqual(binDetails.type, "cardBin")
                
                if (!visaExpectationHasBeenFulfilled) {
                    XCTAssertEqual(message.complete, true)
                    XCTAssertEqual(brandDetails.message, "visa")
                    XCTAssertEqual(last4Details.message, "4242")
                    XCTAssertEqual(binDetails.message, "42424242")
                    
                    // assert metadata
                    XCTAssertEqual(cardNumberTextField.metadata.complete, true)
                    XCTAssertEqual(cardNumberTextField.cardMetadata.cardBrand, "visa")
                    XCTAssertEqual(cardNumberTextField.cardMetadata.cardLast4, "4242")
                    XCTAssertEqual(cardNumberTextField.cardMetadata.cardBin, "42424242")
                    
                    validVisaCardNumberExpectation.fulfill()
                    visaExpectationHasBeenFulfilled = true
                } else if (!mastercardExpectationHasBeenFulfilled) {
                    XCTAssertEqual(message.complete, true)
                    XCTAssertEqual(brandDetails.message, "mastercard")
                    XCTAssertEqual(last4Details.message, "5717")
                    XCTAssertEqual(binDetails.message, "54544229")
                    
                    // assert metadata
                    XCTAssertEqual(cardNumberTextField.metadata.complete, true)
                    XCTAssertEqual(cardNumberTextField.cardMetadata.cardBrand, "mastercard")
                    XCTAssertEqual(cardNumberTextField.cardMetadata.cardLast4, "5717")
                    XCTAssertEqual(cardNumberTextField.cardMetadata.cardBin, "54544229")
                    validMasterCardNumberExpectation.fulfill()
                    mastercardExpectationHasBeenFulfilled = true
                } else {
                    XCTAssertEqual(message.complete, true)
                    XCTAssertEqual(brandDetails.message, "americanExpress")
                    XCTAssertEqual(last4Details.message, "8868")
                    XCTAssertEqual(binDetails.message, "348570")
                    
                    // assert metadata
                    XCTAssertEqual(cardNumberTextField.metadata.complete, true)
                    XCTAssertEqual(cardNumberTextField.cardMetadata.cardBrand, "americanExpress")
                    XCTAssertEqual(cardNumberTextField.cardMetadata.cardLast4, "8868")
                    XCTAssertEqual(cardNumberTextField.cardMetadata.cardBin, "348570")
                    validAmexCardNumberExpectation.fulfill()
                }
            }
        }.store(in: &cancellables)
        
        cardNumberTextField.insertText("4242424242424242")
        fieldCleared = true
        cardNumberTextField.text = ""
        cardNumberTextField.insertText("5454422955385717")
        fieldCleared = true
        cardNumberTextField.text = ""
        cardNumberTextField.insertText("348570250878868")
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testWithAndWithoutCardNumberInputEvents() throws {
        let cardNumberTextField = CardNumberUITextField()
        
        let numberInputExpectation = self.expectation(description: "Card number input")
        let numberDeleteExpectation = self.expectation(description: "Card number delete")
        var cancellables = Set<AnyCancellable>()
        cardNumberTextField.subject.sink { completion in
            print(completion)
        } receiveValue: { message in
            XCTAssertEqual(message.type, "textChange")
            
            if (!message.empty) {
                XCTAssertEqual(message.valid, true)
                XCTAssertEqual(message.complete, true)
                
                // assert metadata
                XCTAssertEqual(cardNumberTextField.metadata.valid, true)
                XCTAssertEqual(cardNumberTextField.metadata.complete, true)
                numberInputExpectation.fulfill()
            } else {
                XCTAssertEqual(message.valid, false)
                XCTAssertEqual(message.complete, false)
                
                // assert metadata
                XCTAssertEqual(cardNumberTextField.metadata.valid, false)
                XCTAssertEqual(cardNumberTextField.metadata.complete, false)
                
                // card bin and last 4 should be nil for non-complete
                XCTAssertEqual(cardNumberTextField.cardMetadata.cardLast4, nil)
                XCTAssertEqual(cardNumberTextField.cardMetadata.cardBin, nil)
                numberDeleteExpectation.fulfill()
            }
        }.store(in: &cancellables)
        
        cardNumberTextField.insertText("4242424242424242")
        cardNumberTextField.text = ""
        cardNumberTextField.insertText("")
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testThrowsWithInvalidCardNumberInput() throws {
        let cardNumberTextField = CardNumberUITextField()
        let invalidCardNumber = "4129939187355598" //Luhn invalid
        cardNumberTextField.text = invalidCardNumber
        
        let body: [String: Any] = [
            "data": [
                "cardNumberRef": cardNumberTextField,
            ],
            "type": "card_number"
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
        let cardNumberTextField = CardNumberUITextField()
        try! cardNumberTextField.setConfig(options: TextElementOptions(enableCopy: true))
        
        let rightViewContainer = cardNumberTextField.rightView
        let iconImageView = rightViewContainer?.subviews.compactMap { $0 as? UIImageView }.first
        
        // assert icon exists
        XCTAssertNotNil(cardNumberTextField.rightView)
        XCTAssertNotNil(iconImageView)
    }
    
    func testCopyIconColor() throws {
        let cardNumberTextField = CardExpirationDateUITextField()
        try! cardNumberTextField.setConfig(options: TextElementOptions(enableCopy: true, copyIconColor: UIColor.red))
        
        let rightViewContainer = cardNumberTextField.rightView
        let iconImageView = rightViewContainer?.subviews.compactMap { $0 as? UIImageView }.first
        
        // assert icon exists
        XCTAssertNotNil(iconImageView)
        
        // assert color
        XCTAssertEqual(iconImageView?.tintColor, UIColor.red)
    }

    func testBinLookupTriggeredAfter6Digits() throws {
        let cardNumberTextField = CardNumberUITextField()
        cardNumberTextField.binLookup = true
        BasisTheoryElements.basePath = "https://api.flock-dev.com"
        BasisTheoryElements.apiKey = Configuration.getConfiguration().btApiKey ?? ""
        
        let binLookupExpectation = self.expectation(description: "BIN lookup triggered")
        
        var cancellables = Set<AnyCancellable>()
        cardNumberTextField.subject.sink { completion in
        } receiveValue: { message in
            if message.binInfo != nil {
                binLookupExpectation.fulfill()
            }
        }.store(in: &cancellables)
        
        // Type first 6 digits of a card (Visa test BIN)
        cardNumberTextField.text = "424242"
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
    
    func testBinInfoIncludedInEvents() throws {
        let cardNumberTextField = CardNumberUITextField()
        cardNumberTextField.binLookup = true
        BasisTheoryElements.basePath = "https://api.flock-dev.com"
        BasisTheoryElements.apiKey = Configuration.getConfiguration().btApiKey ?? ""
        
        let binInfoExpectation = self.expectation(description: "BinInfo included in event")
        
        var cancellables = Set<AnyCancellable>()
        cardNumberTextField.subject.sink { completion in
        } receiveValue: { message in
            // Once we have 6+ digits and BIN lookup completes, binInfo should be present
            if let binInfo = message.binInfo {
                XCTAssertNotNil(binInfo.brand)
                XCTAssertNotNil(binInfo.funding)
                XCTAssertNotNil(binInfo.issuer)
                binInfoExpectation.fulfill()
            }
        }.store(in: &cancellables)
        
        // Type a complete Visa card number
        cardNumberTextField.text = "4242424242424242"
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
    
    func testBinInfoClearedWhenDigitsBelow6() throws {
        let cardNumberTextField = CardNumberUITextField()
        cardNumberTextField.binLookup = true
        BasisTheoryElements.basePath = "https://api.flock-dev.com"
        BasisTheoryElements.apiKey = Configuration.getConfiguration().btApiKey ?? ""
        
        let binInfoReceivedExpectation = self.expectation(description: "BinInfo received")
        let binInfoClearedExpectation = self.expectation(description: "BinInfo cleared")
        var hasSeenBinInfo = false
        
        var cancellables = Set<AnyCancellable>()
        cardNumberTextField.subject.sink { completion in
        } receiveValue: { message in
            
            if message.binInfo != nil && !hasSeenBinInfo {
                hasSeenBinInfo = true
                binInfoReceivedExpectation.fulfill()
                
                // Now clear the text to below 6 digits
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    print("DEBUG: Clearing text to 4242")
                    cardNumberTextField.text = "4242"
                }
            }
            
            // After clearing to less than 6 digits, binInfo should be nil
            if hasSeenBinInfo && message.binInfo == nil && !message.empty {
                binInfoClearedExpectation.fulfill()
            }
        }.store(in: &cancellables)
        
        // Type 6+ digits to trigger BIN lookup
        cardNumberTextField.text = "424242"
        
        waitForExpectations(timeout: 10.0)
    }
    
    func testBinLookupNotTriggeredWhenDisabled() throws {
        let cardNumberTextField = CardNumberUITextField()
        cardNumberTextField.binLookup = false
        BasisTheoryElements.basePath = "https://api.flock-dev.com"
        BasisTheoryElements.apiKey = Configuration.getConfiguration().btApiKey ?? ""
        
        let noBinInfoExpectation = self.expectation(description: "No BinInfo when disabled")
        
        var cancellables = Set<AnyCancellable>()
        cardNumberTextField.subject.sink { completion in
        } receiveValue: { message in
            // binInfo should always be nil when binLookup is disabled
            XCTAssertNil(message.binInfo)
        }.store(in: &cancellables)
        
        // Type a complete card number
        cardNumberTextField.text = "4242424242424242"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            noBinInfoExpectation.fulfill()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
    
    func testBinLookupCaching() throws {
        let cardNumberTextField = CardNumberUITextField()
        cardNumberTextField.binLookup = true
        BasisTheoryElements.basePath = "https://api.flock-dev.com"
        BasisTheoryElements.apiKey = Configuration.getConfiguration().btApiKey ?? ""
        
        // Clear cache before test
        BinLookup.clearCache()
        
        let firstLookupExpectation = self.expectation(description: "First BIN lookup")
        let secondLookupExpectation = self.expectation(description: "Second BIN lookup (cached)")
        
        var lookupCount = 0
        
        var cancellables = Set<AnyCancellable>()
        cardNumberTextField.subject.sink { completion in
            print(completion)
        } receiveValue: { message in
            if message.binInfo != nil {
                lookupCount += 1
                if lookupCount == 1 {
                    firstLookupExpectation.fulfill()
                } else if lookupCount == 2 {
                    // Second lookup should be instant (cached)
                    secondLookupExpectation.fulfill()
                }
            }
        }.store(in: &cancellables)
        
        // First lookup
        cardNumberTextField.text = "424242"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // Clear and type same BIN again (should be cached)
            cardNumberTextField.text = ""
            cardNumberTextField.text = "424242"
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
    
    func testForceEventSendsEventWithBinInfo() throws {
        let cardNumberTextField = CardNumberUITextField()
        cardNumberTextField.binLookup = true
        BasisTheoryElements.basePath = "https://api.flock-dev.com"
        BasisTheoryElements.apiKey = Configuration.getConfiguration().btApiKey ?? ""
        
        let forceEventExpectation = self.expectation(description: "Force event sends binInfo")
        var receivedBinInfo = false
        
        var cancellables = Set<AnyCancellable>()
        cardNumberTextField.subject.sink { completion in
            print(completion)
        } receiveValue: { message in
            if message.binInfo != nil && !receivedBinInfo {
                receivedBinInfo = true
                forceEventExpectation.fulfill()
            }
        }.store(in: &cancellables)
        
        // Type 6 digits to trigger BIN lookup
        cardNumberTextField.text = "424242"
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
}
