//
//  BasisTheoryElements.swift
//
//
//  Created by Brian Gonzalez on 10/13/22.
//

import Foundation
import BasisTheory
import AnyCodable
import Combine
import JSONWebKey

public enum TokenizingError: Error {
    case invalidApiKey
    case invalidInput
}

public enum ProxyError: Error {
    case invalidRequest
    case invalidInput
}

public enum HttpClientError: Error {
    case invalidURL
    case invalidRequest
}

extension RequestBuilder {
    func addBasisTheoryElementHeaders(apiKey: String, btTraceId: String) -> Self {
        addHeaders([
            "User-Agent": "BasisTheory iOS Elements",
            "BT-API-KEY": apiKey,
            "BT-TRACE-ID": btTraceId
        ])
        
        return self
    }
}

final public class BasisTheoryElements {
    public static let version = "4.2.2" // do not modify. updated through CI
    public static var apiKey: String = ""
    public static var basePath: String = "https://api.basistheory.com"
    
    private static func getApiKey(_ apiKey: String?) -> String {
        apiKey != nil ? apiKey! : BasisTheoryElements.apiKey
    }
    
    private static func completeApiRequest<T>(endpoint: String, btTraceId: String, result: Result<Response<T>, ErrorResponse>, completion: @escaping ((_ data: T?, _ error: Error?) -> Void)) {
        do {
            let app = try result.get()
            
            completion(app.body, nil)
            TelemetryLogging.info("Successful API response", attributes: [
                "endpoint": endpoint,
                "BT-TRACE-ID": btTraceId,
                "apiSuccess": true
            ])
        } catch {
            completion(nil, error)
            TelemetryLogging.error("Unsuccessful API response", error: error, attributes: [
                "endpoint": endpoint,
                "BT-TRACE-ID": btTraceId,
                "apiSuccess": false
            ])
        }
    }
    
    private static func logBeginningOfApiCall(endpoint: String, btTraceId: String, extraAttributes: [String: Encodable] = [:]) {
        TelemetryLogging.info("Starting API request", attributes: [
            "endpoint": endpoint,
            "BT-TRACE-ID": btTraceId
        ].merging(extraAttributes, uniquingKeysWith: { (_, new) in new }))
    }
    
    private static func getApplicationKey(apiKey: String, btTraceId: String, completion: @escaping ((_ data: Application?, _ error: Error?) -> Void)) {
        let endpoint = "GET /applications/key"
        logBeginningOfApiCall(endpoint: endpoint, btTraceId: btTraceId)
        
        BasisTheoryAPI.basePath = basePath
        ApplicationsAPI.getByKeyWithRequestBuilder().addBasisTheoryElementHeaders(apiKey: getApiKey(apiKey), btTraceId: btTraceId).execute { result in
            completeApiRequest(endpoint: endpoint, btTraceId: btTraceId, result: result, completion: completion)
        }
    }
    
    public static func tokenize(body: [String: Any], apiKey: String? = nil, completion: @escaping ((_ data: AnyCodable?, _ error: Error?) -> Void)) -> Void {
        let endpoint = "POST /tokenize"
        let btTraceId = UUID().uuidString
        logBeginningOfApiCall(endpoint: endpoint, btTraceId: btTraceId)
        
        var mutableBody = body
        do {
            try replaceElementRefs(body: &mutableBody, endpoint: endpoint, btTraceId: btTraceId)
        } catch {
            completion(nil, TokenizingError.invalidInput) // error logged with more detail in replaceElementRefs
            return
        }

        BasisTheoryAPI.basePath = basePath
        TokenizeAPI.tokenizeWithRequestBuilder(body: AnyCodable(mutableBody)).addBasisTheoryElementHeaders(apiKey: getApiKey(apiKey), btTraceId: btTraceId).execute { result in
            completeApiRequest(endpoint: endpoint, btTraceId: btTraceId, result: result, completion: completion)
        }
    }
    
    public static func encryptToken(body: EncryptToken, completion: @escaping ((_ data: [EncryptTokenResponse]?, _ error: Error?) -> Void)) -> Void {
        do {
            let recipientPublicKey = try JWEEncryption.createJWK(from: body.publicKey)
            var responses: [EncryptTokenResponse] = []
            
            // Convert both cases to an array of token requests
            let tokenRequestsArray: [[String: Any]]
            switch body.tokenRequests {
            case .single(let singleRequest):
                tokenRequestsArray = [singleRequest]
            case .multiple(let multipleRequests):
                tokenRequestsArray = Array(multipleRequests.values)
            }
            
            // Process each token request
            for tokenRequest in tokenRequestsArray {
                do {
                    let encryptedResponse = try encryptSingleToken(
                        tokenRequest: tokenRequest,
                        recipientPublicKey: recipientPublicKey,
                        keyId: body.keyId
                    )
                    responses.append(encryptedResponse)
                } catch {
                    completion(nil, error)
                    return
                }
            }
            
            completion(responses, nil)
            TelemetryLogging.info("Successful token encryption", attributes: [
                "encryptionSuccess": true,
                "tokenCount": responses.count
            ])
            
        } catch {
            completion(nil, error)
            TelemetryLogging.error("Token encryption failed", error: error, attributes: [
                "encryptionSuccess": false
            ])
        }
    }
    
    private static func encryptSingleToken(
        tokenRequest: [String: Any],
        recipientPublicKey: JWK,
        keyId: String
    ) throws -> EncryptTokenResponse {
        var mutableTokenRequest = tokenRequest
        try replaceElementRefs(body: &mutableTokenRequest, endpoint: "LOCAL /encrypt-token", btTraceId: nil)
        
        let jsonData = try JSONSerialization.data(withJSONObject: mutableTokenRequest, options: [])
        let encryptedString = try JWEEncryption.encrypt(
            data: jsonData,
            recipientPublicKey: recipientPublicKey,
            keyId: keyId
        )
        
        return EncryptTokenResponse(encrypted: encryptedString, type: "encrypted_token")
    }
    
    public static func createToken(body: CreateToken, apiKey: String? = nil, completion: @escaping ((_ data: CreateTokenResponse?, _ error: Error?) -> Void)) -> Void {
        let endpoint = "POST /tokens"
        let btTraceId = UUID().uuidString
        logBeginningOfApiCall(endpoint: endpoint, btTraceId: btTraceId)
        
        var mutableBody = body
        var mutableData = body.data
        do {
            try replaceElementRefs(body: &mutableData, endpoint: endpoint, btTraceId: btTraceId)
        } catch {
            completion(nil, TokenizingError.invalidInput) // error logged with more detail in replaceElementRefs
            return
        }

        mutableBody.data = mutableData


        BasisTheoryAPI.basePath = basePath
        let createTokenRequest = mutableBody.toCreateTokenRequest()
        
        TokensAPI.createWithRequestBuilder(createTokenRequest: createTokenRequest).addBasisTheoryElementHeaders(apiKey: getApiKey(apiKey), btTraceId: btTraceId).execute { result in
            completeApiRequest(endpoint: endpoint, btTraceId: btTraceId, result: result, completion: completion)
        }
    }
    
    public static func proxy(apiKey: String? = nil, proxyKey: String? = nil, proxyUrl: String? = nil, proxyHttpRequest: ProxyHttpRequest? = nil, completion: @escaping ((_ request: URLResponse?, _ data: JSON?, _ error: Error?) -> Void)) -> Void {
        let endpoint = "\(proxyHttpRequest?.method?.rawValue ?? HttpMethod.get.rawValue) \(proxyHttpRequest?.url ?? "\(BasisTheoryElements.basePath)/proxy")"
        let btTraceId = UUID().uuidString
        logBeginningOfApiCall(endpoint: endpoint, btTraceId: btTraceId, extraAttributes: [
            "proxyHttpRequestPath": proxyHttpRequest?.path ?? "nil",
            "proxyHttpRequestQuery": proxyHttpRequest?.query ?? "nil"
        ])
        
        BasisTheoryAPI.basePath = basePath
        
        var request = try! ProxyHelpers.getUrlRequest(proxyHttpRequest: proxyHttpRequest)
        
        ProxyHelpers.setMethodOnRequest(proxyHttpRequest: proxyHttpRequest, request: &request)
        
        ProxyHelpers.setHeadersOnRequest(btTraceId: btTraceId, apiKey: apiKey, proxyKey: proxyKey, proxyUrl: proxyUrl, proxyHttpRequest: proxyHttpRequest, request: &request)
        
        var mutableProxyHttpRequest = proxyHttpRequest
        if(proxyHttpRequest != nil && proxyHttpRequest?.body != nil) {
            var mutableBody = proxyHttpRequest?.body
            
            do {
                try replaceElementRefs(body: &(mutableBody)!, endpoint: endpoint, btTraceId: btTraceId)
            } catch {
                completion(nil, nil, ProxyError.invalidInput) // error logged with more detail in replaceElementRefs
                return
            }
            
            mutableProxyHttpRequest?.body = mutableBody
        }
        
        ProxyHelpers.setBodyOnRequest(proxyHttpRequest: mutableProxyHttpRequest, request: &request)
        
        ProxyHelpers.executeRequest(endpoint: endpoint, btTraceId: btTraceId, request: request, completion: completion)
    }
    
    public static func createSession(apiKey: String? = nil, completion: @escaping ((_ data: CreateSessionResponse?, _ error: Error?) -> Void)) -> Void {
        let endpoint = "POST /sessions"
        let btTraceId = UUID().uuidString
        logBeginningOfApiCall(endpoint: endpoint, btTraceId: btTraceId)
        
        SessionsAPI.createWithRequestBuilder().addBasisTheoryElementHeaders(apiKey: getApiKey(apiKey), btTraceId: btTraceId).execute { result in
            completeApiRequest(endpoint: endpoint, btTraceId: btTraceId, result: result, completion: completion)
        }
    }
    
    public static func getTokenById(id: String, apiKey: String? = nil, completion: @escaping ((_ data: GetTokenByIdResponse?, _ error: Error?) -> Void)) -> Void {
        let endpoint = "GET /tokens/id"
        let btTraceId = UUID().uuidString
        logBeginningOfApiCall(endpoint: endpoint, btTraceId: btTraceId)
        
        TokensAPI.getByIdWithRequestBuilder(id: id).addBasisTheoryElementHeaders(apiKey: getApiKey(apiKey), btTraceId: btTraceId).execute { result in
            do {
                let token = try result.get().body
                
                var json = JSON.dictionaryValue([:])
                BasisTheoryElements.traverseJsonDictionary(dictionary: token.data!.value as! [String:Any], json: &json)
                
                completion(token.toGetTokenByIdResponse(data: json), nil)
                TelemetryLogging.info("Successful API response", attributes: [
                    "endpoint": endpoint,
                    "BT-TRACE-ID": btTraceId,
                    "apiSuccess": true
                ])
            } catch {
                completion(nil, error)
                TelemetryLogging.error("Unsuccessful API response", error: error, attributes: [
                    "endpoint": endpoint,
                    "BT-TRACE-ID": btTraceId,
                    "apiSuccess": false
                ])
            }
        }
    }
    
    public static func post(url: String, payload: [String: Any]?, config: Config?, completion: @escaping ((_ request: URLResponse?, _ data: JSON?, _ error: Error?) -> Void)) -> Void {
        TelemetryLogging.info("Making POST request to \(url)")
        
        HttpClientHelpers.executeRequest(method: HttpMethod.post, url: url, payload: payload, config: config, completion: completion)
    }
    
    public static func put(url: String, payload: [String: Any]?, config: Config?, completion: @escaping ((_ request: URLResponse?, _ data: JSON?, _ error: Error?) -> Void)) -> Void {
        TelemetryLogging.info("Making PUT request to \(url)")
        
        HttpClientHelpers.executeRequest(method: HttpMethod.put, url: url, payload: payload, config: config, completion: completion)
    }
    
    public static func patch(url: String, payload: [String: Any]?, config: Config?, completion: @escaping ((_ request: URLResponse?, _ data: JSON?, _ error: Error?) -> Void)) -> Void {
        TelemetryLogging.info("Making PATCH request to \(url)")
        
        HttpClientHelpers.executeRequest(method: HttpMethod.patch, url: url, payload: payload, config: config, completion: completion)
    }
    
    public static func get(url: String, config: Config?, completion: @escaping ((_ request: URLResponse?, _ data: JSON?, _ error: Error?) -> Void)) -> Void {
        TelemetryLogging.info("Making GET request to \(url)")
        
        HttpClientHelpers.executeRequest(method: HttpMethod.get, url: url, payload: nil, config: config, completion: completion)
    }
    
    public static func delete(url: String, config: Config?, completion: @escaping ((_ request: URLResponse?, _ data: JSON?, _ error: Error?) -> Void)) -> Void {
        TelemetryLogging.info("Making DELETE request to \(url)")
        
        HttpClientHelpers.executeRequest(method: HttpMethod.delete, url: url, payload: nil, config: config, completion: completion)
    }
    
    internal static func replaceElementRefs(body: inout [String: Any], endpoint: String, btTraceId: String? = nil) throws -> Void {
        for (key, val) in body {
            if var v = val as? [String: Any] {
                try replaceElementRefs(body: &v, endpoint: endpoint, btTraceId: btTraceId)
                body[key] = v
            } else if let v = val as? ElementReferenceProtocol {
                let textValue = v.getValue()
                
                if !v.isComplete! {
                    TelemetryLogging.warn("Tried to tokenize while element is incomplete", attributes: [
                        "elementId": v.elementId,
                        "endpoint": endpoint,
                        "BT-TRACE-ID": btTraceId,
                    ])
                    
                    throw TokenizingError.invalidInput
                }

                switch (v.getValueType) {
                case .int:
                    body[key] = Int(textValue!)
                case .double:
                    body[key] = Double(textValue!)
                case .bool:
                    body[key] = Bool(textValue!)
                case .string:
                    body[key] = textValue
                case .none:
                    body[key] = textValue
                }

                TelemetryLogging.info("Retrieving element value for API call", attributes: [
                    "elementId": v.elementId,
                    "endpoint": endpoint,
                    "BT-TRACE-ID": btTraceId,
                ])
            }
        }
    }
    
    internal static func traverseJsonDictionary(dictionary: [String: Any], json: inout JSON, transformValue: ((_ val: Any) -> JSON)? = JSON.createElementValueReference) {
        for (key, value) in dictionary {
            if let value = value as? [String: Any] {
                json[key] = JSON.dictionaryValue([:])
                
                traverseJsonDictionary(dictionary: value, json: &json[key]!, transformValue: transformValue)
            } else if let value = value as? [Any] {
                json[key] = JSON.arrayValue([])
                
                traverseJsonArray(array: value, json: &json[key]!, transformValue: transformValue)
            } else {
                json[key] = transformValue!(value)
            }
        }
    }
    
    internal static func traverseJsonArray(array: [Any], json: inout JSON, transformValue: ((_ val: Any) -> JSON)? = JSON.createElementValueReference) {
        for (index, value) in array.enumerated() {
            if let value = value as? [String: Any] {
                json[index] = JSON.dictionaryValue([:])
                
                traverseJsonDictionary(dictionary: value, json: &json[index]!, transformValue: transformValue)
            } else if let value = value as? [Any] {
                json[index] = JSON.arrayValue([])
                
                traverseJsonArray(array: value, json: &json[index]!, transformValue: transformValue)
            } else {
                json[index] = transformValue!(value)
            }
        }
    }
}

