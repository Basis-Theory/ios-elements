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
                    XCTAssertEqual(brandName, "cartes-bancaires")
                    brandSelectionExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        cardNumberTextField.insertText("402097")
        cardNumberTextField.textFieldDidChange()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.cardBrandSelector.setSelectedBrand("cartes-bancaires")
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }

    func testWorkflowWithMultipleSupportedBrands() {
        cardNumberTextField.coBadgedSupport = [.cartesBancaires]
        
        let brandSelectorShownExpectation = self.expectation(description: "Brand selector shown with multiple brands")
        
        NotificationCenter.default.publisher(for: NSNotification.Name("CardNumberBrandOptionsUpdated"))
            .sink { notification in
                if let brandOptions = notification.object as? [String] {
                    XCTAssertEqual(self.cardBrandSelector.availableBrands.count, 2)
                    XCTAssertTrue(self.cardBrandSelector.availableBrands.contains("visa"))
                    XCTAssertTrue(self.cardBrandSelector.availableBrands.contains("cartes-bancaires"))
                    brandSelectorShownExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        cardNumberTextField.insertText("402097")
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
        cardNumberTextField.coBadgedSupport = []
        
        cardNumberTextField.insertText("4111111111111111")
        cardNumberTextField.textFieldDidChange()
        
        let expectation = self.expectation(description: "Wait for BIN lookup processing")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
        
        XCTAssertTrue(cardBrandSelector.isHidden)
        XCTAssertEqual(cardBrandSelector.availableBrands, [])
    }

    func testIsCompleteFalseWhenMultipleBrandsAvailable() {
        cardNumberTextField.coBadgedSupport = [.cartesBancaires]
        
        let isCompleteExpectation = self.expectation(description: "isComplete should be false")
        
        cardNumberTextField.subject.sink { completion in
        } receiveValue: { event in
            if event.complete == false && event.valid == true && event.maskSatisfied == true {
                isCompleteExpectation.fulfill()
            }
        }.store(in: &cancellables)
        
        cardNumberTextField.insertText("4020978034567896")
        cardNumberTextField.textFieldDidChange()
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }

    func testIsCompleteTrueAfterBrandSelection() {
        cardNumberTextField.coBadgedSupport = [.cartesBancaires]
        
        let isCompleteAfterSelectionExpectation = self.expectation(description: "isComplete should be true after brand selection")
        
        cardNumberTextField.subject.sink { completion in
        } receiveValue: { event in
            if event.complete == true && event.selectedNetwork != nil {
                isCompleteAfterSelectionExpectation.fulfill()
            }
        }.store(in: &cancellables)
        
        cardNumberTextField.insertText("4020978034567896")
        cardNumberTextField.textFieldDidChange()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.cardBrandSelector.setSelectedBrand("cartes-bancaires")
        }
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }

    func testFilteringBinInfo() {
        cardNumberTextField.coBadgedSupport = [.cartesBancaires]
        
        let brandSelectorShownExpectation = self.expectation(description: "Brand selector shown")
        let brandSelectorHiddenExpectation = self.expectation(description: "Brand selector hidden")
        var brandSelectorShown = false
        
        NotificationCenter.default.publisher(for: NSNotification.Name("CardNumberBrandOptionsUpdated"))
            .sink { notification in
                if let brandOptions = notification.object as? [String] {
                    if brandOptions.count > 1 && !brandSelectorShown {
                        brandSelectorShown = true
                        XCTAssertFalse(self.cardBrandSelector.isHidden)
                        brandSelectorShownExpectation.fulfill()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.cardNumberTextField.text = "4020977"
                            self.cardNumberTextField.textFieldDidChange()
                        }
                    } else if brandOptions.count == 1 && brandSelectorShown {
                        XCTAssertTrue(self.cardBrandSelector.isHidden)
                        brandSelectorHiddenExpectation.fulfill()
                    }
                }
            }
            .store(in: &cancellables)
        
        cardNumberTextField.insertText("4020978")
        cardNumberTextField.textFieldDidChange()
        
        waitForExpectations(timeout: TIMEOUT_EXPECTATION)
    }

}
