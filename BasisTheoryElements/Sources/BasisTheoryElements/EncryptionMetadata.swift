import Foundation

public struct EncryptionMetadata: Codable {
    public var cek: CekMetadata?
    public var kek: KekMetadata?
    
    public init(cek: CekMetadata? = nil, kek: KekMetadata? = nil) {
        self.cek = cek
        self.kek = kek
    }
}

public struct CekMetadata: Codable {
    public var alg: String?
    public var enc: String?
    
    public init(alg: String? = nil, enc: String? = nil) {
        self.alg = alg
        self.enc = enc
    }
}

public struct KekMetadata: Codable {
    public var alg: String?
    public var prov: String?
    
    public init(alg: String? = nil, prov: String? = nil) {
        self.alg = alg
        self.prov = prov
    }
}
