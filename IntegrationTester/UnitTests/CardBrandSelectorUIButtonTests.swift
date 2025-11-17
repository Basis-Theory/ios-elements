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
            object: ["VISA"]
        )

        XCTAssertTrue(cardBrandSelector.isHidden)
        XCTAssertEqual(cardBrandSelector.availableBrands, ["VISA"])
    }
    
    func testBrandSelectorVisibleWithMultipleSupportedBrands() {
        NotificationCenter.default.post(
            name: NSNotification.Name("CardNumberBrandOptionsUpdated"),
            object: ["VISA", "CARTES BANCAIRES"]
        )

        XCTAssertFalse(cardBrandSelector.isHidden)
        XCTAssertEqual(cardBrandSelector.availableBrands.count, 2)
        XCTAssertTrue(cardBrandSelector.availableBrands.contains("VISA"))
        XCTAssertTrue(cardBrandSelector.availableBrands.contains("CARTES BANCAIRES"))
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
            object: ["VISA", "CARTES BANCAIRES"]
        )

        let expectation = self.expectation(description: "Wait for notification processing")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        XCTAssertEqual(cardBrandSelector.availableBrands.count, 2)
        XCTAssertTrue(cardBrandSelector.availableBrands.contains("VISA"))
        XCTAssertTrue(cardBrandSelector.availableBrands.contains("CARTES BANCAIRES"))

        cardBrandSelector.setSelectedBrand("CARTES BANCAIRES")

        let selectionExpectation = self.expectation(description: "Wait for selection processing")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            selectionExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        XCTAssertEqual(cardBrandSelector.selectedBrand, "CARTES BANCAIRES")
    }
    
    func testBrandSelectionSendsNotification() {
        NotificationCenter.default.post(
            name: NSNotification.Name("CardNumberBrandOptionsUpdated"),
            object: ["VISA", "CARTES BANCAIRES"]
        )

        let expectation = self.expectation(description: "Brand selection notification received")

        NotificationCenter.default.publisher(for: NSNotification.Name("CardBrandSelected"))
            .sink { notification in
                if let brandName = notification.object as? String {
                    XCTAssertEqual(brandName, "CARTES BANCAIRES")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        cardBrandSelector.setSelectedBrand("CARTES BANCAIRES")

        waitForExpectations(timeout: 1.0)
    }
    
    func testBrandSelectionTriggersCallback() {
        NotificationCenter.default.post(
            name: NSNotification.Name("CardNumberBrandOptionsUpdated"),
            object: ["VISA", "CARTES BANCAIRES"]
        )

        let expectation = self.expectation(description: "Brand selection callback triggered")

        cardBrandSelector.onBrandSelection { selectedBrand in
            XCTAssertEqual(selectedBrand, "CARTES BANCAIRES")
            expectation.fulfill()
        }

        cardBrandSelector.setSelectedBrand("CARTES BANCAIRES")

        waitForExpectations(timeout: 1.0)
    }
    
    func testBrandSelectorClearedWhenBinInfoCleared() {
        NotificationCenter.default.post(
            name: NSNotification.Name("CardNumberBrandOptionsUpdated"),
            object: ["VISA", "CARTES BANCAIRES"]
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
