import Foundation
import AnyCodable

extension AnyCodable {
    /// Recursively unwraps `AnyCodable`/`AnyDecodable` values into native Swift types
    /// so that nested dictionaries become `[String: Any]` instead of `[String: AnyDecodable]`.
    func deepUnwrap() -> Any {
        let raw = self.value
        return AnyCodable.unwrap(raw)
    }

    private static func unwrap(_ value: Any) -> Any {
        switch value {
        case let dict as [String: Any]:
            return dict.mapValues { unwrap($0) }
        case let array as [Any]:
            return array.map { unwrap($0) }
        case let codable as AnyCodable:
            return unwrap(codable.value)
        default:
            // Check via Mirror for AnyDecodable (same module, shares _AnyDecodable protocol)
            let mirror = Mirror(reflecting: value)
            if mirror.displayStyle == nil,
               let child = mirror.children.first(where: { $0.label == "value" }) {
                return unwrap(child.value)
            }
            return value
        }
    }
}
