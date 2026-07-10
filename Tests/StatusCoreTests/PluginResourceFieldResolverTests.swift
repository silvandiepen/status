import Foundation
import Testing
@testable import StatusCore
@testable import StatusUI

@Test func pluginResourceFieldResolverShowsCanonicalResourceFields() throws {
    let view = PackagedPluginView(
        id: "repositories",
        type: .resourceList,
        fields: ["name", "type", "resourceType", "actionUrl", "missing"]
    )
    let resource = Resource(
        id: "repo_status",
        accountID: "acc_work",
        pluginID: "com.status.github",
        type: "repository",
        name: "statusfoundry/status",
        fields: [:],
        actionURL: URL(string: "https://github.com/statusfoundry/status")!
    )

    let fields = PluginResourceFieldResolver.resolvedFields(for: view, resource: resource)

    #expect(fields.map(\.key) == ["name", "type", "resourceType", "actionUrl"])
    #expect(fields.map(\.value) == [
        "statusfoundry/status",
        "repository",
        "repository",
        "https://github.com/statusfoundry/status"
    ])
}

@Test func pluginResourceFieldResolverPrefersExplicitResourceFields() throws {
    let view = PackagedPluginView(
        id: "repositories",
        type: .resourceList,
        fields: ["name", "actionUrl"]
    )
    let resource = Resource(
        id: "repo_status",
        accountID: "acc_work",
        pluginID: "com.status.github",
        type: "repository",
        name: "Canonical name",
        fields: [
            "name": "Mapped display name",
            "actionUrl": "https://example.com/mapped"
        ],
        actionURL: URL(string: "https://github.com/statusfoundry/status")!
    )

    let fields = PluginResourceFieldResolver.resolvedFields(for: view, resource: resource)

    #expect(fields.map(\.value) == ["Mapped display name", "https://example.com/mapped"])
}
