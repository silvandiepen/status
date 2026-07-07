import Foundation

public struct PluginMappingCommitResult: Equatable, Sendable {
    public var resourceIDs: [String]
    public var eventResults: [EventIngestionResult]
    public var auditEntry: AuditEntry

    public init(resourceIDs: [String], eventResults: [EventIngestionResult], auditEntry: AuditEntry) {
        self.resourceIDs = resourceIDs
        self.eventResults = eventResults
        self.auditEntry = auditEntry
    }
}

public final class PluginMappingOutputCommitter {
    private let store: StatusPersistenceStore
    private let ingestor: EventIngestor
    private let stateDetector: StateChangeDetector

    public init(store: StatusPersistenceStore) {
        self.store = store
        self.ingestor = EventIngestor(store: store)
        self.stateDetector = StateChangeDetector(store: store)
    }

    public func commit(
        _ output: PluginMappingExecutionOutput,
        jobID: String? = nil,
        capturedAt: Date
    ) throws -> PluginMappingCommitResult {
        var resourceIDs: [String] = []
        for mappedResource in output.resources {
            let externalID = mappedResource.state["id"] ?? mappedResource.resource.id
            try store.upsertResource(
                mappedResource.resource,
                externalID: externalID,
                fields: mappedResource.state,
                seenAt: capturedAt
            )
            _ = try stateDetector.record(
                resourceID: mappedResource.resource.id,
                state: mappedResource.state,
                jobID: jobID,
                capturedAt: capturedAt
            )
            resourceIDs.append(mappedResource.resource.id)
        }

        let eventResults = try output.events.map { try ingestor.ingest($0) }
        let auditEntry = AuditEntry(
            id: auditID(jobID: jobID, capturedAt: capturedAt),
            title: "Plugin mapping output committed",
            detail: "\(resourceIDs.count) resources stored, \(eventResults.count) events processed.",
            timestamp: capturedAt,
            status: "success",
            jobID: jobID,
            eventID: singleInsertedEventID(from: eventResults)
        )
        try store.insertAuditEntry(auditEntry)

        return PluginMappingCommitResult(
            resourceIDs: resourceIDs,
            eventResults: eventResults,
            auditEntry: auditEntry
        )
    }

    private func auditID(jobID: String?, capturedAt: Date) -> String {
        if let jobID {
            return "aud_\(jobID)_mapping_commit"
        }
        return "aud_mapping_commit_\(Int(capturedAt.timeIntervalSince1970))"
    }

    private func singleInsertedEventID(from results: [EventIngestionResult]) -> String? {
        guard results.count == 1, case .inserted(let eventID, _) = results[0] else {
            return nil
        }
        return eventID
    }
}
