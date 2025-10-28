//
//  ProxyHelpers.swift
//  
//
//  Created by Brian Gonzalez on 12/21/22.
//

import Foundation
import BasisTheory

struct ProxyHelpers {
    static func getUrlRequest(proxyHttpRequest: ProxyHttpRequest?) throws -> URLRequest {
        var url = proxyHttpRequest?.url ?? "\(BasisTheoryElements.basePath)/proxy" // allows for whitelabeled proxy calls
        
        if proxyHttpRequest?.path != nil {
            url += proxyHttpRequest!.path!
        }
        
        var modifiedQuery = proxyHttpRequest?.query ?? [:]
        modifiedQuery.removeValue(forKey: "bt-proxy-key")
        
        let urlQueryParams = modifiedQuery.compactMap({(key, value) -> String in
            return "\(key)=\(value)"
        }).joined(separator: "&")
        
        if !urlQueryParams.isEmpty {
            url += "?\(urlQueryParams)"
        }
        
        let serviceUrl = URL(string: url)!
        
        return URLRequest(url: serviceUrl)
    }
    
    static func setMethodOnRequest(proxyHttpRequest: ProxyHttpRequest?, request: inout URLRequest) {
        request.httpMethod = proxyHttpRequest?.method?.rawValue ?? HttpMethod.get.rawValue
    }
    
    static func setHeadersOnRequest(btTraceId: String, apiKey: String?, proxyKey: String?, proxyUrl: String?, proxyHttpRequest: ProxyHttpRequest?, request: inout URLRequest) {
        var modifiedHeaders = proxyHttpRequest?.headers ?? [:]
        
        modifiedHeaders["Content-Type"] = "Application/json"
        modifiedHeaders["BT-TRACE-ID"] = btTraceId
        
        if apiKey != nil {
            modifiedHeaders["BT-API-KEY"] = apiKey
        } else {
            modifiedHeaders.removeValue(forKey: "BT-API-KEY")
        }
        
        if proxyKey != nil {
            modifiedHeaders["BT-PROXY-KEY"] = proxyKey
            modifiedHeaders.removeValue(forKey: "BT-PROXY-URL")
        } else if proxyUrl != nil {
            modifiedHeaders["BT-PROXY-URL"] = proxyUrl
            modifiedHeaders.removeValue(forKey: "BT-PROXY-KEY")
        }

        if let encodedDeviceInfo = getEncodedDeviceInfo() {
            modifiedHeaders["BT-DEVICE-INFO"] = encodedDeviceInfo
        }
        
        for header in modifiedHeaders {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }
    }
    
    static func setBodyOnRequest(proxyHttpRequest: ProxyHttpRequest?, request: inout URLRequest) {
        if let proxyHttpRequestBody = proxyHttpRequest?.body {
            let httpBody = try! JSONSerialization.data(withJSONObject: proxyHttpRequestBody, options: [])
            request.httpBody = httpBody
        }
    }
    
    static func executeRequest(endpoint: String, btTraceId: String, request: URLRequest, completion: @escaping ((_ request: URLResponse?, _ data: JSON?, _ error: Error?) -> Void)) {
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            let shouldExposeRawProxyResponse = (response as? HTTPURLResponse)?
                            .allHeaderFields
                            .contains { (key, _) in
                                (key as? String)?.lowercased() == "bt-expose-raw-proxy-response"
                            } == true
            
            if let response = response {
                if let data = data, !data.isEmpty {
                    do {
                        let serializedJson = try JSONSerialization.jsonObject(with: data, options: [])
                        
                        var json = JSON.dictionaryValue([:])
                        if(shouldExposeRawProxyResponse) {
                            BasisTheoryElements.traverseJsonDictionary(dictionary: serializedJson as! [String:Any], json: &json, transformValue: JSON.rawValue)
                        } else {
                            BasisTheoryElements.traverseJsonDictionary(dictionary: serializedJson as! [String:Any], json: &json, transformValue: JSON.createElementValueReference)
                        }
                        
                        completion(response, json, nil)
                        TelemetryLogging.info("Successful API response", attributes: [
                            "endpoint": endpoint,
                            "BT-TRACE-ID": btTraceId,
                            "apiSuccess": true
                        ])
                    } catch {
                        completion(response, nil, error)
                        TelemetryLogging.warn("Unsuccessful API response", error: error, attributes: [
                            "endpoint": endpoint,
                            "BT-TRACE-ID": btTraceId,
                            "apiSuccess": false
                        ])
                    }
                } else {
                    completion(response, JSON.dictionaryValue([:]), nil)
                    TelemetryLogging.info("Successful API response w/ empty/nil body", attributes: [
                        "endpoint": endpoint,
                        "BT-TRACE-ID": btTraceId,
                        "apiSuccess": true
                    ])
                }
            } else {
                completion(nil, nil, ProxyError.invalidRequest)
                TelemetryLogging.warn("Invalid proxy request", error: error, attributes: [
                    "endpoint": endpoint,
                    "BT-TRACE-ID": btTraceId,
                ])
            }
        }.resume()
    }
}
