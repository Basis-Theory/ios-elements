//
//  HttpClientViewController.swift
//  IntegrationTester
//
//  Created by kevin on 28/6/23.
//

import Foundation
import UIKit
import BasisTheoryElements
import Combine

class HttpClientViewController: UIViewController {
    private let lightBackgroundColor : UIColor = UIColor( red: 240/255, green: 240/255, blue: 240/255, alpha: 1.0 )
    private let darkBackgroundColor : UIColor = UIColor( red: 200/255, green: 200/255, blue: 200/255, alpha: 1.0 )
    private var cancellables = Set<AnyCancellable>()
    
    @IBOutlet weak var cardNumberTextField: CardNumberUITextField!
    @IBOutlet weak var expirationDateTextField: CardExpirationDateUITextField!
    @IBOutlet weak var cvcTextField: CardVerificationCodeUITextField!
    @IBOutlet weak var cardBrand: UITextView!
    
    @IBAction func printToConsoleLog(_ sender: Any) {
        cardNumberTextField.text = "4242424242424242"
        expirationDateTextField.text = "10/26"
        cvcTextField.text = "909"
    }
    
    @IBAction func createPaymentMethod(_ sender: Any) {
        let body: [String: Any] = [
            "type": "card",
            "billing_details": [
                "name": "Peter Panda"
            ],
            "card": [
                "number": self.cardNumberTextField,
                "exp_month": self.expirationDateTextField.month(),
                "exp_year": self.expirationDateTextField.format(dateFormat: "YY"),
                "cvc": self.cvcTextField
            ]
        ]
        
        BasisTheoryElements.post(
            url: "https://api.stripe.com/v1/payment_methods",
            payload: body,
            config: Config.init(headers: ["Authorization" : "Bearer {{ Stripe's API Key }}", "Content-Type": "application/x-www-form-urlencoded"])) { data, error, completion  in
                DispatchQueue.main.async {
                    guard error == nil else {
                        print(error)
                        return
                    }
                    print(data)
                }
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
