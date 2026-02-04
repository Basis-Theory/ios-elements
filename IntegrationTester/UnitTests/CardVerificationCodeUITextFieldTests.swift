//
//  CardVerificationCodeUITextField.swift
//  IntegrationTesterTests
//
//  Created by Brian Gonzalez on 10/18/22.
//

import XCTest
import BasisTheoryElements
import Combine

final class CardVerificationCodeUITextFieldTests: XCTestCase {
    override func setUpWithError() throws { }

    override func tearDownWithError() throws { }
    
    func testInvalidCVCEvents() throws {
        let cvcTextField = CardVerificationCodeUITextField()
        
        // change to only this assertion as it has a default mask now
        let invalidCvcWith2DigitsExpectation = self.expectation(description: "Invalid CVC with 2 digits")

        
        var cancellables = Set<AnyCancellable>()
        cvcTextField.subject.sink { completion in
            print(completion)
        } receiveValue: { message in
            XCTAssertEqual(message.type, "textChange")
            XCTAssertEqual(message.empty, false)
            XCTAssertEqual(message.valid, false)
            XCTAssertEqual(message.complete, false)
            invalidCvcWith2DigitsExpectation.fulfill()
        }.store(in: &cancellables)

        cvcTextField.insertText("12")
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testValidCVCEvents() throws {
        let cvcTextField = CardVerificationCodeUITextField()

        let valid3DigitCvcExpectation = self.expectation(description: "Valid 3-digit CVC")
        let valid4DigitCvcExpectation = self.expectation(description: "Valid 4-digit CVC")
        
        var threeDigitExpectationHasBeenFulfilled = false

        var cancellables = Set<AnyCancellable>()
        cvcTextField.subject.sink { completion in
            print(completion)
        } receiveValue: { message in
            XCTAssertEqual(message.type, "textChange")
            XCTAssertEqual(message.empty, false)
            XCTAssertEqual(message.valid, true)
            
            if (!threeDigitExpectationHasBeenFulfilled) {
                XCTAssertEqual(message.complete, true)
                valid3DigitCvcExpectation.fulfill()
                threeDigitExpectationHasBeenFulfilled = true
            } else {
                XCTAssertEqual(message.complete, true)
                valid4DigitCvcExpectation.fulfill()
            }
        }.store(in: &cancellables)

        cvcTextField.insertText("123")
        cvcTextField.insertText("4")
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testWithAndWithoutCVCInputEvents() throws {
        let cvcTextField = CardVerificationCodeUITextField()
        
        let cvcInputExpectation = self.expectation(description: "CVC input")
        let cvcDeleteExpectation = self.expectation(description: "CVC delete")
        var cancellables = Set<AnyCancellable>()
        cvcTextField.subject.sink { completion in
            print(completion)
        } receiveValue: { message in
            XCTAssertEqual(message.type, "textChange")
            
            if (!message.empty) {
                XCTAssertEqual(message.valid, true)
                XCTAssertEqual(message.complete, true)
                cvcInputExpectation.fulfill()
            } else {
                XCTAssertEqual(message.valid, false)
                XCTAssertEqual(message.complete, false)
                cvcDeleteExpectation.fulfill()
            }
        }.store(in: &cancellables)

        cvcTextField.insertText("1234")
        cvcTextField.text = ""
        cvcTextField.insertText("")
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testCvcEventIsEmittedWhenCardBrandChanges() throws {
        let cardNumberTextField = CardNumberUITextField()
        let cvcTextField = CardVerificationCodeUITextField()
        
        cvcTextField.setConfig(options: CardVerificationCodeOptions(cardNumberUITextField: cardNumberTextField))
        
        var cvcInitialMaskHasBeenSet = false
        var cvcInitialTextHasBeenEntered = false
        let cvcTextExpectation = self.expectation(description: "CVC input")
        let cvcMaskChangeExpectation1 = self.expectation(description: "CVC mask change 1")
        let cvcMaskChangeExpectation2 = self.expectation(description: "CVC mask change 2")
        var cancellables = Set<AnyCancellable>()
        cvcTextField.subject.sink { completion in
            print(completion)
        } receiveValue: { message in
            if !cvcInitialMaskHasBeenSet {
                cvcInitialMaskHasBeenSet = true
                
                XCTAssertEqual(message.type, "maskChange")
                XCTAssertEqual(message.valid, false)
                XCTAssertEqual(message.complete, false)
                
                cvcMaskChangeExpectation1.fulfill()
            } else if !cvcInitialTextHasBeenEntered {
                cvcInitialTextHasBeenEntered = true
                
                XCTAssertEqual(message.type, "textChange")
                XCTAssertEqual(message.valid, true)
                XCTAssertEqual(message.complete, true)
                
                cvcTextExpectation.fulfill()
            } else {
                XCTAssertEqual(message.type, "maskChange")
                XCTAssertEqual(message.valid, true)
                XCTAssertEqual(message.complete, false)
                
                cvcMaskChangeExpectation2.fulfill()
            }
        }.store(in: &cancellables)
        
        let amExCardNumber = "378282246310005"
        let amExCvc = "4321"
        
        cardNumberTextField.insertText(amExCardNumber)
        cvcTextField.insertText(amExCvc)
        
        let visaCardNumber = "4242424242424242"
        let masterCardCardNumber = "5555555555554444"
        
        cardNumberTextField.text = ""
        cardNumberTextField.insertText(visaCardNumber)
        cardNumberTextField.text = ""
        cardNumberTextField.insertText(masterCardCardNumber)
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testEnableCopy() throws {
        let cvcField = CardVerificationCodeUITextField()
        cvcField.setConfig(options: CardVerificationCodeOptions(enableCopy: true))
        
        let rightViewContainer = cvcField.rightView
        let iconImageView = rightViewContainer?.subviews.compactMap { $0 as? UIImageView }.first
        
        // assert icon exists
        XCTAssertNotNil(cvcField.rightView)
        XCTAssertNotNil(iconImageView)
    }
    
    func testCopyIconColor() throws {
        let cvcField = CardVerificationCodeUITextField()
        cvcField.setConfig(options: CardVerificationCodeOptions(enableCopy: true, copyIconColor: UIColor.red))
        
        let rightViewContainer = cvcField.rightView
        let iconImageView = rightViewContainer?.subviews.compactMap { $0 as? UIImageView }.first
        
        // assert icon exists
        XCTAssertNotNil(iconImageView)
        
        // assert color
        XCTAssertEqual(iconImageView?.tintColor, UIColor.red)
    }
    
    func testCopyEventEmitted() throws {
        let cvcField = CardVerificationCodeUITextField()
        cvcField.setConfig(options: CardVerificationCodeOptions(enableCopy: true))
        
        let copyEventExpectation = self.expectation(description: "Copy event emitted")
        var cancellables = Set<AnyCancellable>()
        
        cvcField.insertText("123")
        
        cvcField.subject.sink { completion in
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
        
        cvcField.perform(#selector(cvcField.copyText))
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testCopyEventWithIncompleteCVC() throws {
        let cvcField = CardVerificationCodeUITextField()
        cvcField.setConfig(options: CardVerificationCodeOptions(enableCopy: true))
        
        let copyEventExpectation = self.expectation(description: "Copy event with incomplete CVC")
        var cancellables = Set<AnyCancellable>()
        
        cvcField.insertText("12")
        
        cvcField.subject.sink { completion in
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
        
        cvcField.perform(#selector(cvcField.copyText))
        
        waitForExpectations(timeout: 1, handler: nil)
    }
}
