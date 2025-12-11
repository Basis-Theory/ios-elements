import Foundation

public class TokenIntentClient {
    private let apiKey: String
    private let baseURL: String

    public init(apiKey: String, baseURL: String? = nil) {
        self.apiKey = apiKey
        self.baseURL = baseURL ?? BasisTheoryElements.basePath
    }

    // MARK: - Create Token Intent

    public func createTokenIntent(
        request: CreateTokenIntentRequest,
        completion: @escaping (Result<TokenIntent, Error>) -> Void
    ) {
        let endpoint = "POST /token-intents"
        let btTraceId = UUID().uuidString

        let url = URL(string: "\(baseURL)/token-intents")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "BT-API-KEY")

        if let encodedDeviceInfo = getEncodedDeviceInfo() {
            urlRequest.setValue(encodedDeviceInfo, forHTTPHeaderField: "BT-DEVICE-INFO")
        }

        // Create a mutable copy of the request data and replace element references
        var mutableData = request.data
        do {
            try BasisTheoryElements.replaceElementRefs(
                body: &mutableData, endpoint: endpoint, btTraceId: btTraceId)
        } catch {
            completion(.failure(error))
            return
        }

        // Create a new request with the processed data
        let processedRequest = CreateTokenIntentRequest(type: request.type, data: mutableData)

        do {
            urlRequest.httpBody = try JSONEncoder().encode(processedRequest)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(
                    .failure(
                        NSError(
                            domain: "TokenIntentClient", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            do {
                let tokenIntent = try JSONDecoder().decode(TokenIntent.self, from: data)
                completion(.success(tokenIntent))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - Async/await support

@available(iOS 13.0, *)
extension TokenIntentClient {
    public func createTokenIntent(request: CreateTokenIntentRequest) async throws -> TokenIntent {
        return try await withCheckedThrowingContinuation { continuation in
            createTokenIntent(request: request) { result in
                continuation.resume(with: result)
            }
        }
    }
}
