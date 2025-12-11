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

public struct BinRange: Codable {
    public let binMin: String
    public let binMax: String
}

public struct CardInfo: Codable {
    public let brand: String
    public let funding: String
    public let issuer: CardIssuerDetails
    public let binRange: [BinRange]?
    
    public init(brand: String, funding: String, issuer: CardIssuerDetails, binRange: [BinRange]? = nil) {
        self.brand = brand
        self.funding = funding
        self.issuer = issuer
        self.binRange = binRange
    }
}

public struct BinInfo: Codable {
    public let brand: String?
    public let funding: String?
    public let issuer: CardIssuerDetails?
    public let segment: String?
    public let binRange: [BinRange]?
    public let additional: [CardInfo]?
    
    public init(brand: String?, funding: String?, issuer: CardIssuerDetails?, segment: String?, binRange: [BinRange]? = nil, additional: [CardInfo]? = nil) {
        self.brand = brand
        self.funding = funding
        self.issuer = issuer
        self.segment = segment
        self.additional = additional
        self.binRange = binRange
    }
}
