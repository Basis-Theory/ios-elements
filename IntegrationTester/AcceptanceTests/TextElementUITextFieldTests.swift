//
//  IntegrationTesterUITests.swift
//  IntegrationTesterUITests
//
//  Created by Brian Gonzalez on 10/18/22.
//

import XCTest

final class IntegrationTesterUITests: XCTestCase {
    private var app: XCUIApplication = XCUIApplication()

    override func setUpWithError() throws {
        app.launch()

        let textElementExampleButton = app.buttons["TextElementUITextField Example"]
        textElementExampleButton.press(forDuration: 0.1)
    }

    override func tearDownWithError() throws { }
    
    func testTextSetter() throws {
        let setTextButton = app.buttons["Set Text"]
        setTextButton.press(forDuration: 0.1)
        
        let nameTextField = app.textFields["Name"]
        let phoneNumberTextField = app.textFields["Phone Number"]
        
        XCTAssertEqual(nameTextField.value as! String, "Tom Cruise")
        XCTAssertEqual(phoneNumberTextField.value as! String, "(555)123-4567")
    }
    
    func testFieldMask() throws {
        let invalidValue = "abcdefg"
        let validValue = "5551234567"
        let partiallyValidValue = "ab55cdef5c"
        
        let phoneNumberTextField = app.textFields["Phone Number"]
        phoneNumberTextField.tap()
        
        phoneNumberTextField.typeText(invalidValue)
        XCTAssertEqual(phoneNumberTextField.value as! String, "(")
        
        phoneNumberTextField.doubleTap()
        app.keys["delete"].tap()
        
        phoneNumberTextField.typeText(partiallyValidValue)
        XCTAssertEqual(phoneNumberTextField.value as! String, "(555)")
        
        phoneNumberTextField.doubleTap()
        app.keys["delete"].tap()
        
        phoneNumberTextField.typeText(validValue)
        XCTAssertEqual(phoneNumberTextField.value as! String, "(555)123-4567")
        
        // test that cant add more digits to complete mask
        phoneNumberTextField.typeText("1")
        XCTAssertEqual(phoneNumberTextField.value as! String, "(555)123-4567")
    }
    
    func testElementSetValueRef() throws {
        let nameTextField = app.textFields["Name"]
        let readOnlyTextField = app.textFields["Read Only"]
        
        nameTextField.tap()
        nameTextField.typeText("abcdefg")
        
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", "abcdefg"),
            object: readOnlyTextField
        )
        wait(for: [expectation], timeout: 5)
        
        XCTAssertEqual(readOnlyTextField.value as! String, "abcdefg")
    }
    
    func testCopy() throws {
        let nameTextField = app.textFields["Name"]
        let phoneNumberTextField = app.textFields["Phone Number"]
        
        let nameFieldCopyIcon = nameTextField.otherElements["copy"]
        
        nameTextField.tap()
        nameTextField.typeText("123")
        
        nameFieldCopyIcon.tap()
        
        phoneNumberTextField.press(forDuration: 1)
        
        let pasteOption = app.menuItems["Paste"]

        if pasteOption.waitForExistence(timeout: 10) {
            pasteOption.tap()
        } else {
            XCTFail("Field paste option took to long to display.")
        }
        
        XCTAssertEqual(phoneNumberTextField.value as! String, "(123")
    }
    
    func testCopyFromReadOnly() throws {
        let nameTextField = app.textFields["Name"]
        let readOnlyTextField = app.textFields["Read Only"]
        let phoneNumberTextField = app.textFields["Phone Number"]
        
        let readOnlyFieldCopyIcon = readOnlyTextField.otherElements["copy"]
        
        nameTextField.tap()
        nameTextField.typeText("123")
        
        readOnlyFieldCopyIcon.tap()
        
        phoneNumberTextField.press(forDuration: 1)
        
        let pasteOption = app.menuItems["Paste"]

        if pasteOption.waitForExistence(timeout: 10) {
            pasteOption.tap()
        } else {
            XCTFail("Field paste option took to long to display.")
        }
        
        XCTAssertEqual(phoneNumberTextField.value as! String, "(123")
    }
}
