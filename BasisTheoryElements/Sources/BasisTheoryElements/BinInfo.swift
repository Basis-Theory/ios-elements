//
//  BinInfo.swift
//
//
//  Created by BasisTheory Elements
//

import Foundation

public struct CardIssuerDetails: Codable {
    public let country: String
    public let name: String
    
    public init(country: String, name: String) {
        self.country = country
        self.name = name
    }
}

public struct CardInfo: Codable {
    public let brand: String
    public let funding: String
    public let issuer: CardIssuerDetails
    
    public init(brand: String, funding: String, issuer: CardIssuerDetails) {
        self.brand = brand
        self.funding = funding
        self.issuer = issuer
    }
}

public struct BinInfo: Codable {
    public let brand: String
    public let funding: String
    public let issuer: CardIssuerDetails
    public let segment: String
    public let additional: [CardInfo]?
    
    public init(brand: String, funding: String, issuer: CardIssuerDetails, segment: String, additional: [CardInfo]? = nil) {
        self.brand = brand
        self.funding = funding
        self.issuer = issuer
        self.segment = segment
        self.additional = additional
    }
}

public enum CoBadgedSupport: String, Codable {
    case cartesBancaires = "cartes-bancaires"
}
