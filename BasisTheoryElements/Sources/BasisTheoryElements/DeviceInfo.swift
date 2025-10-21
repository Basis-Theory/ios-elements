//
//  DeviceInfo.swift
//  
//
//  Created by Basis Theory Elements on 10/21/24.
//

import Foundation
import UIKit

public struct DeviceInfo: Codable {
    let uaBrands: [[String: String]]?
    let uaMobile: Bool?
    let uaPlatform: String?
    let uaPlatformVersion: String?
    let languages: [String]?
    let timeZone: String?
    let platform: String?
    let screenWidth: Double?
    let screenHeight: Double?
    let innerWidth: Double?
    let innerHeight: Double?
    let devicePixelRatio: Double?
    
    enum CodingKeys: String, CodingKey {
        case uaBrands
        case uaMobile
        case uaPlatform
        case uaPlatformVersion
        case languages
        case timeZone
        case platform
        case screenWidth
        case screenHeight
        case innerWidth
        case innerHeight
        case devicePixelRatio
    }
}

/// Collects device information and returns it as a base64-encoded string for HTTP headers
/// This information is sent with API requests for analytics and security purposes
/// Returns nil if encoding fails
public func getEncodedDeviceInfo() -> String? {
    let screen = UIScreen.main.bounds
    let nativeScale = UIScreen.main.nativeScale
    
    // Get iOS version
    let systemVersion = UIDevice.current.systemVersion
    
    // Get preferred languages
    let preferredLanguages = Locale.preferredLanguages
    
    // Get timezone
    let timeZone = TimeZone.current.identifier
    
    // Get device model/platform
    let platform = UIDevice.current.systemName
    
    let deviceInfo = DeviceInfo(
        uaBrands: nil, // Not available on iOS
        uaMobile: true, // iOS devices are always mobile
        uaPlatform: platform,
        uaPlatformVersion: systemVersion,
        languages: preferredLanguages,
        timeZone: timeZone,
        platform: platform,
        screenWidth: Double(screen.width * nativeScale),
        screenHeight: Double(screen.height * nativeScale),
        innerWidth: Double(screen.width),
        innerHeight: Double(screen.height),
        devicePixelRatio: Double(nativeScale)
    )
    
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .useDefaultKeys
    
    guard let jsonData = try? encoder.encode(deviceInfo) else {
        return nil
    }
    
    let encodedString = jsonData.base64EncodedString()
    print("Encoded Device Info: \(encodedString)")
    
    return encodedString
}
