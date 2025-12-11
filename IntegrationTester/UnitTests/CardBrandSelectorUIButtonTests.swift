//
//  CardBrandSelectorUIButtonTests.swift
//  IntegrationTester
//
//  Created by Basis Theory on 11/11/25.
//

import XCTest
import Combine
@testable import BasisTheoryElements

final class CardBrandSelectorUIButtonTests: XCTestCase {
    
    var cardBrandSelector: CardBrandSelectorUIButton!
    var cardNumberTextField: CardNumberUITextField!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()

        cardNumberTextField = CardNumberUITextField()
        cardNumberTextField.binLookup = true
        cardNumberTextField.coBadgedSupport = [.cartesBancaires]

        cardBrandSelector = CardBrandSelectorUIButton()

        let options = CardBrandSelectorOptions(cardNumberUITextField: cardNumberTextField)
        cardBrandSelector.setConfig(options: options)
    }
    
    override func tearDown() {
        cardBrandSelector = nil
        cardNumberTextField = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertNil(cardBrandSelector.selectedBrand)
        XCTAssertEqual(cardBrandSelector.availableBrands, [])
        XCTAssertTrue(cardBrandSelector.isHidden)
    }
    
    func testBrandSelectorHiddenWhenNoCoBadgedSupport() {
        let textFieldWithoutCobadge = CardNumberUITextField()
        textFieldWithoutCobadge.binLookup = true
        textFieldWithoutCobadge.coBadgedSupport = []

        let options = CardBrandSelectorOptions(cardNumberUITextField: textFieldWithoutCobadge)
        cardBrandSelector.setConfig(options: options)

        NotificationCenter.default.post(
            name: NSNotification.Name("CardNumberBrandOptionsUpdated"),
            object: ["visa"]
        )

        XCTAssertTrue(cardBrandSelector.isHidden)
        XCTAssertEqual(cardBrandSelector.availableBrands, ["visa"])
    }
    
    func testBrandSelectorVisibleWithMultipleSupportedBrands() {
        NotificationCenter.default.post(
            name: NSNotification.Name("CardNumberBrandOptionsUpdated"),
            object: ["visa", "cartes-bancaires"]
        )

        XCTAssertFalse(cardBrandSelector.isHidden)
        XCTAssertEqual(cardBrandSelector.availableBrands.count, 2)
        XCTAssertTrue(cardBrandSelector.availableBrands.contains("visa"))
        XCTAssertTrue(cardBrandSelector.availableBrands.contains("cartes-bancaires"))
    }
    
    func testBrandSelectorHiddenWithSingleBrand() {
        NotificationCenter.default.post(
            name: NSNotification.Name("CardNumberBrandOptionsUpdated"),
            object: ["VISA"]
        )

        XCTAssertTrue(cardBrandSelector.isHidden)
        XCTAssertEqual(cardBrandSelector.availableBrands.count, 1)
    }
    
    func testBrandSelectionUpdatesSelectedBrand() {
        NotificationCenter.default.post(
            name: NSNotification.Name("CardNumberBrandOptionsUpdated"),
            object: ["visa", "cartes-bancaires"]
        )

        let expectation = self.expectation(description: "Wait for notification processing")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        XCTAssertEqual(cardBrandSelector.availableBrands.count, 2)
        XCTAssertTrue(cardBrandSelector.availableBrands.contains("visa"))
        XCTAssertTrue(cardBrandSelector.availableBrands.contains("cartes-bancaires"))

        cardBrandSelector.setSelectedBrand("cartes-bancaires")

        let selectionExpectation = self.expectation(description: "Wait for selection processing")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            selectionExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        XCTAssertEqual(cardBrandSelector.selectedBrand, "cartes-bancaires")
    }
    
    func testBrandSelectionSendsNotification() {
        NotificationCenter.default.post(
            name: NSNotification.Name("CardNumberBrandOptionsUpdated"),
            object: ["visa", "cartes-bancaires"]
        )

        let expectation = self.expectation(description: "Brand selection notification received")

        NotificationCenter.default.publisher(for: NSNotification.Name("CardBrandSelected"))
            .sink { notification in
                if let brandName = notification.object as? String {
                    XCTAssertEqual(brandName, "cartes-bancaires")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        cardBrandSelector.setSelectedBrand("cartes-bancaires")

        waitForExpectations(timeout: 1.0)
    }
    
    func testBrandSelectionTriggersCallback() {
        NotificationCenter.default.post(
            name: NSNotification.Name("CardNumberBrandOptionsUpdated"),
            object: ["visa", "cartes-bancaires"]
        )

        let expectation = self.expectation(description: "Brand selection callback triggered")

        cardBrandSelector.onBrandSelection { selectedBrand in
            XCTAssertEqual(selectedBrand, "cartes-bancaires")
            expectation.fulfill()
        }

        cardBrandSelector.setSelectedBrand("cartes-bancaires")

        waitForExpectations(timeout: 1.0)
    }
    
    func testBrandSelectorClearedWhenBinInfoCleared() {
        NotificationCenter.default.post(
            name: NSNotification.Name("CardNumberBrandOptionsUpdated"),
            object: ["visa", "cartes-bancaires"]
        )

        XCTAssertFalse(cardBrandSelector.isHidden)

        NotificationCenter.default.post(
            name: NSNotification.Name("CardNumberBrandOptionsUpdated"),
            object: []
        )

        XCTAssertTrue(cardBrandSelector.isHidden)
        XCTAssertEqual(cardBrandSelector.availableBrands, [])
        XCTAssertNil(cardBrandSelector.selectedBrand)
    }
}
