import Foundation
import JSONWebKey
import JSONWebEncryption
import JSONWebAlgorithms

extension String {
    /**
     * Removes PEM format headers, footers, and whitespace from a public key string.
     * Handles formats like:
     * -----BEGIN PUBLIC KEY-----
     * [base64 content]
     * -----END PUBLIC KEY-----
     */
    func removePemFormat() -> String {
        return self.replacingOccurrences(of: "-----.*?-----|\\s", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public class JWEEncryption {
    public enum EncryptionConstants {
        public static let keyType: JWK.KeyType = .octetKeyPair
        public static let curve: JWK.CryptographicCurve = .x25519
        public static let algorithm = "ECDH-ES"
        public static let encryptionAlgorithm: ContentEncryptionAlgorithm = .a256GCM
    }
    
    public enum JWKError: Error {
        case invalidPublicKey
        case errorConvertPayloadToString
        case invalidKeyId
    }
    
    /// Creates a JWK from a public key string
    /// - Parameter publicKey: The base64 encoded public key string (can include PEM format)
    /// - Returns: JWK representation of the public key
    /// - Throws: JWKError.invalidPublicKey if the public key is not valid base64
    public static func createJWK(from publicKey: String) throws -> JWK {
        guard !publicKey.isEmpty else {
            throw JWKError.invalidPublicKey
        }

        let cleanedKey = publicKey.removePemFormat()
        guard let keyData = Data(base64Encoded: cleanedKey) else {
            throw JWKError.invalidPublicKey
        }
        
        return JWK(
            keyType: EncryptionConstants.keyType,
            algorithm: EncryptionConstants.algorithm,
            curve: EncryptionConstants.curve,
            x: keyData
        )
    }

    /// Encrypts JSON data using ECDH-ES and AES-GCM
    /// - Parameters:
    ///   - payload: The JSON object to encrypt
    ///   - recipientPublicKey: The recipient's public key JWK
    ///   - keyId: The key identifier to include in the JWE header
    /// - Returns: JWE compact serialization string
    public static func encrypt(payload: Data, recipientPublicKey: JWK, keyId: String) throws -> String {

        guard !keyId.isEmpty else {
            throw JWKError.invalidKeyId
        }
        
        let protectedHeader = DefaultJWEHeaderImpl(
            keyManagementAlgorithm: .ecdhES,
            encodingAlgorithm: .a256GCM,
            keyID: keyId
        )

        let serialization = try JWE(
            payload: payload,
            protectedHeader: protectedHeader,
            recipientKey: recipientPublicKey
        )

        return serialization.compactSerialization
    }

}
