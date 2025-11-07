//
//  CardNumberElementUITextField.swift
//
//
//  Created by Lucas Chociay on 01/12/22.
//

import UIKit

final public class CardNumberUITextField: TextElementUITextField, CardElementProtocol, CardNumberElementProtocol {
    public var cardMetadata: CardMetadata = CardMetadata(cardBrand: "unknown")
    
    internal var cardBrand: CardBrandResults?
    private var cardMask: [Any]?
    public var binLookup: Bool = false
    private var binInfo: BinInfo?
    private var lastBinLookup: String?
    
    override var getElementEvent: ((String?, ElementEvent) -> ElementEvent)? {
        get {
            getCardElementEvent
        }
        set { }
    }
    
    override var validation: ((String?) -> Bool)? {
        get {
            validateCardNumber
        }
        set { }
    }
    
    public var cardTypes: [CardBrandDetails]? {
        get {
            return nil
        }
        set(newCardTypes) {
            guard let cardTypes = newCardTypes else {
                return
            }
            CardBrand.addCardBrands(cardBrands: cardTypes)
        }
    }
    
    override var inputMask: [Any]? {
        get {
            if cardMask != nil {
                return self.cardMask
            } else {
                return getDefaultCardMask()
            }
        }
        set {
            
        }
    }
    
    public override func setConfig(options: TextElementOptions?) throws {
        if (options?.enableCopy != nil || options?.copyIconColor != nil) {
            try! super.setConfig(options: TextElementOptions(enableCopy: options?.enableCopy, copyIconColor: options?.copyIconColor))
        } else {
            throw ElementConfigError.configNotAllowed
        }
    }
    
    private func getDefaultCardMask() -> [Any] {
        let regexDigit = try! NSRegularExpression(pattern: "\\d")
        return [
            regexDigit,
            regexDigit,
            regexDigit,
            regexDigit,
            " ",
            regexDigit,
            regexDigit,
            regexDigit,
            regexDigit,
            " ",
            regexDigit,
            regexDigit,
            regexDigit,
            regexDigit,
            " ",
            regexDigit,
            regexDigit,
            regexDigit,
            regexDigit
        ]
    }
    
    private func getCardElementEvent(text: String?, event: ElementEvent) -> ElementEvent {
        cardBrand = CardBrand.getCardBrand(text: text)
        
        if (cardBrand?.bestMatchCardBrand != nil) {
            updateCardMask(mask: cardBrand?.bestMatchCardBrand?.cardNumberMaskInput)
        }
        
        let maskSatisfied = cardBrand?.maskSatisfied ?? false
        let complete = maskSatisfied && event.valid
        self.isComplete = complete
        let brand = cardBrand?.bestMatchCardBrand?.cardBrandName != nil ? String(describing: cardBrand!.bestMatchCardBrand!.cardBrandName) : "unknown"
        var details = [ElementEventDetails(type: "cardBrand", message: brand)]
        cardMetadata.cardBrand = brand
        
        if complete {
            let last4 = String(text!.suffix(4))
            let bin = text!.count < 16 ? String(text!.prefix(6)) : String(text!.prefix(8))
            details.append(ElementEventDetails(type: "cardLast4", message: last4))
            details.append(ElementEventDetails(type: "cardBin", message: bin))
            cardMetadata.cardLast4 = last4
            cardMetadata.cardBin = bin
        } else {
            cardMetadata.cardLast4 = nil
            cardMetadata.cardBin = nil
        }
        
        let elementEvent = ElementEvent(type: "textChange", complete: complete, empty: event.empty, valid: event.valid, maskSatisfied: maskSatisfied, details: details, binInfo: self.binInfo)
        
        TelemetryLogging.info("CardNumberUITextField textChange event", attributes: [
            "elementId": self.elementId,
            "event": try? elementEvent.encode()
        ])
        
        return elementEvent
    }
    
    private func validateCardNumber(text: String?) -> Bool {
        guard text != nil else {
            return false
        }
        
        return validateLuhn(cardNumber: text)
    }
    
    private func validateLuhn(cardNumber: String?) -> Bool {
        guard cardNumber != "" else {
            return false
        }
        
        var sum = 0
        let digitStrings = cardNumber?.reversed().map { String($0) }
        
        for tuple in digitStrings!.enumerated() {
            if let digit = Int(tuple.element) {
                let odd = tuple.offset % 2 == 1
                
                switch (odd, digit) {
                case (true, 9):
                    sum += 9
                case (true, 0...8):
                    sum += (digit * 2) % 9
                default:
                    sum += digit
                }
            } else {
                return false
            }
        }
        return sum % 10 == 0
    }
    
    private func updateCardMask(mask: [Any]?) {
        self.cardMask = mask
    }
    
    private func performBinLookup(text: String?) {
        guard let text = text, text.count >= 6 else {
            if binInfo != nil {
                binInfo = nil
                lastBinLookup = nil
                super.textFieldDidChange(forceEvent: true)
            }
            return
        }
        let bin = String(text.prefix(6))

        guard bin != lastBinLookup else {
            return
        }

        lastBinLookup = bin

        BinLookup.getBinInfo(bin: bin, apiKey: BasisTheoryElements.apiKey) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.binInfo = nil
                } else {
                    self?.binInfo = result
                }

                self?.textFieldDidChange(forceEvent: true)
            }
        }
    }

    override var inputTransform: ElementTransform? {
        get {
            let spaceRegex = try! NSRegularExpression(pattern: "[ \t]")
            return ElementTransform(matcher: spaceRegex)
        }
        set { }
    }

    override func textFieldDidChange(forceEvent: Bool = false) {
        if (super.getValue() != nil) {
            guard Int(super.getValue()!) != nil else {
                cardBrand = nil
                super.textFieldDidChange(forceEvent: forceEvent)
                return
            }
            
            cardBrand = CardBrand.getCardBrand(text: super.getValue())
            
            if (cardBrand?.bestMatchCardBrand != nil) {
                updateCardMask(mask: cardBrand?.bestMatchCardBrand?.cardNumberMaskInput)
            }

            if binLookup {
                performBinLookup(text: super.getValue())
            }
        }

        super.textFieldDidChange(forceEvent: forceEvent)
    }

    public func triggerTextChange() {
        textFieldDidChange()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        self.keyboardType = .asciiCapableNumberPad
        TelemetryLogging.info("CardNumberUITextField init", attributes: [
            "elementId": self.elementId
        ])
    }
}
