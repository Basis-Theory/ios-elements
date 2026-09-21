import XCTest
@testable import BasisTheoryElements

final class EnvironmentConfigurationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        BasisTheoryElements._resetConfiguration()
    }

    override func tearDown() {
        BasisTheoryElements._resetConfiguration()
        super.tearDown()
    }

    func testDefaultBasePath() {
        XCTAssertEqual(BasisTheoryElements.basePath, "https://api.basistheory.com")
    }

    func testDefaultEnvironment() {
        XCTAssertNil(BasisTheoryElements.environment)
    }

    func testSettingEnvironmentToTEST() {
        BasisTheoryElements.environment = .TEST

        XCTAssertEqual(BasisTheoryElements.basePath, "https://api.test.basistheory.com")
        XCTAssertEqual(BasisTheoryElements.environment, .TEST)
    }

    func testSettingEnvironmentToUS() {
        BasisTheoryElements.environment = .US

        XCTAssertEqual(BasisTheoryElements.basePath, "https://api.us.basistheory.com")
        XCTAssertEqual(BasisTheoryElements.environment, .US)
    }

    func testSettingEnvironmentToEU() {
        BasisTheoryElements.environment = .EU

        XCTAssertEqual(BasisTheoryElements.basePath, "https://api.eu.basistheory.com")
        XCTAssertEqual(BasisTheoryElements.environment, .EU)
    }

    func testSettingBasePathExplicitly() {
        BasisTheoryElements.basePath = "https://custom.api.com"

        XCTAssertEqual(BasisTheoryElements.basePath, "https://custom.api.com")
    }

    func testSettingBasePathToFlockDev() {
        BasisTheoryElements.basePath = "https://api.flock-dev.com"

        XCTAssertEqual(BasisTheoryElements.basePath, "https://api.flock-dev.com")
    }

    func testBasePathTakesPrecedenceOverEnvironment() {
        BasisTheoryElements.environment = .TEST
        XCTAssertEqual(BasisTheoryElements.basePath, "https://api.test.basistheory.com")

        BasisTheoryElements.basePath = "https://custom.api.com"

        XCTAssertEqual(BasisTheoryElements.basePath, "https://custom.api.com")
        XCTAssertEqual(BasisTheoryElements.environment, .TEST)
    }

    func testSettingEnvironmentAfterBasePathDoesNotOverride() {
        BasisTheoryElements.basePath = "https://custom.api.com"

        BasisTheoryElements.environment = .TEST

        XCTAssertEqual(BasisTheoryElements.basePath, "https://custom.api.com")
        XCTAssertEqual(BasisTheoryElements.environment, .TEST)
    }

    func testSwitchingBetweenEnvironments() {
        BasisTheoryElements.environment = .TEST
        XCTAssertEqual(BasisTheoryElements.basePath, "https://api.test.basistheory.com")

        BasisTheoryElements.environment = .US

        XCTAssertEqual(BasisTheoryElements.basePath, "https://api.us.basistheory.com")
    }

    func testRegionalEnvironmentsResolveToDistinctHosts() {
        BasisTheoryElements.environment = .US
        let usPath = BasisTheoryElements.basePath

        BasisTheoryElements.environment = .EU

        XCTAssertNotEqual(usPath, BasisTheoryElements.basePath)
        XCTAssertEqual(usPath, "https://api.us.basistheory.com")
        XCTAssertEqual(BasisTheoryElements.basePath, "https://api.eu.basistheory.com")
    }

    func testRegionalEnvironmentIsOptIn() {
        XCTAssertEqual(BasisTheoryElements.basePath, "https://api.basistheory.com")

        BasisTheoryElements.environment = .EU

        XCTAssertEqual(BasisTheoryElements.basePath, "https://api.eu.basistheory.com")
    }

    func testExplicitBasePathBeatsRegionalEnvironment() {
        BasisTheoryElements.basePath = "https://custom.api.com"

        BasisTheoryElements.environment = .EU

        XCTAssertEqual(BasisTheoryElements.basePath, "https://custom.api.com")
    }

    func testClearingEnvironmentReturnsToTheDefault() {
        BasisTheoryElements.environment = .TEST
        XCTAssertEqual(BasisTheoryElements.basePath, "https://api.test.basistheory.com")

        BasisTheoryElements.environment = nil

        XCTAssertEqual(BasisTheoryElements.basePath, "https://api.basistheory.com")
    }

    func testClearingARegionReturnsToTheDefault() {
        BasisTheoryElements.environment = .EU
        XCTAssertEqual(BasisTheoryElements.basePath, "https://api.eu.basistheory.com")

        BasisTheoryElements.environment = nil

        XCTAssertEqual(BasisTheoryElements.basePath, "https://api.basistheory.com")
    }

    func testSettingEnvironmentToDEFAULT() {
        BasisTheoryElements.environment = .DEFAULT

        XCTAssertEqual(BasisTheoryElements.basePath, "https://api.basistheory.com")
        XCTAssertEqual(BasisTheoryElements.environment, .DEFAULT)
    }

    func testSwitchingFromARegionBackToDEFAULT() {
        BasisTheoryElements.environment = .EU
        XCTAssertEqual(BasisTheoryElements.basePath, "https://api.eu.basistheory.com")

        BasisTheoryElements.environment = .DEFAULT

        XCTAssertEqual(BasisTheoryElements.basePath, "https://api.basistheory.com")
    }

    func testClearingEnvironmentDoesNotOverrideAnExplicitBasePath() {
        BasisTheoryElements.basePath = "https://custom.api.com"

        BasisTheoryElements.environment = nil

        XCTAssertEqual(BasisTheoryElements.basePath, "https://custom.api.com")
    }

    func testBackwardsCompatibilityWithDirectBasePathAssignment() {
        BasisTheoryElements.basePath = "https://api.flock-dev.com"

        XCTAssertEqual(BasisTheoryElements.basePath, "https://api.flock-dev.com")
        XCTAssertNil(BasisTheoryElements.environment)
    }

    func testBackwardsCompatibilityResettingToDefault() {
        BasisTheoryElements.basePath = "https://custom.com"

        BasisTheoryElements.basePath = "https://api.basistheory.com"

        XCTAssertEqual(BasisTheoryElements.basePath, "https://api.basistheory.com")
    }

    func testTokenIntentClientUsesEnvironmentConfiguration() {
        BasisTheoryElements.environment = .TEST

        let client = TokenIntentClient(apiKey: "test_key")

        XCTAssertEqual(BasisTheoryElements.basePath, "https://api.test.basistheory.com")
    }

    func testTokenIntentClientWithExplicitBaseURL() {
        BasisTheoryElements.environment = .TEST

        let client = TokenIntentClient(apiKey: "test_key", baseURL: "https://custom.com")

        XCTAssertEqual(BasisTheoryElements.basePath, "https://api.test.basistheory.com")
    }
}

