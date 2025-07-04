//
//  EncryptTokenViewController.swift
//  IntegrationTester
//
//  Created by Assistant on Date.
//

import Foundation
import UIKit
import BasisTheoryElements
import BasisTheory
import Combine

class EncryptTokenViewController: UIViewController {
    private let lightBackgroundColor : UIColor = UIColor( red: 240/255, green: 240/255, blue: 240/255, alpha: 1.0 )
    private let darkBackgroundColor : UIColor = UIColor( red: 200/255, green: 200/255, blue: 200/255, alpha: 1.0 )
    private var cancellables = Set<AnyCancellable>()
    
    // Test encryption keys - in production, these would come from your backend
    private let publicKey = "-----BEGIN PUBLIC KEY-----\n9n4FlhKXk6FL1VIOJD0l8iXEb317zge+Uc5B53AwWj0=\n-----END PUBLIC KEY-----"
    private let keyId = "3add6cc6-84eb-44f0-a891-bf4fc25bb9e5"
    
    @IBOutlet weak var cardNumberTextField: CardNumberUITextField!
    @IBOutlet weak var expirationDateTextField: CardExpirationDateUITextField!
    @IBOutlet weak var cvcTextField: CardVerificationCodeUITextField!
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
    
    @IBAction func encryptSingleToken(_ sender: Any) {
        let cardTokenRequest: [String: Any] = [
            "data": [
                "number": self.cardNumberTextField,
                "expiration_month": self.expirationDateTextField.month(),
                "expiration_year": self.expirationDateTextField.year(),
                "cvc": self.cvcTextField
            ],
            "type": "card"
        ]
        
        let encryptTokenRequest = EncryptTokenRequest(
            tokenRequests: cardTokenRequest,
            publicKey: publicKey,
            keyId: keyId
        )
        
        do {
            let encryptResponse = try BasisTheoryElements.encryptToken(input: encryptTokenRequest)
            
            // Display the encrypted result
            var outputText = "Encrypted Token:\n\n"
            
            // Handle structured response
            switch encryptResponse {
            case .single(let encryptedToken):
                outputText += "Type: \(encryptedToken.type)\n"
                outputText += "Encrypted: \(encryptedToken.encrypted)\n\n"
                
            case .multiple(let encryptedTokens):
                outputText += "Multiple tokens found:\n"
                for (tokenName, encryptedToken) in encryptedTokens {
                    outputText += "\(tokenName):\n"
                    outputText += "  Type: \(encryptedToken.type)\n"
                    outputText += "  Encrypted: \(encryptedToken.encrypted)\n\n"
                }
            }
            
            self.output.text = outputText
            print("Encryption successful:")
            print(outputText)
            
        } catch {
            self.output.text = "Encryption failed: \(error.localizedDescription)"
            print("Encryption error: \(error)")
        }
    }
    
    @IBAction func encryptMultipleTokens(_ sender: Any) {
        let multipleTokenRequests: [String: [String: Any]] = [
            "creditCard": [
                "data": [
                    "number": self.cardNumberTextField,
                    "expiration_month": self.expirationDateTextField.month(),
                    "expiration_year": self.expirationDateTextField.year(),
                    "cvc": self.cvcTextField
                ],
                "type": "card"
            ],
            "personalInfo": [
                "data": [
                    "name": "John Doe",
                    "email": "john@example.com"
                ],
                "type": "token"
            ],
            "bankAccount": [
                "data": [
                    "routing_number": "021000021",
                    "account_number": "1234567890"
                ],
                "type": "bank"
            ]
        ]
        
        let encryptTokenRequest = EncryptTokenRequest(
            tokenRequests: multipleTokenRequests,
            publicKey: publicKey,
            keyId: keyId
        )
        
        do {
            let encryptResponse = try BasisTheoryElements.encryptToken(input: encryptTokenRequest)
            
            // Display the encrypted result
            var outputText = "Encrypted Tokens:\n\n"
            
            // Handle structured response
            switch encryptResponse {
            case .single(let encryptedToken):
                outputText += "Single token:\n"
                outputText += "Type: \(encryptedToken.type)\n"
                outputText += "Encrypted: \(encryptedToken.encrypted)\n\n"
                
            case .multiple(let encryptedTokens):
                outputText += "Multiple tokens encrypted:\n\n"
                for (tokenName, encryptedToken) in encryptedTokens {
                    outputText += "\(tokenName):\n"
                    outputText += "  Type: \(encryptedToken.type)\n"
                    outputText += "  Encrypted: \(encryptedToken.encrypted.prefix(50))...\n\n"
                }
            }
            
            self.output.text = outputText
            print("Multiple encryption successful:")
            print(outputText)
            
        } catch {
            self.output.text = "Multiple encryption failed: \(error.localizedDescription)"
            print("Multiple encryption error: \(error)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setStyles(textField: cardNumberTextField, placeholder: "Card Number")
        setStyles(textField: expirationDateTextField, placeholder: "MM/YY")
        setStyles(textField: cvcTextField, placeholder: "CVC")
        
        let cvcOptions = CardVerificationCodeOptions(cardNumberUITextField: cardNumberTextField)
        cvcTextField.setConfig(options: cvcOptions)
        
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
        
        // Set initial display text
        self.output.text = "Use the buttons to encrypt single or multiple tokens.\n\nSingle token encrypts just the card data.\n\nMultiple tokens encrypts card + additional demo data."
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
