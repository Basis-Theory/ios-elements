# Basis Theory iOS Elements SDK

**Basis Theory Elements** are simple, secure, developer-friendly inputs that empower consumers to collect sensitive data from their users directly to Basis Theory’s certified vault.

Think about it as a portal that we open within your mobile app that allows users to seamlessly tokenize information and never notice they are interacting with our technology. Here is how we make it possible:

- Own your UX, by fully customizing how **Elements** are styled
- Use inputs and forms with ease
- Interact with Elements just like native elements

## Installation

### Swift Package Manager

#### Via Xcode

Add through Xcode via _File -> Add Packages_. Search for "https://github.com/Basis-Theory/ios-elements" and click on "Copy Dependency".

#### Via Package.swift

Add the following line under `dependencies` to your `Package.swift`:

```swift
    .package(url: "https://github.com/Basis-Theory/ios-elements", from: "X.X.X"),
```

And add `BasisTheoryElements` as a dependency to your `target`:

```swift
    dependencies: [
        .product(name: "BasisTheoryElements", package: "ios-elements"),
        ...
    ],
```

### CocoaPods

Add the following line to your `Podfile` under your `target`:

```ruby
    pod 'BasisTheoryElements'
```

## Features

- [TextElementUITextField](https://developers.basistheory.com/docs/sdks/mobile/ios/types#textelementuitextfield) to securely collect text input
- [CardNumberUITextField](https://developers.basistheory.com/docs/sdks/mobile/ios/types#cardnumberuitextfield) to securely collect credit card numbers
- [CardExpirationDateUITextField](https://developers.basistheory.com/docs/sdks/mobile/ios/types#cardexpirationdateuitextfield) to securely collect card expiration dates
- [CardVerificationCodeUITextField](https://developers.basistheory.com/docs/sdks/mobile/ios/types#cardverificationcodeuitextfield) to securely collect card verification codes
- [Services](https://developers.basistheory.com/docs/sdks/mobile/ios/services) to retrieve and tokenize sensitive data entered into Elements
- [Styling](https://developers.basistheory.com/docs/sdks/mobile/ios/#styling-elements) - custom styles and branding are fully supported
- [Events](https://developers.basistheory.com/docs/sdks/mobile/ios/events) - subscribe to events raised by Elements

## Full TextElementUITextField Example

The following code can be run from our [open source repo](https://github.com/Basis-Theory/ios-elements). Just open the `IntegrationTester.xcodeproj` file found [here](https://github.com/Basis-Theory/ios-elements/tree/master/IntegrationTester/IntegrationTester.xcodeproj).

```swift
//
//  ViewController.swift
//  iOSExample
//
//  Created by Brian Gonzalez on 10/18/22.
//

import UIKit
import Combine
import BasisTheoryElements

class TextElementUITextFieldViewController: UIViewController {
    private let lightBackgroundColor : UIColor = UIColor( red: 240/255, green: 240/255, blue: 240/255, alpha: 1.0 )
    private let darkBackgroundColor : UIColor = UIColor( red: 200/255, green: 200/255, blue: 200/255, alpha: 1.0 )
    private var cancellables = Set<AnyCancellable>()

    @IBOutlet private weak var nameTextField: TextElementUITextField!
    @IBOutlet weak var output: UITextView!
    @IBOutlet private weak var phoneNumberTextField: TextElementUITextField!

    @IBAction func printToConsoleLog(_ sender: Any) {
        nameTextField.text = "Tom Cruise"
        phoneNumberTextField.text = "555-123-4567"

        print("nameTextField.text: \(nameTextField.text)")
        print("phoneTextField.text: \(phoneNumberTextField.text)")
    }

    @IBAction func tokenize(_ sender: Any) {
        let body: [String: Any] = [
            "data": [
                "name": self.nameTextField,
                "phoneNumber": self.phoneNumberTextField,
                "myProp": "myValue",
                "object": [
                    "nestedProp": "nestedValue",
                    "phoneNumber": self.phoneNumberTextField,
                ]
            ],
            "search_indexes": ["{{ data.phoneNumber }}"],
            "type": "token"
        ]

        BasisTheoryElements.tokenize(body: body, apiKey: "YOUR PUBLIC API KEY") { data, error in
            guard error == nil else {
                self.output.text = "There was an error!"
                print(error)
                return
            }

            let stringifiedData = String(data: try! JSONSerialization.data(withJSONObject: data!.value as! [String: Any], options: .prettyPrinted), encoding: .utf8)!

            self.output.text = stringifiedData
            print(stringifiedData)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let regexDigit = try! NSRegularExpression(pattern: "\\d")
        let phoneMask = [ //(123)456-7890
            "(",
            regexDigit,
            regexDigit,
            regexDigit,
            ")",
            regexDigit,
            regexDigit,
            regexDigit,
            "-",
            regexDigit,
            regexDigit,
            regexDigit,
            regexDigit
        ] as [Any]

        let transformMatcher = try! NSRegularExpression(pattern: "[()-]") //Regex to remove parentheses & dashes
        let phoneOptions = TextElementOptions(mask: phoneMask, transform: ElementTransform(matcher: transformMatcher))

        try! phoneNumberTextField.setConfig(options: phoneOptions)

        setStyles(textField: nameTextField, placeholder: "Name")
        setStyles(textField: phoneNumberTextField, placeholder: "Phone Number")

        nameTextField.subject.sink { completion in
            print(completion)
        } receiveValue: { message in
            print(message)
        }.store(in: &cancellables)
    }

    private func setStyles(textField: UITextField, placeholder: String) {
        textField.layer.cornerRadius = 15.0
        textField.placeholder = placeholder
        textField.backgroundColor = lightBackgroundColor
        textField.addTarget(self, action: #selector(didBeginEditing(_:)), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(didEndEditing(_:)), for: .editingDidEnd)
    }

    @objc private func didBeginEditing(_ textField: UITextField) {
        textField.backgroundColor = darkBackgroundColor
    }

    @objc private func didEndEditing(_ textField: UITextField) {
        textField.backgroundColor = lightBackgroundColor
    }
}
```

## Full Split Card Elements Example

The following code can be run from our [open source repo](https://github.com/Basis-Theory/ios-elements). Just open the `IntegrationTester.xcodeproj` file found [here](https://github.com/Basis-Theory/ios-elements/tree/master/IntegrationTester/IntegrationTester.xcodeproj).

```swift
//
//  SplitCardElementsViewController.swift
//  IntegrationTester
//
//  Created by Brian Gonzalez on 11/10/22.
//

import Foundation
import UIKit
import BasisTheoryElements
import Combine

class SplitCardElementsViewController: UIViewController {
    private let lightBackgroundColor : UIColor = UIColor( red: 240/255, green: 240/255, blue: 240/255, alpha: 1.0 )
    private let darkBackgroundColor : UIColor = UIColor( red: 200/255, green: 200/255, blue: 200/255, alpha: 1.0 )
    private var cancellables = Set<AnyCancellable>()

    @IBOutlet weak var cardNumberTextField: CardNumberUITextField!
    @IBOutlet weak var expirationDateTextField: CardExpirationDateUITextField!
    @IBOutlet weak var cvcTextField: CardVerificationCodeUITextField!
    @IBOutlet weak var output: UITextView!
    @IBOutlet weak var cardBrand: UITextView!

    @IBAction func tokenize(_ sender: Any) {
        let body: [String: Any] = [
            "data": [
                "number": self.cardNumberTextField,
                "expiration_month": self.expirationDateTextField.month(),
                "expiration_year": self.expirationDateTextField.year(),
                "cvc": self.cvcTextField
            ],
            "type": "card"
        ]

        BasisTheoryElements.tokenize(body: body, apiKey: "YOUR PUBLIC API KEY") { data, error in
            guard error == nil else {
                self.output.text = "There was an error!"
                print(error)
                return
            }

            let stringifiedData = String(data: try! JSONSerialization.data(withJSONObject: data!.value as! [String: Any], options: .prettyPrinted), encoding: .utf8)!

            self.output.text = stringifiedData
            print(stringifiedData)
        }
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        setStyles(textField: cardNumberTextField, placeholder: "Card Number")
        setStyles(textField: expirationDateTextField, placeholder: "MM/YY")
        setStyles(textField: cvcTextField, placeholder: "CVC")

        cardNumberTextField.subject.sink { completion in
            print(completion)
        } receiveValue: { message in
            print("cardNumber:")
            print(message)

            if (!message.details.isEmpty) {
                var brandDetails = message.details[0]

                self.cardBrand.text = brandDetails.type + ": " + brandDetails.message
            }
        }.store(in: &cancellables)

        expirationDateTextField.subject.sink { completion in
            print(completion)
        } receiveValue: { message in
            print("expirationDate:")
            print(message)
        }.store(in: &cancellables)

        cvcTextField.subject.sink { completion in
            print(completion)
        } receiveValue: { message in
            print("CVC:")
            print(message)
        }.store(in: &cancellables)
    }

    private func setStyles(textField: UITextField, placeholder: String) {
        textField.layer.cornerRadius = 15.0
        textField.placeholder = placeholder
        textField.backgroundColor = lightBackgroundColor
        textField.addTarget(self, action: #selector(didBeginEditing(_:)), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(didEndEditing(_:)), for: .editingDidEnd)
    }

    @objc private func didBeginEditing(_ textField: UITextField) {
        textField.backgroundColor = darkBackgroundColor
    }

    @objc private func didEndEditing(_ textField: UITextField) {
        textField.backgroundColor = lightBackgroundColor
    }
}
```
