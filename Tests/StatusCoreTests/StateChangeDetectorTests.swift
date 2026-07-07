import Foundation
import Testing
@testable import StatusCore

@Test func stateChangeDetectorRecordsFirstObservation() throws {
    let store = try temporaryStore()
    let detector = StateChangeDetector(store: store)
    let now = Date(timeIntervalSince1970: 1_783_433_520)

    let result = try detector.record(
        resourceID: "res_app",
        state: ["appStoreState": "REJECTED"],
        jobID: "job_first",
        capturedAt: now
    )

    guard case .firstObservation(let snapshot) = result else {
        Issue.record("Expected first observation")
        return
    }

    #expect(snapshot.resourceID == "res_app")
    #expect(snapshot.state["appStoreState"] == "REJECTED")
    #expect(try store.resourceStateSnapshot(resourceID: "res_app") == snapshot)
}

@Test func stateChangeDetectorTreatsSameStateAsUnchangedAndRefreshesSnapshot() throws {
    let store = try temporaryStore()
    let detector = StateChangeDetector(store: store)
    let firstDate = Date(timeIntervalSince1970: 1_783_433_520)
    let secondDate = Date(timeIntervalSince1970: 1_783_437_120)
    let state = ["appStoreState": "IN_REVIEW"]

    _ = try detector.record(resourceID: "res_app", state: state, jobID: "job_first", capturedAt: firstDate)
    let result = try detector.record(resourceID: "res_app", state: state, jobID: "job_second", capturedAt: secondDate)

    guard case .unchanged(let snapshot) = result else {
        Issue.record("Expected unchanged observation")
        return
    }

    #expect(snapshot.jobID == "job_second")
    #expect(snapshot.capturedAt == secondDate)
    #expect(try store.resourceStateSnapshot(resourceID: "res_app") == snapshot)
}

@Test func stateChangeDetectorReportsTransitionWhenStateHashChanges() throws {
    let store = try temporaryStore()
    let detector = StateChangeDetector(store: store)
    let firstDate = Date(timeIntervalSince1970: 1_783_433_520)
    let secondDate = Date(timeIntervalSince1970: 1_783_437_120)

    _ = try detector.record(
        resourceID: "res_app",
        state: ["appStoreState": "IN_REVIEW"],
        jobID: "job_first",
        capturedAt: firstDate
    )
    let result = try detector.record(
        resourceID: "res_app",
        state: ["appStoreState": "REJECTED"],
        jobID: "job_second",
        capturedAt: secondDate
    )

    guard case .changed(let previous, let current) = result else {
        Issue.record("Expected changed observation")
        return
    }

    #expect(previous.state["appStoreState"] == "IN_REVIEW")
    #expect(current.state["appStoreState"] == "REJECTED")
    #expect(try store.resourceStateSnapshot(resourceID: "res_app") == current)
}

@Test func stateHashIsStableForDictionaryKeyOrder() throws {
    let store = try temporaryStore()
    let detector = StateChangeDetector(store: store)

    let first = try detector.hash([
        "appStoreState": "REJECTED",
        "latestBuildState": "VALID"
    ])
    let second = try detector.hash([
        "latestBuildState": "VALID",
        "appStoreState": "REJECTED"
    ])

    #expect(first == second)
}

private func temporaryStore() throws -> StatusPersistenceStore {
    let path = FileManager.default.temporaryDirectory
        .appendingPathComponent("status-\(UUID().uuidString).sqlite")
        .path
    let database = try SQLiteDatabase(path: path)
    try StatusDatabaseMigrator.migrate(database)
    try insertResourceFixture(database, resourceID: "res_app")
    return StatusPersistenceStore(database: database)
}

private func insertResourceFixture(_ database: SQLiteDatabase, resourceID: String) throws {
    let now = "2026-07-07T12:00:00Z"
    try database.execute(
        """
        INSERT INTO plugins
        (id, name, author, description, category, trust_level, installed_version, install_path, installed_at, updated_at)
        VALUES (?, 'App Store Connect', 'Status Foundry', 'Fixture plugin', 'developer', 'official', '0.1.0', '/tmp/plugin', ?, ?)
        """,
        bindings: [.text("com.status.appstoreconnect"), .text(now), .text(now)]
    )
    try database.execute(
        """
        INSERT INTO accounts
        (id, plugin_id, provider, display_name, auth_type, created_at, updated_at)
        VALUES (?, 'com.status.appstoreconnect', 'appstoreconnect', 'Example Account', 'none', ?, ?)
        """,
        bindings: [.text("acc_fixture"), .text(now), .text(now)]
    )
    try database.execute(
        """
        INSERT INTO resources
        (id, account_id, plugin_id, type, external_id, name, first_seen_at, last_seen_at)
        VALUES (?, 'acc_fixture', 'com.status.appstoreconnect', 'app', '123', 'Example App', ?, ?)
        """,
        bindings: [.text(resourceID), .text(now), .text(now)]
    )
    for jobID in ["job_first", "job_second"] {
        try database.execute(
            """
            INSERT INTO jobs
            (id, plugin_id, trigger_id, account_id, status, started_at)
            VALUES (?, 'com.status.appstoreconnect', 'trg_fixture', 'acc_fixture', 'succeeded', ?)
            """,
            bindings: [.text(jobID), .text(now)]
        )
    }
}
