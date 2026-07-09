import Foundation

public enum StatusAppConfiguration {
    public static let registryBaseURLKey = "STATUS_REGISTRY_URL"
    public static let defaultRegistryBaseURL = URL(string: "https://status-registry.hakobs.com")!

    public static func registryBaseURL(
        processInfo: ProcessInfo = .processInfo,
        userDefaults: UserDefaults = .standard,
        bundle: Bundle = .main
    ) -> URL {
        registryBaseURL(
            environment: processInfo.environment,
            userDefaults: userDefaults,
            bundleValue: bundle.object(forInfoDictionaryKey: registryBaseURLKey) as? String
        )
    }

    public static func registryBaseURL(
        environment: [String: String],
        userDefaults: UserDefaults,
        bundleValue: String?
    ) -> URL {
        urlValue(userDefaults.string(forKey: registryBaseURLKey))
            ?? urlValue(environment[registryBaseURLKey])
            ?? urlValue(bundleValue)
            ?? defaultRegistryBaseURL
    }

    public static func registryHost(
        processInfo: ProcessInfo = .processInfo,
        userDefaults: UserDefaults = .standard,
        bundle: Bundle = .main
    ) -> String {
        registryBaseURL(processInfo: processInfo, userDefaults: userDefaults, bundle: bundle).host
            ?? defaultRegistryBaseURL.host
            ?? "status-registry.hakobs.com"
    }

    public static func registryHost(
        environment: [String: String],
        userDefaults: UserDefaults,
        bundleValue: String?
    ) -> String {
        registryBaseURL(environment: environment, userDefaults: userDefaults, bundleValue: bundleValue).host
            ?? defaultRegistryBaseURL.host
            ?? "status-registry.hakobs.com"
    }

    private static func urlValue(_ value: String?) -> URL? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              value.isEmpty == false,
              let url = URL(string: value),
              let scheme = url.scheme,
              scheme == "https" || scheme == "http",
              url.host?.isEmpty == false
        else {
            return nil
        }
        return url
    }
}
