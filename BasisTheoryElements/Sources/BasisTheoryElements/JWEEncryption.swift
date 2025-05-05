import Foundation
import JSONWebKey
import JSONWebEncryption
import JSONWebAlgorithms

public class JWEEncryption {
    public enum EncryptionConstants {
        public static let keyType: JWK.KeyType = .octetKeyPair
        public static let curve: JWK.CryptographicCurve = .x25519
        public static let algorithm = "ECDH-ES"
        public static let encryptionAlgorithm: ContentEncryptionAlgorithm = .a256GCM
    }
    
    public enum JWKError: Error {
        case invalidBase64Key
    }
    
    /// Creates a JWK from a public key string
    /// - Parameter publicKey: The base64 encoded public key string
    /// - Returns: JWK representation of the public key
    /// - Throws: JWKError.invalidBase64Key if the public key is not valid base64
    public static func createJWK(from publicKey: String) throws -> JWK {
        guard let keyData = Data(base64Encoded: publicKey) else {
            throw JWKError.invalidBase64Key
        }
        
        return JWK(
            keyType: EncryptionConstants.keyType,
            algorithm: EncryptionConstants.algorithm,
            curve: EncryptionConstants.curve,
            x: keyData
        )
    }

    /// Encrypts data using ECDH-ES and AES-GCM
    /// - Parameters:
    ///   - data: The data to encrypt
    ///   - recipientPublicKey: The recipient's public key JWK
    /// - Returns: JWE compact serialization string
    public static func encrypt(data: Data, recipientPublicKey: JWK) throws -> String {
        let serialization = try JWE(
            payload: data,
            keyManagementAlg: .ecdhES,
            encryptionAlgorithm: .a256GCM,
            recipientKey: recipientPublicKey
        )

        return serialization.compactSerialization
    }

}
