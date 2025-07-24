//
//  TokenIntentViewController.swift
//  IntegrationTester
//
//  Created by Kevin on 07/23/25.
//

import BasisTheory
import BasisTheoryElements
import Combine
import Foundation
import UIKit

class TokenIntentViewController: UIViewController {
    private let lightBackgroundColor: UIColor = UIColor(
        red: 240 / 255, green: 240 / 255, blue: 240 / 255, alpha: 1.0)
    private let darkBackgroundColor: UIColor = UIColor(
        red: 200 / 255, green: 200 / 255, blue: 200 / 255, alpha: 1.0)
    private var cancellables = Set<AnyCancellable>()
    private var lastTokenIntentId: String?

    @IBOutlet weak var cardNumberTextField: CardNumberUITextField!
    @IBOutlet weak var expirationDateTextField: CardExpirationDateUITextField!
    @IBOutlet weak var cvcTextField: CardVerificationCodeUITextField!
    @IBOutlet weak var output: UITextView!
    @IBOutlet weak var cardBrand: UITextView!
    @IBOutlet weak var tokenIntentIdTextField: UITextField!

    @IBAction func printToConsoleLog(_ sender: Any) {
        cardNumberTextField?.text = "4242424242424242"
        expirationDateTextField?.text = "10/26"
        cvcTextField?.text = "909"

        print("cardNumberTextField.text: \(cardNumberTextField?.text ?? "nil")")
        print("expirationDateTextField.text: \(expirationDateTextField?.text ?? "nil")")
        print("cvcTextField.text: \(cvcTextField?.text ?? "nil")")
    }

    private func getApiKey() -> String? {
        let config = Configuration.getConfiguration()
        guard let apiKey = config.btApiKey, !apiKey.isEmpty else {
            output?.text = "Error: API key not configured. Please check your Configuration."
            print("Error: btApiKey is nil or empty in Configuration")
            return nil
        }
        return apiKey
    }

    @IBAction func createTokenIntent(_ sender: Any) {
        guard let apiKey = getApiKey() else { return }

        guard let cardNumberTextField = cardNumberTextField,
            let expirationDateTextField = expirationDateTextField,
            let cvcTextField = cvcTextField
        else {
            output?.text = "Error: UI elements not properly connected"
            return
        }

        let request = CreateTokenIntentRequest(
            type: "card",
            data: [
                "number": cardNumberTextField,
                "expiration_month": expirationDateTextField.month(),
                "expiration_year": expirationDateTextField.year(),
                "cvc": cvcTextField,
            ])

        BasisTheoryElements.createTokenIntent(request: request, apiKey: apiKey) {
            [weak self] data, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    self.output?.text =
                        "There was an error creating token intent!\n\nError: \(error.localizedDescription)"
                    print(error)
                    return
                }

                guard let data = data else {
                    self.output?.text = "No data received from server"
                    return
                }

                // Store the token intent ID for later use
                self.lastTokenIntentId = data.id
                self.tokenIntentIdTextField?.text = data.id

                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted

                do {
                    let jsonData = try encoder.encode(data)
                    let stringifiedData =
                        String(data: jsonData, encoding: .utf8) ?? "Unable to encode response"

                    self.output?.text = "Token Intent Created:\n\n\(stringifiedData)"
                    print(stringifiedData)
                } catch {
                    self.output?.text = "Error encoding response: \(error.localizedDescription)"
                    print("Encoding error: \(error)")
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setStyles(textField: cardNumberTextField, placeholder: "Card Number")
        setStyles(textField: expirationDateTextField, placeholder: "MM/YY")
        setStyles(textField: cvcTextField, placeholder: "CVC")
        setStyles(textField: tokenIntentIdTextField, placeholder: "Token Intent ID")

        let cvcOptions = CardVerificationCodeOptions(cardNumberUITextField: cardNumberTextField)
        cvcTextField.setConfig(options: cvcOptions)

        cardNumberTextField.subject.sink { completion in
            print(completion)
        } receiveValue: { [weak self] message in
            print("cardNumber:")
            print(message)

            if !message.details.isEmpty {
                let brandDetails = message.details[0]
                self?.cardBrand?.text = brandDetails.type + ": " + brandDetails.message
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

    private func setStyles(textField: UITextField?, placeholder: String) {
        guard let textField = textField else { return }

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
