import Foundation
import Testing
@testable import StatusCore

@Test func registryBaseURLUsesDefaultWhenNoOverrideExists() {
    let defaults = UserDefaults(suiteName: "StatusAppConfigurationTests.default")!
    defaults.removeObject(forKey: StatusAppConfiguration.registryBaseURLKey)

    #expect(StatusAppConfiguration.registryBaseURL(environment: [:], userDefaults: defaults, bundleValue: nil) == StatusAppConfiguration.defaultRegistryBaseURL)
}

@Test func registryBaseURLUsesUserDefaultsBeforeEnvironmentAndBundle() {
    let defaults = UserDefaults(suiteName: "StatusAppConfigurationTests.userDefaults")!
    defaults.set("https://user-defaults-registry.example.test", forKey: StatusAppConfiguration.registryBaseURLKey)
    defer { defaults.removeObject(forKey: StatusAppConfiguration.registryBaseURLKey) }

    let url = StatusAppConfiguration.registryBaseURL(
        environment: [StatusAppConfiguration.registryBaseURLKey: "https://environment-registry.example.test"],
        userDefaults: defaults,
        bundleValue: "https://bundle-registry.example.test"
    )

    #expect(url.absoluteString == "https://user-defaults-registry.example.test")
}

@Test func registryBaseURLUsesEnvironmentBeforeBundle() {
    let defaults = UserDefaults(suiteName: "StatusAppConfigurationTests.environment")!
    defaults.removeObject(forKey: StatusAppConfiguration.registryBaseURLKey)

    let url = StatusAppConfiguration.registryBaseURL(
        environment: [StatusAppConfiguration.registryBaseURLKey: "https://environment-registry.example.test"],
        userDefaults: defaults,
        bundleValue: "https://bundle-registry.example.test"
    )

    #expect(url.absoluteString == "https://environment-registry.example.test")
}

@Test func registryBaseURLIgnoresInvalidOverrides() {
    let defaults = UserDefaults(suiteName: "StatusAppConfigurationTests.invalid")!
    defaults.set("not a registry url", forKey: StatusAppConfiguration.registryBaseURLKey)
    defer { defaults.removeObject(forKey: StatusAppConfiguration.registryBaseURLKey) }

    let url = StatusAppConfiguration.registryBaseURL(
        environment: [StatusAppConfiguration.registryBaseURLKey: "ftp://registry.example.test"],
        userDefaults: defaults,
        bundleValue: "https://bundle-registry.example.test"
    )

    #expect(url.absoluteString == "https://bundle-registry.example.test")
}

@Test func registryHostUsesConfiguredRegistryHost() {
    let defaults = UserDefaults(suiteName: "StatusAppConfigurationTests.host")!
    defaults.removeObject(forKey: StatusAppConfiguration.registryBaseURLKey)

    let host = StatusAppConfiguration.registryHost(
        environment: [StatusAppConfiguration.registryBaseURLKey: "https://temporary-worker.example.workers.dev"],
        userDefaults: defaults,
        bundleValue: nil
    )

    #expect(host == "temporary-worker.example.workers.dev")
}
