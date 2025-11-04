//
//  BinLookup.swift
//
//
//  Created by BasisTheory Elements
//

import Foundation

public class BinLookup {
    private static var cache: [String: BinInfo?] = [:]
    
    public static func getBinInfo(bin: String, apiKey: String, completion: @escaping (BinInfo?, Error?) -> Void) {
        if let cachedResult = cache[bin] {
            completion(cachedResult, nil)
            return
        }
        
        let urlString = "\(BasisTheoryElements.basePath)/enrichments/card-details?bin=\(bin)"

        guard let url = URL(string: urlString) else {
            TelemetryLogging.error("Invalid URL for BIN lookup", error: nil, attributes: [
                "urlString": urlString
            ])
            completion(nil, HttpClientError.invalidURL)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "BT-API-KEY")
        request.setValue("BasisTheory iOS Elements", forHTTPHeaderField: "User-Agent")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                TelemetryLogging.error("Network error for BIN lookup", error: error, attributes: [
                    "urlString": urlString
                ])
                cache[bin] = nil
                completion(nil, error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                TelemetryLogging.error("Invalid HTTP response for BIN lookup", error: nil, attributes: [
                    "urlString": urlString
                ])
                cache[bin] = nil
                completion(nil, HttpClientError.invalidRequest)
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                let error = NSError(domain: "BinLookup", code: httpResponse.statusCode, userInfo: [
                    NSLocalizedDescriptionKey: "HTTP error! status: \(httpResponse.statusCode)"
                ])

                cache[bin] = nil
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                TelemetryLogging.error("No data received for BIN lookup", error: nil, attributes: [
                    "urlString": urlString
                ])
                cache[bin] = nil
                completion(nil, HttpClientError.invalidRequest)
                return
            }

            do {
                let decoder = JSONDecoder()
                let binInfo = try decoder.decode(BinInfo.self, from: data)
                cache[bin] = binInfo
                completion(binInfo, nil)
            } catch {
                TelemetryLogging.error("JSON decode error for BIN lookup", error: error, attributes: [
                    "urlString": urlString
                ])
                cache[bin] = nil
                completion(nil, error)
            }
        }
        
        task.resume()
    }
    
    public static func clearCache() {
        cache.removeAll()
    }
}
