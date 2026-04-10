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
    
    @IBOutlet weak var readOnlyTextField: TextElementUITextField!
    @IBOutlet weak var cardNumberTextField: CardNumberUITextField!
    @IBOutlet weak var expirationDateTextField: CardExpirationDateUITextField!
    @IBOutlet weak var cvcTextField: CardVerificationCodeUITextField!
    @IBOutlet weak var cardBrandSelector: CardBrandSelectorUIButton!
    @IBOutlet weak var output: UITextView!
    @IBOutlet weak var cardBrand: UITextView!

    @IBAction func printToConsoleLog(_ sender: Any) {
        cardNumberTextField.text = "4242424242424242"
        expirationDateTextField.text = "10/26"
        cvcTextField.text = "909"
        
        print("cardNumberTextField.text: \(cardNumberTextField.text)")
        print("expirationDateTextField.text: \(expirationDateTextField.text)")
        print("cvcTextField.text: \(cvcTextField.text)")
    }

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

        // this next line is used for our own testing purposes. you can simply pass in your public API key into the tokenize request below
        let config = Configuration.getConfiguration()
        BasisTheoryElements.tokenize(body: body, apiKey: config.btApiKey!) { data, error in
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

        let config = Configuration.getConfiguration()
        BasisTheoryElements.apiKey = config.btApiKey ?? ""

        readOnlyTextField.setValueRef(element: cardNumberTextField)

        setStyles(textField: cardNumberTextField, placeholder: "Card Number")
        setStyles(textField: expirationDateTextField, placeholder: "MM/YY")
        setStyles(textField: cvcTextField, placeholder: "CVC")
        setStyles(textField: readOnlyTextField, placeholder: "Read Only")

        // Enable BIN lookup on card number field
        cardNumberTextField.binLookup = true

        let cvcOptions = CardVerificationCodeOptions(cardNumberUITextField: cardNumberTextField)
        cvcTextField.setConfig(options: cvcOptions)

        // Configure cobadge support on CardNumberElement
        cardNumberTextField.coBadgedSupport = [.cartesBancaires]

        let brandSelectorOptions = CardBrandSelectorOptions(
            cardNumberUITextField: cardNumberTextField
        )

        cardBrandSelector.setConfig(options: brandSelectorOptions)

        cardNumberTextField.subject.sink { completion in
            print(completion)
        } receiveValue: { message in
            print("cardNumber:")
            print(message)

            if (!message.details.isEmpty) {
                let brandDetails = message.details[0]
                
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
