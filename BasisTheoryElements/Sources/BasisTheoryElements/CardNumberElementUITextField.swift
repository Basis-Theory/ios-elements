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
    private var rawBinInfo: BinInfo?
    private var binInfo: BinInfo?
    private var lastBinLookup: String?
    public var coBadgedSupport: [CoBadgedSupport]?
    internal var selectedNetwork: String?
    private var lastBrandOptions: [String] = []
    
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

    private func getFilteredBinInfo() -> BinInfo? {
        let text = super.getValue() ?? ""

        guard let binInfo = rawBinInfo  else {
            return nil
        }

        let cardValue = text
        let primaryRanges = binInfo.binRange ?? []

        let isValidPrimaryRange = primaryRanges.contains { range in
            let binLength = min(range.binMin.count, cardValue.count)
            let cardBin = Int(String(cardValue.prefix(binLength))) ?? 0
            let binMin = Int(String(range.binMin.prefix(binLength))) ?? 0
            let binMax = Int(String(range.binMax.prefix(binLength))) ?? 0
            return binMin <= cardBin && cardBin <= binMax
        }

        let additionals = binInfo.additional?.filter { additional in
            guard let ranges = additional.binRange else { return false }
            return ranges.contains { range in
                let binLength = min(range.binMin.count, cardValue.count)
                let cardBin = Int(String(cardValue.prefix(binLength))) ?? 0
                let binMin = Int(String(range.binMin.prefix(binLength))) ?? 0
                let binMax = Int(String(range.binMax.prefix(binLength))) ?? 0
                return binMin <= cardBin && cardBin <= binMax
            }
        }

        if !isValidPrimaryRange && additionals?.isEmpty ?? true {
            return nil
        }

        return BinInfo(
            brand: isValidPrimaryRange ? binInfo.brand : nil,
            funding: isValidPrimaryRange ? binInfo.funding : nil,
            issuer: isValidPrimaryRange ? binInfo.issuer : nil,
            segment: isValidPrimaryRange ? binInfo.segment : nil,
            additional: additionals?.map { additional in
                CardInfo(
                    brand: additional.brand,
                    funding: additional.funding,
                    issuer: additional.issuer
                )
            }
        )
    }
    
    private func getCardElementEvent(text: String?, event: ElementEvent) -> ElementEvent {
        cardBrand = CardBrand.getCardBrand(text: text)
        
        if (cardBrand?.bestMatchCardBrand != nil) {
            updateCardMask(mask: cardBrand?.bestMatchCardBrand?.cardNumberMaskInput)
        }
        
        let maskSatisfied = cardBrand?.maskSatisfied ?? false
        let hasValidAdditionalBrands = getBrandOptions().count > 1
        let needsBrandSelection = !(coBadgedSupport?.isEmpty ?? true) && hasValidAdditionalBrands && selectedNetwork == nil
        let complete = maskSatisfied && event.valid && !needsBrandSelection
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
        
        let elementEvent = ElementEvent(
            type: "textChange",
            complete: complete,
            empty: event.empty,
            valid: event.valid,
            maskSatisfied: maskSatisfied,
            details: details,
            binInfo: self.binLookup ? getFilteredBinInfo() : nil,
            selectedNetwork: hasValidAdditionalBrands ? self.selectedNetwork : nil
        )
        
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
            if !(self.coBadgedSupport?.isEmpty ?? true) {
                self.updateBrandSelectorOptions()
            }
            return
        }

        lastBinLookup = bin

        BinLookup.getBinInfo(bin: bin, apiKey: BasisTheoryElements.apiKey) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.rawBinInfo = nil
                } else {
                    self?.rawBinInfo = result
                }

                if self?.binLookup == true {
                    self?.textFieldDidChange(forceEvent: true)
                }
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
        if (super.getValue() == nil) {
            cardBrand = nil
            clearBinInfo()
            super.textFieldDidChange(forceEvent: forceEvent)
            return
        }

        guard Int(super.getValue()!) != nil else {
            cardBrand = nil
            clearBinInfo()
            super.textFieldDidChange(forceEvent: forceEvent)
            return
        }

        cardBrand = CardBrand.getCardBrand(text: super.getValue())

        if (cardBrand?.bestMatchCardBrand != nil) {
            updateCardMask(mask: cardBrand?.bestMatchCardBrand?.cardNumberMaskInput)
        }

        let text = super.getValue() ?? ""
        if text.count >= 6 && (binLookup || !(coBadgedSupport?.isEmpty ?? true)) {
            performBinLookup(text: text)
        } else if text.count < 6 {
            clearBinInfo()
        }

        super.textFieldDidChange(forceEvent: forceEvent)
    }

    private func normalizeBrandName(_ brandName: String) -> String {
        return brandName.lowercased().replacingOccurrences(of: "_", with: "-")
    }

    private func isValidBrand(_ brandName: String, supportedBy: [String]) -> Bool {
        let isValid = CardBrandName.allBrandNames.contains(brandName)

        let isSupported = supportedBy.contains(brandName)

        return isValid && isSupported
    }

    public func updateBrandSelectorOptions() {
        let currentBrandOptions = getBrandOptions()

        if currentBrandOptions != lastBrandOptions {
            lastBrandOptions = currentBrandOptions
            NotificationCenter.default.post(
                name: NSNotification.Name("CardNumberBrandOptionsUpdated"),
                object: currentBrandOptions
            )
        }
    }

    internal func getBrandOptions() -> [String] {
        guard let binInfo = getFilteredBinInfo() else { return [] }
        var brands: [String] = []

        if let brand = binInfo.brand {
            brands.append(normalizeBrandName(brand))
        }

        guard let coBadgedSupport = coBadgedSupport,
              !coBadgedSupport.isEmpty else {
            return brands
        }

        let supportedRawValues = coBadgedSupport.map { $0.rawValue }

        binInfo.additional?.forEach { additional in
            let brandName = normalizeBrandName(additional.brand)

            if isValidBrand(brandName, supportedBy: supportedRawValues) {
                brands.append(brandName)
            }
        }

        return brands
    }

    internal func clearBinInfo() {
        guard rawBinInfo != nil || selectedNetwork != nil else { return }

        rawBinInfo = nil
        binInfo = nil
        selectedNetwork = nil
        lastBinLookup = nil

        if !(coBadgedSupport?.isEmpty ?? true) && !lastBrandOptions.isEmpty {
            lastBrandOptions = []
            NotificationCenter.default.post(
                name: NSNotification.Name("CardNumberBrandOptionsUpdated"),
                object: []
            )
        }
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

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(brandSelected(_:)),
            name: NSNotification.Name("CardBrandSelected"),
            object: nil
        )

        TelemetryLogging.info("CardNumberUITextField init", attributes: [
            "elementId": self.elementId
        ])
    }

    @objc private func brandSelected(_ notification: Notification) {
        if let brandName = notification.object as? String {
            selectedNetwork = brandName
            textFieldDidChange(forceEvent: true)
        }
    }
}
