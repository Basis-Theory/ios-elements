import Foundation
import CryptoKit

extension String {
    
    func base64URLEncodedString() -> String? {
        self.data(using: .utf8)?.base64URLEncodedString()
    }
    
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

extension UInt32 {
    var bigEndianData: Data {
        var be = bigEndian
        return Data(bytes: &be, count: 4)
    }
}

extension Data {
   func base64URLEncodedString() -> String {
       return self.base64EncodedString()
           .replacingOccurrences(of: "+", with: "-")
           .replacingOccurrences(of: "/", with: "_")
           .replacingOccurrences(of: "=", with: "")
   }
}


public class JWEEncryption {
    public enum Constants {
        public static let keyType = "OKP"
        public static let curve = "X25519"
        public static let algorithm = "ECDH-ES"
        public static let encAlg = "A256GCM"
    }
    
    public enum JWEError: Error {
        case invalidPublicKey
        case errorConvertPayloadToString
        case invalidKeyId
        case keyAgreementFailed
        case encryptionFailed
    }
        
    /// Encrypts the payload using ECDH-ES (Curve25519) and AES-GCM, returns JWE compact serialization string.
    /// - Parameters:
    ///   - payload: Data to encrypt
    ///   - recipientPublicKeyBase64: Recipient public key (base64 or PEM string)
    ///   - keyId: Key identifier (kid)
    public static func encrypt(
        payload: Data,
        recipientPublicKey: String,
        keyId: String
    ) throws -> String {

        guard !recipientPublicKey.isEmpty else {
            throw JWEError.invalidPublicKey
        }

        guard !keyId.isEmpty else {
            throw JWEError.invalidKeyId
        }
        
        // --- 1. Clean and decode the recipient public key
        let cleanedKey = recipientPublicKey.removePemFormat()
        
        guard let recipientKeyData = Data(base64Encoded: cleanedKey) else {
            throw JWEError.invalidPublicKey
        }
        let recipientPubKey: Curve25519.KeyAgreement.PublicKey
        do {
            recipientPubKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: recipientKeyData)
        } catch {
            throw JWEError.invalidPublicKey
        }
        
        // --- 2. Generate ephemeral key pair (sender)
        let senderKeyPair = Curve25519.KeyAgreement.PrivateKey()
        let senderPubKey = senderKeyPair.publicKey
        
        // --- 3. ECDH key agreement (shared secret)
        let sharedSecret: SharedSecret
        do {
            sharedSecret = try senderKeyPair.sharedSecretFromKeyAgreement(with: recipientPubKey)
        } catch {
            throw JWEError.keyAgreementFailed
        }
        
        // --- 4. Derive Content Encryption Key (CEK)
        let derivedKey = deriveKey(sharedSecret: sharedSecret)
        
        // --- 5. Build the JWE Protected Header JSON
        let headerDict: [String: Any] = [
            "alg": Constants.algorithm,
            "enc": Constants.encAlg, 
            "kid": keyId,
            "epk": [
                "kty": Constants.keyType,
                "crv": Constants.curve,
                "x": senderPubKey.rawRepresentation.base64URLEncodedString()
            ]
        ]
        
        let headerData = try JSONSerialization.data(withJSONObject: headerDict, options: .sortedKeys)
        let headerBase64 = headerData.base64URLEncodedString()
        
        // --- 6. Encrypt with AES-GCM using encoded header as AAD
        let nonce = AES.GCM.Nonce()
        let aad = headerBase64.data(using: .utf8)! // AAD must be ASCII bytes of base64url header
        
        let sealedBox: AES.GCM.SealedBox
        do {
            sealedBox = try AES.GCM.seal(payload, using: SymmetricKey(data: derivedKey), nonce: nonce, authenticating: aad)
        } catch {
            throw JWEError.encryptionFailed
        }
        
        // --- 7. Assemble Compact Serialization
        let jweToken = [
            headerBase64,
            "",
            Data(sealedBox.nonce).base64URLEncodedString(),
            sealedBox.ciphertext.base64URLEncodedString(),
            sealedBox.tag.base64URLEncodedString()
        ].joined(separator: ".")
        
        return jweToken
    }
    
    // Derive key using Concat KDF
    private static func deriveKey(sharedSecret: SharedSecret) -> Data {
        // Extract the raw shared secret bytes
        let sharedSecretData = sharedSecret.withUnsafeBytes { Data($0) }
        
        // Use proper Concat KDF as per RFC 7518 (not HKDF)
        let kdfInfo = getKdfInfo()
        
        let derivedKey = concatKDF(sharedSecret: sharedSecretData, keyDataLen: 32, otherInfo: kdfInfo)
        
        return derivedKey
    }
    
    // Implement Concat KDF as per RFC 7518 Section 4.1.3
    private static func concatKDF(sharedSecret: Data, keyDataLen: Int, otherInfo: Data) -> Data {
        var derivedKey = Data()
        var counter: UInt32 = 1
        
        while derivedKey.count < keyDataLen {
            var hash = SHA256()
            
            // Counter as big-endian 32-bit integer
            var counterBytes = counter.bigEndianData
            hash.update(data: counterBytes)
            
            // Shared secret
            hash.update(data: sharedSecret)
            
            // Other info (KDF parameters)
            hash.update(data: otherInfo)
            
            let digest = hash.finalize()
            derivedKey.append(contentsOf: digest)
            
            counter += 1
        }
        
        // Return only the required number of bytes
        return Data(derivedKey.prefix(keyDataLen))
    }
    
    // Get KDF info
    private static func getKdfInfo() -> Data {
        var info = Data()
        
        // Algorithm "A256GCM" 
        let algBytes = Constants.encAlg.data(using: .ascii)!
        info.append(UInt32(algBytes.count).bigEndianData)  // Big-endian length
        info.append(algBytes)
        
        // PartyUInfo = null (0 bytes)
        info.append(UInt32(0).bigEndianData)
        
        // PartyVInfo = null (0 bytes) 
        info.append(UInt32(0).bigEndianData)
        
        // SuppPubInfo = Key length in bits (256)
        info.append(UInt32(256).bigEndianData)
      
        return info
    }
}
