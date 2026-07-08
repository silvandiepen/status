import Foundation
import Testing
@testable import StatusCore

@Test func pluginRequestJobRunnerFetchesJSONExecutesMappingsAndCommits() async throws {
    let database = try temporaryRequestRunnerDatabase()
    try insertRequestRunnerPluginFixture(database, pluginID: "com.status.github", accountID: "acct_gh")
    let store = StatusPersistenceStore(database: database)
    let responseURL = try #require(URL(string: "https://api.github.com/repos/statusfoundry/status/actions/runs?per_page=25"))
    let transport = FakePluginRequestTransport(responses: [
        responseURL: PluginHTTPResponse(
            data: Data("""
            {
              "workflow_runs": [
                {
                  "name": "CI",
                  "conclusion": "failure",
                  "repository": { "id": "repo-1" },
                  "head_branch": "main",
                  "html_url": "https://github.com/statusfoundry/status/actions/runs/1",
                  "updated_at": "2026-07-07T20:15:30Z"
                }
              ]
            }
            """.utf8),
            statusCode: 200,
            url: responseURL
        )
    ])
    let runner = PluginRequestJobRunner(
        transport: transport,
        committer: PluginMappingOutputCommitter(store: store)
    )

    let result = try await runner.run(
        definition: githubDefinition(),
        input: PluginRequestJobInput(
            pluginID: "com.status.github",
            accountID: "acct_gh",
            provider: "com.status.github",
            requestID: "list_workflow_runs",
            variables: ["owner": "statusfoundry", "repo": "status"],
            headers: ["Authorization": "Bearer token"],
            jobID: "job_gh",
            capturedAt: Date(timeIntervalSince1970: 1_783_433_520)
        )
    )

    #expect(result.request.url == responseURL)
    #expect(result.request.headers["Authorization"] == "Bearer token")
    #expect(result.mappingOutput.events.map(\.type) == ["github.workflow.failed"])
    #expect(try store.event(id: result.mappingOutput.events[0].id)?.summary == "CI failed on main.")
    #expect(try store.statusItemCount() == 1)
}

@Test func pluginRequestJobRunnerNormalizesWebsiteProbeResponse() async throws {
    let database = try temporaryRequestRunnerDatabase()
    try insertRequestRunnerPluginFixture(database, pluginID: "com.status.website", accountID: "acct_web")
    let store = StatusPersistenceStore(database: database)
    let responseURL = try #require(URL(string: "https://status.hakobs.com"))
    let transport = FakePluginRequestTransport(responses: [
        responseURL: PluginHTTPResponse(data: Data("Service unavailable".utf8), statusCode: 503, url: responseURL)
    ])
    let runner = PluginRequestJobRunner(
        transport: transport,
        committer: PluginMappingOutputCommitter(store: store)
    )

    let result = try await runner.run(
        definition: websiteDefinition(),
        input: PluginRequestJobInput(
            pluginID: "com.status.website",
            accountID: "acct_web",
            provider: "com.status.website",
            requestID: "check_site",
            variables: ["host": "status.hakobs.com"],
            jobID: "job_web",
            capturedAt: Date(timeIntervalSince1970: 1_783_433_520)
        )
    )

    #expect(result.payload == .object([
        "host": .string("status.hakobs.com"),
        "previousHealthy": .null,
        "reachable": .bool(false),
        "statusCode": .number(503)
    ]))
    #expect(result.mappingOutput.resources.map(\.resource.id) == ["acct_web:status.hakobs.com"])
    #expect(result.mappingOutput.events.map(\.type) == ["website.down"])
    #expect(try store.resource(id: "acct_web:status.hakobs.com")?.name == "status.hakobs.com")
    #expect(try store.statusItemCount() == 1)
}

@Test func pluginRequestJobRunnerFollowsJSONAPINextLinkPagination() async throws {
    let database = try temporaryRequestRunnerDatabase()
    try insertRequestRunnerPluginFixture(database, pluginID: "com.status.appstoreconnect", accountID: "acct_asc", jobID: "job_asc")
    let store = StatusPersistenceStore(database: database)
    let firstURL = try #require(URL(string: "https://api.appstoreconnect.apple.com/v1/apps"))
    let secondURL = try #require(URL(string: "https://api.appstoreconnect.apple.com/v1/apps?cursor=next"))
    let transport = FakePluginRequestTransport(responses: [
        firstURL: PluginHTTPResponse(
            data: Data("""
            {
              "data": [
                { "id": "app-1", "attributes": { "name": "Status One", "bundleId": "com.example.one" } }
              ],
              "links": { "next": "https://api.appstoreconnect.apple.com/v1/apps?cursor=next" }
            }
            """.utf8),
            statusCode: 200,
            url: firstURL
        ),
        secondURL: PluginHTTPResponse(
            data: Data("""
            {
              "data": [
                { "id": "app-2", "attributes": { "name": "Status Two", "bundleId": "com.example.two" } }
              ],
              "links": { "next": null }
            }
            """.utf8),
            statusCode: 200,
            url: secondURL
        )
    ])
    let runner = PluginRequestJobRunner(
        transport: transport,
        committer: PluginMappingOutputCommitter(store: store)
    )

    let result = try await runner.run(
        definition: appStoreConnectDefinition(),
        input: PluginRequestJobInput(
            pluginID: "com.status.appstoreconnect",
            accountID: "acct_asc",
            provider: "com.status.appstoreconnect",
            requestID: "list_apps",
            headers: ["Authorization": "Bearer token"],
            jobID: "job_asc",
            capturedAt: Date(timeIntervalSince1970: 1_783_433_520)
        )
    )

    #expect(result.mappingOutput.resources.map(\.resource.id) == ["acct_asc:app-1", "acct_asc:app-2"])
    #expect(try store.resource(id: "acct_asc:app-1")?.name == "Status One")
    #expect(try store.resource(id: "acct_asc:app-2")?.name == "Status Two")
}

private struct FakePluginRequestTransport: PluginRequestHTTPTransport {
    var responses: [URL: PluginHTTPResponse]

    func response(for request: PluginHTTPRequest) async throws -> PluginHTTPResponse {
        try #require(responses[request.url])
    }
}

private func githubDefinition() -> PluginPackageDefinition {
    PluginPackageDefinition(
        requests: PackagedPluginRequests(requests: [
            "list_workflow_runs": PackagedPluginRequest(
                url: "https://api.github.com/repos/{{owner}}/{{repo}}/actions/runs",
                auth: "default",
                query: ["per_page": "25"],
                timeoutSeconds: 30
            )
        ]),
        mappings: PackagedPluginMappings(events: [
            PackagedEventMapping(
                type: "github.workflow.failed",
                request: "list_workflow_runs",
                source: "$.workflow_runs[*]",
                when: .shorthand("$.conclusion == 'failure'"),
                resourceID: "$.repository.id",
                title: "Workflow failed",
                summary: "{{name}} failed on {{head_branch}}.",
                severity: .fixed(.warning),
                actionURL: "{{html_url}}",
                timestamp: "$.updated_at"
            )
        ])
    )
}

private func appStoreConnectDefinition() -> PluginPackageDefinition {
    PluginPackageDefinition(
        requests: PackagedPluginRequests(requests: [
            "list_apps": PackagedPluginRequest(
                url: "https://api.appstoreconnect.apple.com/v1/apps",
                auth: "default",
                pagination: PackagedPluginRequestPagination(
                    type: "jsonapi-next-link",
                    path: "$.links.next",
                    maxPages: 5
                ),
                timeoutSeconds: 30
            )
        ]),
        mappings: PackagedPluginMappings(resources: [
            PackagedResourceMapping(
                type: "app",
                request: "list_apps",
                source: "$.data[*]",
                id: "$.id",
                name: "$.attributes.name",
                fields: ["bundleId": "$.attributes.bundleId"]
            )
        ])
    )
}

private func websiteDefinition() -> PluginPackageDefinition {
    PluginPackageDefinition(
        requests: PackagedPluginRequests(requests: [
            "check_site": PackagedPluginRequest(url: "https://{{host}}", timeoutSeconds: 15)
        ]),
        mappings: PackagedPluginMappings(
            resources: [
                PackagedResourceMapping(
                    type: "website",
                    request: "check_site",
                    id: "{{host}}",
                    name: "{{host}}",
                    actionURL: "https://{{host}}"
                )
            ],
            events: [
                PackagedEventMapping(
                    type: "website.down",
                    request: "check_site",
                    when: .shorthand("$.statusCode >= 500 || $.reachable == false"),
                    resourceID: "{{host}}",
                    title: "Website down",
                    summary: "{{host}} is not responding normally.",
                    severity: .fixed(.critical),
                    actionURL: "https://{{host}}"
                )
            ]
        )
    )
}

private func temporaryRequestRunnerDatabase() throws -> SQLiteDatabase {
    let path = FileManager.default.temporaryDirectory
        .appendingPathComponent("status-\(UUID().uuidString).sqlite")
        .path
    let database = try SQLiteDatabase(path: path)
    try StatusDatabaseMigrator.migrate(database)
    return database
}

private func insertRequestRunnerPluginFixture(
    _ database: SQLiteDatabase,
    pluginID: String,
    accountID: String,
    jobID: String? = nil
) throws {
    let now = "2026-07-07T12:00:00Z"
    try database.execute(
        """
        INSERT INTO plugins
        (id, name, author, description, category, trust_level, installed_version, install_path, installed_at, updated_at)
        VALUES (?, ?, 'Status Foundry', 'Fixture plugin', 'developer', 'official', '0.1.0', '/tmp/plugin', ?, ?)
        """,
        bindings: [.text(pluginID), .text(pluginID), .text(now), .text(now)]
    )
    try database.execute(
        """
        INSERT INTO accounts
        (id, plugin_id, provider, display_name, auth_type, created_at, updated_at)
        VALUES (?, ?, ?, 'Fixture account', 'none', ?, ?)
        """,
        bindings: [.text(accountID), .text(pluginID), .text(pluginID), .text(now), .text(now)]
    )
    try database.execute(
        """
        INSERT INTO jobs
        (id, plugin_id, trigger_id, account_id, status, started_at)
        VALUES (?, ?, 'trg_fixture', ?, 'running', ?)
        """,
        bindings: [.text(jobID ?? (pluginID == "com.status.website" ? "job_web" : "job_gh")), .text(pluginID), .text(accountID), .text(now)]
    )
}
