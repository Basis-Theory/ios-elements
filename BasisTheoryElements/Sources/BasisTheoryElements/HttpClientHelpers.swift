//
//  HttpClientHelpers.swift
//  
//
//  Created by Brian Gonzalez on 6/16/23.
//

import Foundation

public struct Config {
    public var headers: [String: String]
    
    public init(headers: [String: String]) {
        self.headers = headers
    }
}

private func mapObjToRequestBody(contentType: String, obj: Any) -> Data? {
    switch contentType {
    case "application/json":
        return try? JSONSerialization.data(withJSONObject: obj, options: [])
    case "application/x-www-form-urlencoded":
        if let formParams = convertObjectToFormUrlEncoded(obj) {
            let encodedParams = encodeParamsToFormUrlEncoded(formParams)
            return encodedParams.data(using: .utf8)
        }
    default:
        fatalError("Content-Type not supported")
    }
    return nil
}

private func convertObjectToFormUrlEncoded(_ obj: Any?, prefix: String = "") -> [String: Any]? {
    guard let obj = obj else {
        return nil
    }
    
    var formParams: [String: Any] = [:]
    
    if let dictionary = obj as? [String: Any] {
        for (key, value) in dictionary {
            let newPrefix = prefix.isEmpty ? key : "\(prefix)[\(key)]"
            if let subFormParams = convertObjectToFormUrlEncoded(value, prefix: newPrefix) {
                formParams.merge(subFormParams) { (_, new) in new }
            }
        }
    } else if let array = obj as? [Any] {
        for (index, value) in array.enumerated() {
            let newPrefix = prefix.isEmpty ? "\(index)" : "\(prefix)[\(index)]"
            if let subFormParams = convertObjectToFormUrlEncoded(value, prefix: newPrefix) {
                formParams.merge(subFormParams) { (_, new) in new }
            }
        }
    } else {
        formParams[prefix] = obj
    }
    
    return formParams.isEmpty ? nil : formParams
}

private func encodeParamsToFormUrlEncoded(_ formParams: [String: Any]) -> String {
    return formParams
        .compactMap { (key, value) in
            guard let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let encodedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                return nil
            }
            return "\(encodedKey)=\(encodedValue)"
        }
        .joined(separator: "&")
}


struct HttpClientHelpers {
    private static let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    private static let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    static func executeTypedRequest<T: Decodable>(
        method: HttpMethod,
        url: String,
        headers: [String: String] = [:],
        body: Encodable? = nil,
        completion: @escaping (T?, Error?) -> Void
    ) {
        guard let requestUrl = URL(string: url) else {
            completion(nil, HttpClientError.invalidURL)
            return
        }
        
        var request = URLRequest(url: requestUrl)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if let encodedDeviceInfo = getEncodedDeviceInfo() {
            request.setValue(encodedDeviceInfo, forHTTPHeaderField: "BT-DEVICE-INFO")
        }

        if let body = body {
            do {
                request.httpBody = try jsonEncoder.encode(body)
            } catch {
                completion(nil, error)
                return
            }
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(nil, HttpClientError.invalidRequest)
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let responseBody = data.flatMap { String(data: $0, encoding: .utf8) }
                TelemetryLogging.error("HTTP request failed", error: HttpClientError.httpError(statusCode: httpResponse.statusCode, body: responseBody), attributes: [
                    "statusCode": httpResponse.statusCode,
                    "url": url,
                    "method": method.rawValue
                ])
                completion(nil, HttpClientError.httpError(statusCode: httpResponse.statusCode, body: responseBody))
                return
            }
            
            guard let data = data else {
                completion(nil, HttpClientError.invalidRequest)
                return
            }
            
            if data.isEmpty {
                completion(nil, nil)
                return
            }
            
            do {
                let result = try jsonDecoder.decode(T.self, from: data)
                completion(result, nil)
            } catch {
                completion(nil, error)
            }
        }.resume()
    }
    
    static func executeRequest(method: HttpMethod, url: String, payload: [String: Any]?, config: Config?, completion: @escaping ((_ request: URLResponse?, _ data: JSON?, _ error: Error?) -> Void)) -> Void {
        guard var components = URLComponents(string: url), components.scheme != nil else {
            completion(nil, nil, HttpClientError.invalidURL)
            return
        }

        guard let url = components.url else {
            completion(nil, nil, HttpClientError.invalidURL)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        if let payload = payload {
            var mutablePayload = payload
            do {
                try BasisTheoryElements.replaceElementRefs(body: &(mutablePayload), endpoint: url.absoluteString)
            } catch {
                completion(nil, nil, HttpClientError.invalidRequest) // error logged with more detail in replaceElementRefs
                return
            }
            
            let contentType = config?.headers["Content-Type"] ?? "application/json"
            
            let httpBody = mapObjToRequestBody(contentType: contentType, obj: mutablePayload)
            
            request.httpBody = httpBody
        }
        
        if let config = config {
            if(config.headers["Content-Type"] == nil) {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            
            for header in config.headers {
                request.setValue(header.value, forHTTPHeaderField: header.key)
            }
        }
        
        if let encodedDeviceInfo = getEncodedDeviceInfo() {
            request.setValue(encodedDeviceInfo, forHTTPHeaderField: "BT-DEVICE-INFO")
        }
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            if let response = response {
                if let data = data {
                    do {
                        let serializedJson = try JSONSerialization.jsonObject(with: data, options: [])
                        
                        var json = JSON.dictionaryValue([:])
                        BasisTheoryElements.traverseJsonDictionary(dictionary: serializedJson as! [String:Any], json: &json, transformValue: JSON.rawValue)
                        
                        TelemetryLogging.info("Successful \(method) response from \(url)")
                        completion(response, json, nil)
                    } catch {
                        TelemetryLogging.warn("Unsuccessful \(method) response from \(url)", error: error)
                        completion(response, nil, error)
                    }
                } else {
                    TelemetryLogging.warn("Unexpected \(method) response from \(url): response does not have a body", error: error)
                    completion(response, nil, error)
                }
            } else {
                TelemetryLogging.warn("Invalid \(method) request to \(url)", error: error)
                completion(nil, nil, HttpClientError.invalidRequest)
            }
        }
        
        task.resume()
    }
}
