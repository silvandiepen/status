import Foundation
import Testing
@testable import StatusCore

@Test func bundledPluginInstallerInstallsOfficialPluginsFromBundleResources() throws {
    let database = try temporaryBundledPluginDatabase()
    let store = StatusPersistenceStore(database: database)
    let installRoot = FileManager.default.temporaryDirectory
        .appendingPathComponent("status-bundled-\(UUID().uuidString)", isDirectory: true)
    let installer = BundledPluginInstaller(store: store, installRoot: installRoot)

    let packages = try installer.availablePlugins()
    let results = try installer.installAll(installedAt: Date(timeIntervalSince1970: 1_783_433_520))

    #expect(packages.map(\.id).sorted() == [
        "com.status.appstoreconnect",
        "com.status.github",
        "com.status.gitlab",
        "com.status.jira",
        "com.status.website",
        "com.status.youtube"
    ])
    #expect(results.map(\.plugin.id).sorted() == packages.map(\.id).sorted())
    #expect(try store.installedPlugins().map(\.id).sorted() == packages.map(\.id).sorted())
    #expect(try store.installedPlugin(id: "com.status.website")?.setup?.fields.first?.id == "host")
    #expect(try store.installedPlugin(id: "com.status.gitlab")?.setup?.fields.first?.id == "projectId")
    #expect(try store.triggers().contains { $0.pluginID == "com.status.website" && $0.kind == .manual && $0.requestID == "check_site" })
    #expect(try store.triggers().contains { $0.pluginID == "com.status.gitlab" && $0.kind == .cron && $0.requestID == "list_pipelines" })
    #expect(try store.triggers().contains { $0.pluginID == "com.status.youtube" && $0.kind == .cron && $0.requestID == "list_my_channels" })
    #expect(try store.rules().contains { $0.provider == "com.status.website" && $0.eventType == "website.down" })
    #expect(try store.rules().contains { $0.provider == "com.status.gitlab" && $0.eventType == "gitlab.pipeline.failed" })
    #expect(try store.rules().contains { $0.provider == "com.status.youtube" && $0.eventType == "youtube.channel.visibility_limited" })
    #expect(try store.installedPluginDefinition(pluginID: "com.status.jira")?.actions.map(\.id) == ["jira.createIssue"])
    let websiteVersion = try #require(try store.installedPluginVersions(pluginID: "com.status.website").first)
    #expect(FileManager.default.fileExists(atPath: try #require(websiteVersion.packagePath)))
}

@Test func bundledPluginInstallerIsIdempotentAndPreservesStoredRules() throws {
    let database = try temporaryBundledPluginDatabase()
    let store = StatusPersistenceStore(database: database)
    let installRoot = FileManager.default.temporaryDirectory
        .appendingPathComponent("status-bundled-\(UUID().uuidString)", isDirectory: true)
    let installer = BundledPluginInstaller(store: store, installRoot: installRoot)

    _ = try installer.install(pluginID: "com.status.website", installedAt: Date(timeIntervalSince1970: 1_783_433_520))
    var rule = try #require(try store.rules().first(where: { $0.provider == "com.status.website" }))
    rule.enabled = true
    try store.upsertRule(rule, updatedAt: Date(timeIntervalSince1970: 1_783_433_620))

    _ = try installer.install(pluginID: "com.status.website", installedAt: Date(timeIntervalSince1970: 1_783_433_720))

    #expect(try store.rules().first(where: { $0.id == rule.id })?.enabled == true)
    #expect(try store.installedPluginVersions(pluginID: "com.status.website").count == 1)
}

@Test func bundledYouTubePluginMapsChannelsUploadsAndMetrics() throws {
    let database = try temporaryBundledPluginDatabase()
    let store = StatusPersistenceStore(database: database)
    let installRoot = FileManager.default.temporaryDirectory
        .appendingPathComponent("status-bundled-\(UUID().uuidString)", isDirectory: true)
    let installer = BundledPluginInstaller(store: store, installRoot: installRoot)
    _ = try installer.install(pluginID: "com.status.youtube", installedAt: Date(timeIntervalSince1970: 1_783_433_520))
    let definition = try #require(try store.installedPluginDefinition(pluginID: "com.status.youtube"))
    let capturedAt = Date(timeIntervalSince1970: 1_783_433_520)

    let channelOutput = try PluginMappingExecutor.execute(
        definition.mappings,
        input: PluginMappingExecutionInput(
            pluginID: "com.status.youtube",
            accountID: "acct_yt",
            provider: "com.status.youtube",
            requestID: "list_my_channels",
            payload: decodeBundledMappingJSON("""
            {
              "items": [
                {
                  "id": "UC_status",
                  "snippet": {
                    "title": "Status Foundry",
                    "description": "Product updates",
                    "country": "MT"
                  },
                  "statistics": {
                    "subscriberCount": "1200",
                    "viewCount": "45000",
                    "videoCount": "38"
                  },
                  "status": {
                    "privacyStatus": "private"
                  },
                  "contentDetails": {
                    "relatedPlaylists": {
                      "uploads": "UU_status"
                    }
                  }
                }
              ]
            }
            """),
            capturedAt: capturedAt
        )
    )
    let uploadOutput = try PluginMappingExecutor.execute(
        definition.mappings,
        input: PluginMappingExecutionInput(
            pluginID: "com.status.youtube",
            accountID: "acct_yt",
            provider: "com.status.youtube",
            requestID: "list_recent_uploads",
            payload: decodeBundledMappingJSON("""
            {
              "items": [
                {
                  "id": {
                    "videoId": "vid_123"
                  },
                  "snippet": {
                    "title": "Status update",
                    "channelId": "UC_status",
                    "channelTitle": "Status Foundry",
                    "publishedAt": "2026-07-09T10:00:00Z",
                    "description": "Release notes"
                  }
                }
              ]
            }
            """),
            capturedAt: capturedAt
        )
    )

    #expect(channelOutput.resources.map { $0.resource.id } == ["acct_yt:UC_status"])
    #expect(channelOutput.resources[0].resource.name == "Status Foundry")
    #expect(channelOutput.resources[0].state["subscriberCount"] == "1200")
    #expect(channelOutput.metrics.map { $0.metric.id }.sorted() == [
        "acct_yt:uc_status:metric:subscriber_count",
        "acct_yt:uc_status:metric:video_count",
        "acct_yt:uc_status:metric:view_count"
    ])
    #expect(channelOutput.events.map { $0.type } == ["youtube.channel.visibility_limited"])
    #expect(channelOutput.events[0].summary == "Status Foundry is currently private.")
    #expect(uploadOutput.resources.map { $0.resource.id } == ["acct_yt:vid_123"])
    #expect(uploadOutput.resources[0].resource.actionURL?.absoluteString == "https://www.youtube.com/watch?v=vid_123")
    #expect(uploadOutput.events.map { $0.type } == ["youtube.video.published"])
    #expect(uploadOutput.events[0].summary == "Status update was published on Status Foundry.")
    #expect(uploadOutput.events[0].timestamp == ISO8601DateFormatter().date(from: "2026-07-09T10:00:00Z"))
}

private func decodeBundledMappingJSON(_ string: String) throws -> MappingJSONValue {
    try JSONDecoder().decode(MappingJSONValue.self, from: Data(string.utf8))
}

private func temporaryBundledPluginDatabase() throws -> SQLiteDatabase {
    let path = FileManager.default.temporaryDirectory
        .appendingPathComponent("status-\(UUID().uuidString).sqlite")
        .path
    let database = try SQLiteDatabase(path: path)
    try StatusDatabaseMigrator.migrate(database)
    return database
}
