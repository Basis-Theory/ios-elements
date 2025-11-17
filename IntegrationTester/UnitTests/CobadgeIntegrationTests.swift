//
//  CobadgeIntegrationTests.swift
//  IntegrationTester
//
//  Created by Basis Theory on 11/11/25.
//

import XCTest
import Combine
@testable import BasisTheoryElements

final class CobadgeIntegrationTests: XCTestCase {
    private final var TIMEOUT_EXPECTATION = 10.0
    
    var cardNumberTextField: CardNumberUITextField!
    var cardBrandSelector: CardBrandSelectorUIButton!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        
        BasisTheoryElements.basePath = "https://api.flock-dev.com"
        BasisTheoryElements.apiKey = Configuration.getConfiguration().btApiKey ?? ""
        
        cardNumberTextField = CardNumberUITextField()
        cardNumberTextField.binLookup = true
        cardNumberTextField.coBadgedSupport = [.cartesBancaires]
        
        cardBrandSelector = CardBrandSelectorUIButton()
        
        let options = CardBrandSelectorOptions(cardNumberUITextField: cardNumberTextField)
        cardBrandSelector.setConfig(options: options)
    }
    
    override func tearDown() {
        cardNumberTextField = nil
        cardBrandSelector = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testCompleteCobadgeWorkflow() {
        let brandSelectorShownExpectation = self.expectation(description: "Brand selector shown")
        let brandSelectionExpectation = self.expectation(description: "Brand selection received")
        
        NotificationCenter.default.publisher(for: NSNotification.Name("CardNumberBrandOptionsUpdated"))
            .sink { notification in
                if let brandOptions = notification.object as? [String], brandOptions.count > 1 {
                    brandSelectorShownExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: NSNotification.Name("CardBrandSelected"))
            .sink { notification in
                if let brandName = notification.object as? String {
                    XCTAssertEqual(brandName, "CARTES BANCAIRES")
                    brandSelectionExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        cardNumberTextField.insertText("4020971234567899")
        cardNumberTextField.textFieldDidChange()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.cardBrandSelector.setSelectedBrand("CARTES BANCAIRES")
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
    
    func testWorkflowWithMultipleSupportedBrands() {
        cardNumberTextField.coBadgedSupport = [.cartesBancaires]
        
        let brandSelectorShownExpectation = self.expectation(description: "Brand selector shown with multiple brands")
        
        NotificationCenter.default.publisher(for: NSNotification.Name("CardNumberBrandOptionsUpdated"))
            .sink { notification in
                if notification.object is [String] {
                    XCTAssertEqual(self.cardBrandSelector.availableBrands.count, 2)
                    XCTAssertTrue(self.cardBrandSelector.availableBrands.contains("VISA"))
                    XCTAssertTrue(self.cardBrandSelector.availableBrands.contains("CARTES BANCAIRES"))
                    brandSelectorShownExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        cardNumberTextField.insertText("4020971234567899")
        cardNumberTextField.textFieldDidChange()
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
    
    func testWorkflowWhenBinInfoCleared() {
        let brandSelectorClearedExpectation = self.expectation(description: "Brand selector cleared")
        
        // Listen for brand options cleared notification
        NotificationCenter.default.publisher(for: NSNotification.Name("CardNumberBrandOptionsUpdated"))
            .sink { notification in
                if let brandOptions = notification.object as? [String], brandOptions.isEmpty {
                    if self.cardBrandSelector.isHidden && self.cardBrandSelector.availableBrands.isEmpty {
                        brandSelectorClearedExpectation.fulfill()
                    }
                }
            }
            .store(in: &cancellables)
        
        cardNumberTextField.insertText("4020971234567899")
        cardNumberTextField.textFieldDidChange()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.cardNumberTextField.text = ""
            self.cardNumberTextField.textFieldDidChange()
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
    
    func testWorkflowWithoutCoBadgedSupport() {
        // Setup without cobadge support
        cardNumberTextField.coBadgedSupport = []
        
        // Input card number that returns only VISA (4111111111111111 -> only VISA)
        cardNumberTextField.insertText("4111111111111111")  // Use full test card number
        cardNumberTextField.textFieldDidChange()
        
        // Add a delay to ensure BIN lookup is processed
        let expectation = self.expectation(description: "Wait for BIN lookup processing")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
        
        // When coBadgedSupport is empty, the brand selector should be hidden and have no available brands
        // The primary brand is handled internally by the card number field, not exposed through the brand selector
        XCTAssertTrue(cardBrandSelector.isHidden)
        XCTAssertEqual(cardBrandSelector.availableBrands, [])
    }
    
    func testIsCompleteFalseWhenMultipleBrandsAvailable() {
        // Setup with cobadge support
        cardNumberTextField.coBadgedSupport = [.cartesBancaires]
        
        let isCompleteExpectation = self.expectation(description: "isComplete should be false")
        
        // Listen for card number events to check isComplete status
        cardNumberTextField.subject.sink { completion in
        } receiveValue: { event in
            if event.complete == false && event.valid == true && event.maskSatisfied == true {
                // Card is valid and mask satisfied but not complete because multiple brands available
                isCompleteExpectation.fulfill()
            }
        }.store(in: &cancellables)
        
        // Input card number that returns multiple brands (4020971234567899 -> VISA + CARTES BANCAIRES)
        cardNumberTextField.insertText("4020971234567899")
        cardNumberTextField.textFieldDidChange()
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
    
    func testIsCompleteTrueAfterBrandSelection() {
        // Setup with cobadge support
        cardNumberTextField.coBadgedSupport = [.cartesBancaires]
        
        let isCompleteAfterSelectionExpectation = self.expectation(description: "isComplete should be true after brand selection")
        
        // Listen for card number events to check isComplete status after brand selection
        cardNumberTextField.subject.sink { completion in
        } receiveValue: { event in
            if event.complete == true && event.selectedNetwork != nil {
                isCompleteAfterSelectionExpectation.fulfill()
            }
        }.store(in: &cancellables)
        
        // Input card number that returns multiple brands
        cardNumberTextField.insertText("4020971234567899")
        cardNumberTextField.textFieldDidChange()
        
        // Wait for BIN lookup, then select a brand
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.cardBrandSelector.setSelectedBrand("CARTES BANCAIRES")
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }
}
