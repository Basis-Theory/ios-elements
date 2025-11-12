//
//  CardBrand.swift
//
//  Created by Brian Gonzalez on 11/21/22.
//

import Foundation

public struct CardBrandDetails {
    public var cardBrandName: String
    public var cardIdentifiers: [Any]
    public var cvcMaskInput: [NSRegularExpression]
    public var cardNumberMaskInput: [Any] = []
    public var validLengths: [Int]
    
    public init(cardBrandName: String, cardIdentifiers: [Any], cvcMaskInput: [NSRegularExpression], gaps: [Int], validLengths: [Int]) {
        var gapIndex = 0
        for i in 1...validLengths.last! {
            if gaps.count-1 >= gapIndex && gaps[gapIndex] == i-1 {
                cardNumberMaskInput.append(" ")
                cardNumberMaskInput.append(CardBrand.regexDigit)
                gapIndex += 1
            } else {
                cardNumberMaskInput.append(CardBrand.regexDigit)
            }
        }
        
        self.cardBrandName = cardBrandName
        self.cardIdentifiers = cardIdentifiers
        self.cvcMaskInput = cvcMaskInput
        self.validLengths = validLengths
    }
}

public struct CardBrandResults {
    public var matchingCardBrands: [CardBrandDetails] = []
    public var bestMatchCardBrand: CardBrandDetails?
    public var maskSatisfied: Bool = false
}

public struct CardBrandName {
    public static let visa = "visa"
    public static let mastercard = "mastercard"
    public static let americanExpress = "americanExpress"
    public static let dinersClub = "dinersClub"
    public static let discover = "discover"
    public static let jcb = "jcb"
    public static let unionPay = "unionPay"
    public static let maestro = "maestro"
    public static let elo = "elo"
    public static let mir = "mir"
    public static let hiper = "hiper"
    public static let hipercard = "hipercard"
    public static let cartesBancaires = "cartes-bancaires"

    public static let allBrandNames = [
        visa,
        mastercard,
        americanExpress,
        dinersClub,
        discover,
        jcb,
        unionPay,
        maestro,
        elo,
        mir,
        hiper,
        hipercard,
        cartesBancaires
    ]
}


public struct CardBrand {
    internal static let regexDigit = try! NSRegularExpression(pattern: "\\d")
    private static let threeDigitCvc = [regexDigit, regexDigit, regexDigit]
    private static let fourDigitCvc = [regexDigit, regexDigit, regexDigit, regexDigit]
    
    
    
    public static let VISA = CardBrandDetails(cardBrandName: CardBrandName.visa, cardIdentifiers: [4], cvcMaskInput: threeDigitCvc, gaps: [4, 8, 12], validLengths: [16, 18, 19])
    public static let MASTERCARD = CardBrandDetails(cardBrandName: CardBrandName.mastercard, cardIdentifiers: [[51, 55], [2221, 2229], [223, 229], [23, 26], [270, 271], 2720], cvcMaskInput: threeDigitCvc, gaps: [4, 8, 12], validLengths: [16])
    public static let AMERICAN_EXPRESS = CardBrandDetails(cardBrandName: CardBrandName.americanExpress, cardIdentifiers: [34, 37], cvcMaskInput: fourDigitCvc, gaps: [4, 10], validLengths: [15])
    public static let DINERS_CLUB = CardBrandDetails(cardBrandName: CardBrandName.dinersClub, cardIdentifiers: [[300, 305], 36, 38, 39], cvcMaskInput: threeDigitCvc, gaps: [4, 10], validLengths: [14, 16, 19])
    public static let DISCOVER = CardBrandDetails(cardBrandName: CardBrandName.discover, cardIdentifiers: [6011, [644, 649], 65], cvcMaskInput: threeDigitCvc, gaps: [4, 8, 12], validLengths: [16, 19])
    public static let JCB = CardBrandDetails(cardBrandName: CardBrandName.jcb, cardIdentifiers: [2131, 1800, [3528, 3589]], cvcMaskInput: threeDigitCvc, gaps: [4, 8, 12], validLengths: [16, 17, 18, 19])
    public static let UNION_PAY = CardBrandDetails(cardBrandName: CardBrandName.unionPay, cardIdentifiers: [
        620,
        [62100, 62197],
        [62200, 62205],
        [622010, 622999],
        [62207, 62209],
        [623, 626],
        6270,
        6272,
        6276,
        [627700, 627779],
        [627781, 627799],
        [6282, 6289],
        6291,
        6292,
        810,
        [8110, 8171],
    ], cvcMaskInput: threeDigitCvc, gaps: [4, 8, 12], validLengths: [14, 15, 16, 17, 18, 19])
    public static let MAESTRO = CardBrandDetails(cardBrandName: CardBrandName.maestro, cardIdentifiers: [
        493698,
        [500000, 504174],
        [504176, 506698],
        [506779, 508999],
        [56, 59],
        63,
        67,
        6,
    ], cvcMaskInput: threeDigitCvc, gaps: [4, 8, 12], validLengths: [12, 13, 14, 15, 16, 17, 18, 19])
    public static let ELO = CardBrandDetails(cardBrandName: CardBrandName.elo, cardIdentifiers: [
        401178,
        401179,
        438935,
        457631,
        457632,
        431274,
        451416,
        457393,
        504175,
        [506699, 506778],
        [509000, 509999],
        627780,
        636297,
        636368,
        [650031, 650033],
        [650035, 650051],
        [650405, 650439],
        [650485, 650538],
        [650541, 650598],
        [650700, 650718],
        [650720, 650727],
        [650901, 650978],
        [651652, 651679],
        [655000, 655019],
        [655021, 655058],
    ], cvcMaskInput: threeDigitCvc, gaps: [4, 8, 12], validLengths: [16])
    public static let MIR = CardBrandDetails(cardBrandName: CardBrandName.mir, cardIdentifiers: [[2200, 2204]], cvcMaskInput: threeDigitCvc, gaps: [4, 8, 12], validLengths: [16, 17, 18, 19])
    public static let HIPER = CardBrandDetails(cardBrandName: CardBrandName.hiper, cardIdentifiers: [637095, 63737423, 63743358, 637568, 637599, 637609, 637612], cvcMaskInput: threeDigitCvc, gaps: [4, 8, 12], validLengths: [16])
    public static let HIPERCARD = CardBrandDetails(cardBrandName: CardBrandName.hipercard, cardIdentifiers: [606282], cvcMaskInput: threeDigitCvc, gaps: [4, 8, 12], validLengths: [16])
    
    public static let DefaultCardBrands =  [
        VISA,
        MASTERCARD,
        AMERICAN_EXPRESS,
        DINERS_CLUB,
        DISCOVER,
        JCB,
        UNION_PAY,
        MAESTRO,
        ELO,
        MIR,
        HIPER,
        HIPERCARD,
    ]
    
    private static var CardBrands: [CardBrandDetails] = DefaultCardBrands
    
    public static func getCardBrand(text: String?) -> CardBrandResults {
        guard text != nil && !text!.isEmpty else {
            return CardBrandResults(matchingCardBrands: [], maskSatisfied: false)
        }
        
        return findMatchingCardBrands(text: text!)
    }
    
    public static func addCardBrands(cardBrands: [CardBrandDetails]) {
        CardBrands = cardBrands
        
        CardBrands.forEach { TelemetryLogging.info("Added custom card brand \($0.cardBrandName)") }
    }
    
    private static func findMatchingCardBrands(text: String) -> CardBrandResults {
        var cardBrandResults = CardBrandResults(matchingCardBrands: [], maskSatisfied: false)
        var longestMatchingLength = 0
        
        for cardBrand in CardBrands {
            for cardBrandIdentifier in cardBrand.cardIdentifiers {
                if let cardBrandIdentifier = cardBrandIdentifier as? Int {
                    let lengthOfCardBrandIdentifier = String(cardBrandIdentifier).count
                    let possibleMatch = Int(text.prefix(lengthOfCardBrandIdentifier))
                    
                    if possibleMatch == cardBrandIdentifier {
                        cardBrandResults.matchingCardBrands.append(cardBrand)
                        
                        findBestMatchAndSetCompleteFlag(text: text, lengthOfCardBrandIdentifier: lengthOfCardBrandIdentifier, cardBrand: cardBrand, longestMatchingLength: &longestMatchingLength, cardBrandResults: &cardBrandResults)
                    }
                } else if let cardBrandIdentifierRange = cardBrandIdentifier as? NSArray {
                    let lowerLimit = cardBrandIdentifierRange[0] as! Int
                    let higherLimit = cardBrandIdentifierRange[1] as! Int
                    let lengthOfCardBrandIdentifier = String(lowerLimit).count
                    let possibleMatch = Int(text.prefix(lengthOfCardBrandIdentifier))!
                    
                    if lowerLimit <= possibleMatch && possibleMatch <= higherLimit {
                        cardBrandResults.matchingCardBrands.append(cardBrand)
                        
                        findBestMatchAndSetCompleteFlag(text: text, lengthOfCardBrandIdentifier: lengthOfCardBrandIdentifier, cardBrand: cardBrand, longestMatchingLength: &longestMatchingLength, cardBrandResults: &cardBrandResults)
                    }
                }
            }
        }
        
        return cardBrandResults
    }
    
    private static func findBestMatchAndSetCompleteFlag(text: String?, lengthOfCardBrandIdentifier: Int, cardBrand: CardBrandDetails, longestMatchingLength: inout Int, cardBrandResults: inout CardBrandResults) {
        if longestMatchingLength < lengthOfCardBrandIdentifier {
            cardBrandResults.bestMatchCardBrand = cardBrand
            longestMatchingLength = lengthOfCardBrandIdentifier
            
            cardBrandResults.maskSatisfied = cardBrand.validLengths.contains(text!.count)
        }
    }
}
