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

    public init(
        type: String,
        label: String,
        resourceType: String,
        defaultSeverity: Severity,
        notificationDefault: NotificationMode,
        emissionModel: EventEmissionModel = .stateTransition,
        dedupBucket: EventDateBucket? = nil
    ) {
        self.type = type
        self.label = label
        self.resourceType = resourceType
        self.defaultSeverity = defaultSeverity
        self.notificationDefault = notificationDefault
        self.emissionModel = emissionModel
        self.dedupBucket = dedupBucket
    }
}
