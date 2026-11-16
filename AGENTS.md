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

## Gotchas

- **No SPM test target**: `Package.swift` does NOT define test targets. Unit tests are in `IntegrationTester/IntegrationTester.xcodeproj` — run via Xcode, not `swift test`.
- **SPM only**: distributed through Swift Package Manager, which resolves versions from git tags. CocoaPods is frozen at 6.0.0 (Trunk is read-only); do not reintroduce a podspec.
- **Version constant**: CI updates `public static let version` in `BasisTheoryElements.swift` to match the release tag.
- **iOS 15+ minimum**: `platforms: [.iOS(.v15)]`
- **Swift 5.5**
- **Integration tests need config**: `IntegrationTester/Env.plist.example` shows required environment setup.
- **Resource bundles**: SPM processes `Assets.xcassets` automatically and exposes it as `Bundle.module` — don't move or rename the Resources directory.

## Release

Automated on push to `master`. CI cuts the version tag, then writes the `BasisTheoryElements.swift` version and CHANGELOG back to `master`. No CocoaPods publish.

## Docs

- [iOS Elements SDK](https://developers.basistheory.com/docs/sdks/mobile/ios/)
