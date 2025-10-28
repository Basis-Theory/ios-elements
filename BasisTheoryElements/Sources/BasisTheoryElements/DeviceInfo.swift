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
    let screenWidthPixels: Double?
    let screenHeightPixels: Double?
    let innerWidthPoints: Double?
    let innerHeightPoints: Double?
    let devicePixelRatio: Double?
}

extension DeviceInfo {
    var encoded: String? {
        try? JSONEncoder().encode(self).base64EncodedString()
    }
}

/// Collects device information and returns it as a base64-encoded string for HTTP headers
/// This information is sent with API requests for analytics and security purposes
/// Returns nil if encoding fails
public func getEncodedDeviceInfo() -> String? {
    let screen = UIScreen.main.bounds
    let scale = UIScreen.main.scale
    
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
        screenWidthPixels: Double(screen.width * scale),
        screenHeightPixels: Double(screen.height * scale),
        innerWidthPoints: Double(screen.width),
        innerHeightPoints: Double(screen.height),
        devicePixelRatio: Double(scale)
    )
    
    return deviceInfo.encoded
}
