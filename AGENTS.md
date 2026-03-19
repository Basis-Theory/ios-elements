# iOS Elements

Swift SDK providing secure UI components for collecting sensitive data on iOS.

## Build & Test

```bash
swift build          # Build via SPM
swift test           # Unit tests (SPM — but see note below)
```

## Project Structure

- `BasisTheoryElements/Sources/BasisTheoryElements/` — Library source (all `.swift` files)
- `IntegrationTester/UnitTests/` — Unit tests (Xcode project, NOT SPM test target)
- `IntegrationTester/AcceptanceTests/` — Acceptance tests (require API key + Xcode)
- `Package.swift` — SPM package definition (no test targets defined here)
- `BasisTheoryElements.podspec` — CocoaPods spec

## Gotchas

- **No SPM test target**: `Package.swift` does NOT define test targets. Unit tests are in `IntegrationTester/IntegrationTester.xcodeproj` — run via Xcode, not `swift test`.
- **Dual distribution**: SPM (`Package.swift`) + CocoaPods (`BasisTheoryElements.podspec`). Both must stay in sync.
- **CocoaPods has a different dependency**: Podspec depends on `BasisTheory` pod (v0.6.1), while SPM depends on `AnyCodable`. The CocoaPods build uses `COCOAPODS=1` preprocessor flag.
- **Version in 3 places**: CI updates version in `BasisTheoryElements.podspec` (s.version + :tag), and `BasisTheoryElements.swift` (`public static let version`). All three must match.
- **iOS 15+ minimum**: `platforms: [.iOS(.v15)]`
- **Swift 5.5**
- **Integration tests need config**: `IntegrationTester/Env.plist.example` shows required environment setup.
- **Resource bundles**: Podspec includes `Assets.xcassets` — don't move or rename the Resources directory.

## Release

Automated on push to `master`. CI bumps version tag, updates podspec + `BasisTheoryElements.swift` version + CHANGELOG, then runs `pod trunk push --allow-warnings`.

## Docs

- [iOS Elements SDK](https://developers.basistheory.com/docs/sdks/mobile/ios/)
