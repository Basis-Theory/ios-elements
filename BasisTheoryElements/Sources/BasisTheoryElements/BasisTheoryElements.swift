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
        var headers: [String: String] = [
            "User-Agent": "BasisTheory iOS Elements",
            "BT-API-KEY": apiKey,
            "BT-TRACE-ID": btTraceId
        ]

        if let deviceInfo = getEncodedDeviceInfo() {
            headers["BT-DEVICE-INFO"] = deviceInfo
        }

        addHeaders(headers)

        return self
    }
}

public enum Environment {
    case TEST
    case US
    case EU

    var url: String {
        switch self {
        case .TEST:
            return "https://api.test.basistheory.com"
        case .US, .EU:
            return "https://api.basistheory.com"
        }
    }
}

final public class BasisTheoryElements {
    public static let version = "4.8.0" // do not modify. updated through CI
    public static var apiKey: String = ""

    internal static var _basePath: String? = nil
    internal static var _environment: Environment? = nil
    internal static var _computedBasePath: String = "https://api.basistheory.com"

    public static var environment: Environment? {
        get { _environment }
        set {
            _environment = newValue
            if _basePath == nil, let env = newValue {
                _computedBasePath = env.url
            }
        }
    }

    public static var basePath: String {
        get {
            if let explicitPath = _basePath {
                return explicitPath
            }
            return _computedBasePath
        }
        set {
            _basePath = newValue
            _computedBasePath = newValue
        }
    }

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

    public static func encryptToken(input: EncryptTokenRequest) throws -> EncryptTokenResponse {
        switch input.tokenRequests {
        case .single(let singleRequest):
            // Handle single token request - return structured type
            let encryptedData = try encryptSingleTokenData(
                tokenRequest: singleRequest,
                recipientPublicKey: input.publicKey,
                keyId: input.keyId
            )

            guard let type = singleRequest["type"] as? String else {
                throw TokenizingError.invalidInput
            }

            TelemetryLogging.info("Successful single token encryption", attributes: [
                "encryptionSuccess": true,
                "tokenCount": 1
            ])

            return .single(EncryptedToken(encrypted: encryptedData, type: type))

        case .multiple(let multipleRequests):
            // Handle multiple token requests - return structured dictionary
            var encryptedTokens: [String: EncryptedToken] = [:]

            for (tokenName, tokenRequest) in multipleRequests {
                let encryptedData = try encryptSingleTokenData(
                    tokenRequest: tokenRequest,
                    recipientPublicKey: input.publicKey,
                    keyId: input.keyId
                )

                guard let type = tokenRequest["type"] as? String else {
                    throw TokenizingError.invalidInput
                }

                encryptedTokens[tokenName] = EncryptedToken(encrypted: encryptedData, type: type)
            }

            TelemetryLogging.info("Successful multiple token encryption", attributes: [
                "encryptionSuccess": true,
                "tokenCount": encryptedTokens.count
            ])

            return .multiple(encryptedTokens)
        }
    }

    private static func encryptSingleTokenData(
        tokenRequest: [String: Any],
        recipientPublicKey: String,
        keyId: String
    ) throws -> String {
        var mutableTokenRequest = tokenRequest

        try replaceElementRefs(body: &mutableTokenRequest, endpoint: "LOCAL /encrypt-token", btTraceId: nil)

        guard let dataField = mutableTokenRequest["data"] else {
            throw TokenizingError.invalidInput
        }

        let jsonData = try JSONSerialization.data(withJSONObject: dataField, options: [])

        return try JWEEncryption.encrypt(
            payload: jsonData,
            recipientPublicKey: recipientPublicKey,
            keyId: keyId
        )
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

    public static func createTokenIntent(
        request: CreateTokenIntentRequest, apiKey: String? = nil,
        completion: @escaping ((_ data: TokenIntent?, _ error: Error?) -> Void)
    ) {
        TelemetryLogging.info("Creating token intent")

        let client = TokenIntentClient(apiKey: getApiKey(apiKey), baseURL: basePath)

        client.createTokenIntent(request: request) { result in
            switch result {
            case .success(let tokenIntent):
                completion(tokenIntent, nil)
            case .failure(let error):
                completion(nil, error)
            }
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

    #if DEBUG
    internal static func _resetConfiguration() {
        _basePath = nil
        _environment = nil
        _computedBasePath = "https://api.basistheory.com"
    }
    #endif
}

