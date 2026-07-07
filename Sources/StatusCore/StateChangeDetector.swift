import CryptoKit
import Foundation

public enum StateObservationResult: Equatable, Sendable {
    case firstObservation(current: ResourceStateSnapshot)
    case unchanged(current: ResourceStateSnapshot)
    case changed(previous: ResourceStateSnapshot, current: ResourceStateSnapshot)
}

public final class StateChangeDetector {
    private let store: StatusPersistenceStore
    private let encoder: JSONEncoder

    public init(store: StatusPersistenceStore) {
        self.store = store
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.sortedKeys]
    }

    public func record(
        resourceID: String,
        state: [String: String],
        jobID: String? = nil,
        capturedAt: Date
    ) throws -> StateObservationResult {
        let current = ResourceStateSnapshot(
            resourceID: resourceID,
            state: state,
            stateHash: try hash(state),
            jobID: jobID,
            capturedAt: capturedAt
        )

        guard let previous = try store.resourceStateSnapshot(resourceID: resourceID) else {
            try store.upsertResourceStateSnapshot(current)
            return .firstObservation(current: current)
        }

        try store.upsertResourceStateSnapshot(current)

        if previous.stateHash == current.stateHash {
            return .unchanged(current: current)
        }

        return .changed(previous: previous, current: current)
    }

    public func hash(_ state: [String: String]) throws -> String {
        let data = try encoder.encode(state)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
