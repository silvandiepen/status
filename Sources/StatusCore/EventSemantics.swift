import CryptoKit
import Foundation

public enum EventEmissionModel: String, Codable, CaseIterable, Sendable {
    case stateTransition = "state-transition"
    case condition = "condition"
    case passThrough = "pass-through"
}

public enum EventDateBucket: String, Codable, CaseIterable, Sendable {
    case fifteenMinutes = "15m"
    case oneHour = "1h"
    case oneDay = "1d"
    case sevenDays = "7d"
}

public struct EventFingerprintInput: Equatable, Sendable {
    public var provider: String
    public var eventType: String
    public var resourceID: String
    public var relevantState: String
    public var dateBucket: String?

    public init(provider: String, eventType: String, resourceID: String, relevantState: String, dateBucket: String? = nil) {
        self.provider = provider
        self.eventType = eventType
        self.resourceID = resourceID
        self.relevantState = relevantState
        self.dateBucket = dateBucket
    }
}

public enum EventFingerprint {
    public static func make(_ input: EventFingerprintInput) -> String {
        let source = [
            input.provider,
            input.eventType,
            input.resourceID,
            input.relevantState,
            input.dateBucket
        ]
        .compactMap(\.self)
        .joined(separator: ":")

        let digest = SHA256.hash(data: Data(source.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

public struct EventTypeDeclaration: Codable, Equatable, Sendable {
    public var type: String
    public var label: String
    public var resourceType: String
    public var defaultSeverity: Severity
    public var notificationDefault: NotificationMode
    public var emissionModel: EventEmissionModel
    public var dedupBucket: EventDateBucket?
    public var opensIncident: String?
    public var closedBy: String?

    public init(
        type: String,
        label: String,
        resourceType: String,
        defaultSeverity: Severity,
        notificationDefault: NotificationMode,
        emissionModel: EventEmissionModel = .stateTransition,
        dedupBucket: EventDateBucket? = nil,
        opensIncident: String? = nil,
        closedBy: String? = nil
    ) {
        self.type = type
        self.label = label
        self.resourceType = resourceType
        self.defaultSeverity = defaultSeverity
        self.notificationDefault = notificationDefault
        self.emissionModel = emissionModel
        self.dedupBucket = dedupBucket
        self.opensIncident = opensIncident
        self.closedBy = closedBy
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case label
        case resourceType
        case defaultSeverity
        case notificationDefault
        case emissionModel
        case dedupBucket
        case opensIncident
        case closedBy
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        label = try container.decode(String.self, forKey: .label)
        resourceType = try container.decode(String.self, forKey: .resourceType)
        defaultSeverity = try container.decode(Severity.self, forKey: .defaultSeverity)
        let notificationDefaultValue = try container.decode(String.self, forKey: .notificationDefault)
        notificationDefault = try Self.decodeNotificationMode(notificationDefaultValue)
        emissionModel = try container.decodeIfPresent(EventEmissionModel.self, forKey: .emissionModel) ?? .stateTransition
        dedupBucket = try container.decodeIfPresent(EventDateBucket.self, forKey: .dedupBucket)
        opensIncident = try container.decodeIfPresent(String.self, forKey: .opensIncident)
        closedBy = try container.decodeIfPresent(String.self, forKey: .closedBy)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(label, forKey: .label)
        try container.encode(resourceType, forKey: .resourceType)
        try container.encode(defaultSeverity, forKey: .defaultSeverity)
        try container.encode(Self.encodeNotificationMode(notificationDefault), forKey: .notificationDefault)
        try container.encode(emissionModel, forKey: .emissionModel)
        try container.encodeIfPresent(dedupBucket, forKey: .dedupBucket)
        try container.encodeIfPresent(opensIncident, forKey: .opensIncident)
        try container.encodeIfPresent(closedBy, forKey: .closedBy)
    }

    private static func decodeNotificationMode(_ value: String) throws -> NotificationMode {
        if let mode = NotificationMode(rawValue: value) {
            return mode
        }
        switch value {
        case "dashboard-only":
            return .dashboardOnly
        case "silent-automation":
            return .silentAutomation
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Unsupported notificationDefault '\(value)'."
                )
            )
        }
    }

    private static func encodeNotificationMode(_ mode: NotificationMode) -> String {
        switch mode {
        case .dashboardOnly:
            "dashboard-only"
        case .silentAutomation:
            "silent-automation"
        default:
            mode.rawValue
        }
    }
}
