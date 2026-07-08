import Foundation

public struct PluginMappingCommitResult: Equatable, Sendable {
    public var resourceIDs: [String]
    public var eventResults: [EventIngestionResult]
    public var metricIDs: [String]
    public var auditEntry: AuditEntry

    public init(
        resourceIDs: [String],
        eventResults: [EventIngestionResult],
        metricIDs: [String] = [],
        auditEntry: AuditEntry
    ) {
        self.resourceIDs = resourceIDs
        self.eventResults = eventResults
        self.metricIDs = metricIDs
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
        capturedAt: Date,
        eventDeclarations: [EventTypeDeclaration] = []
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

        var eventResults: [EventIngestionResult] = []
        for event in output.events {
            eventResults.append(try ingestor.ingest(event))
            try resolveItemsClosedBy(event, declarations: eventDeclarations)
        }
        var metricIDs: [String] = []
        for mappedMetric in output.metrics {
            let previousPoints = try store.metricPoints(metricID: mappedMetric.metric.id)
            try store.upsertMetric(mappedMetric.metric, updatedAt: capturedAt)
            try store.insertMetricPoint(
                metricID: mappedMetric.metric.id,
                value: mappedMetric.pointValue,
                timestamp: mappedMetric.pointTimestamp,
                metadata: jobID.map { ["jobID": $0] } ?? [:]
            )
            if let event = try metricDropEvent(for: mappedMetric, previousPoints: previousPoints) {
                eventResults.append(try ingestor.ingest(event))
            }
            metricIDs.append(mappedMetric.metric.id)
        }
        let auditEntry = AuditEntry(
            id: auditID(jobID: jobID, capturedAt: capturedAt),
            title: "Plugin mapping output committed",
            detail: "\(resourceIDs.count) resources stored, \(eventResults.count) events processed, \(metricIDs.count) metrics updated.",
            timestamp: capturedAt,
            status: "success",
            jobID: jobID,
            eventID: singleInsertedEventID(from: eventResults)
        )
        try store.insertAuditEntry(auditEntry)

        return PluginMappingCommitResult(
            resourceIDs: resourceIDs,
            eventResults: eventResults,
            metricIDs: metricIDs,
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

    private func resolveItemsClosedBy(_ event: Event, declarations: [EventTypeDeclaration]) throws {
        let openedEventTypes = declarations
            .filter { $0.closedBy == event.type }
            .map(\.type)
        for openedEventType in openedEventTypes {
            _ = try store.resolveOpenEventBackedStatusItems(
                resourceID: event.resourceID,
                eventType: openedEventType,
                at: event.timestamp
            )
        }
    }

    private func metricDropEvent(
        for mappedMetric: MappedPluginMetric,
        previousPoints: [(timestamp: Date, value: Double)]
    ) throws -> Event? {
        let threshold = 0.20
        guard let previous = previousPoints.last,
              previous.value > 0,
              mappedMetric.pointValue < previous.value else {
            return nil
        }
        let dropRatio = (previous.value - mappedMetric.pointValue) / previous.value
        guard dropRatio >= threshold else {
            return nil
        }
        guard let resource = try store.resource(id: mappedMetric.metric.resourceID) else {
            return nil
        }

        let percent = Int((dropRatio * 100).rounded())
        let eventType = "metric.\(mappedMetric.metric.label).dropped"
        let relevantState = "\(mappedMetric.metric.id):lt:previous_0.8"
        let fingerprint = EventFingerprint.make(
            EventFingerprintInput(
                provider: resource.pluginID,
                eventType: eventType,
                resourceID: resource.id,
                relevantState: relevantState,
                dateBucket: dayBucket(mappedMetric.pointTimestamp)
            )
        )
        return Event(
            id: "evt_\(fingerprint.prefix(26))",
            provider: resource.pluginID,
            type: eventType,
            resourceID: resource.id,
            resourceName: resource.name,
            severity: .warning,
            title: "\(mappedMetric.metric.label) dropped",
            summary: "\(resource.name) \(mappedMetric.metric.label) dropped \(percent)% vs the previous point.",
            timestamp: mappedMetric.pointTimestamp,
            actionURL: resource.actionURL,
            fingerprint: fingerprint
        )
    }

    private func dayBucket(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
