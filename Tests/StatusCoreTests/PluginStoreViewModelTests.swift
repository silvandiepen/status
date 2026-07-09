import Foundation
import Testing
import StatusCore
@testable import StatusUI

@MainActor
@Test func pluginStoreViewModelLoadsRuntimeStatusesForInstalledPlugins() async throws {
    let plugin = InstalledPlugin(
        id: "com.status.github",
        name: "GitHub",
        author: "Status Foundry",
        description: "GitHub repository checks.",
        category: "development",
        trustLevel: .official,
        installedVersion: "0.1.0",
        installPath: "/tmp/com.status.github",
        installedAt: Date(timeIntervalSince1970: 1_783_433_520),
        updatedAt: Date(timeIntervalSince1970: 1_783_433_520)
    )
    let runtimeStatus = PluginRuntimeStatus(
        pluginID: plugin.id,
        status: .failed,
        detail: "Missing network permission.",
        timestamp: Date(timeIntervalSince1970: 1_783_433_530)
    )
    var loadedStatusPluginIDs: [[String]] = []
    let viewModel = PluginStoreViewModel(
        loadInstalled: { [plugin] },
        loadAvailable: { [] },
        loadRuntimeStatuses: { plugins in
            loadedStatusPluginIDs.append(plugins.map(\.id))
            return [plugin.id: runtimeStatus]
        },
        installPlugin: { _ in }
    )

    await viewModel.reload()

    #expect(loadedStatusPluginIDs == [[plugin.id]])
    #expect(viewModel.runtimeStatuses == [plugin.id: runtimeStatus])
}

@MainActor
@Test func pluginStoreViewModelLoadsResourcesForInstalledPlugins() async throws {
    let plugin = InstalledPlugin(
        id: "com.status.website",
        name: "Website",
        author: "Status Foundry",
        description: "Website checks.",
        category: "operations",
        trustLevel: .official,
        installedVersion: "0.1.0",
        installPath: "/tmp/com.status.website",
        views: [
            PackagedPluginView(
                id: "websites",
                type: .resourceList,
                resourceType: "website",
                fields: ["statusCode"]
            )
        ],
        installedAt: Date(timeIntervalSince1970: 1_783_433_520),
        updatedAt: Date(timeIntervalSince1970: 1_783_433_520)
    )
    let resource = Resource(
        id: "res_com_status_website_example",
        accountID: "acc_website",
        pluginID: plugin.id,
        type: "website",
        name: "example.com",
        fields: ["statusCode": "200"]
    )
    var loadedResourcePluginIDs: [String] = []
    let viewModel = PluginStoreViewModel(
        loadInstalled: { [plugin] },
        loadAvailable: { [] },
        loadRuntimeStatuses: { _ in [:] },
        loadPluginResources: { plugin in
            loadedResourcePluginIDs.append(plugin.id)
            return [resource]
        },
        installPlugin: { _ in }
    )

    await viewModel.reload()

    #expect(loadedResourcePluginIDs == [plugin.id])
    #expect(viewModel.pluginResources == [plugin.id: [resource]])
}

@MainActor
@Test func pluginStoreViewModelLoadsSuggestedAndAppScopedRules() async throws {
    let plugin = InstalledPlugin(
        id: "com.status.github",
        name: "GitHub",
        author: "Status Foundry",
        description: "GitHub repository checks.",
        category: "development",
        trustLevel: .official,
        installedVersion: "0.1.0",
        installPath: "/tmp/com.status.github",
        installedAt: Date(timeIntervalSince1970: 1_783_433_520),
        updatedAt: Date(timeIntervalSince1970: 1_783_433_520)
    )
    let preset = Rule(
        id: "rule_com_status_github_failed_workflow",
        name: "Failed workflow",
        enabled: false,
        provider: plugin.id,
        eventType: "github.workflow.failed",
        conditions: [],
        actions: [RuleActionDefinition(action: "notify")]
    )
    let appRule = Rule(
        id: "rule_app_com_status_github_acc_work_rule_com_status_github_failed_workflow",
        name: "Failed workflow",
        enabled: true,
        scope: .app,
        accountID: "acc_work",
        provider: plugin.id,
        eventType: "github.workflow.failed",
        conditions: [],
        actions: [RuleActionDefinition(action: "notify")]
    )
    let viewModel = PluginStoreViewModel(
        loadInstalled: { [plugin] },
        loadAvailable: { [] },
        loadRules: { _ in [preset, appRule] },
        installPlugin: { _ in }
    )

    await viewModel.reload()

    #expect(viewModel.rulePresets[plugin.id] == [preset])
    #expect(viewModel.appRules[plugin.id] == [appRule])
}

@MainActor
@Test func pluginStoreViewModelEnablesPresetForSelectedApp() async throws {
    let plugin = InstalledPlugin(
        id: "com.status.github",
        name: "GitHub",
        author: "Status Foundry",
        description: "GitHub repository checks.",
        category: "development",
        trustLevel: .official,
        installedVersion: "0.1.0",
        installPath: "/tmp/com.status.github",
        installedAt: Date(timeIntervalSince1970: 1_783_433_520),
        updatedAt: Date(timeIntervalSince1970: 1_783_433_520)
    )
    let account = PluginAccountConfiguration(
        id: "acc_work",
        pluginID: plugin.id,
        accountName: "Work",
        variables: [:]
    )
    let preset = Rule(
        id: "rule_com_status_github_failed_workflow",
        name: "Failed workflow",
        enabled: false,
        provider: plugin.id,
        eventType: "github.workflow.failed",
        conditions: [],
        actions: [RuleActionDefinition(action: "notify")]
    )
    var savedRules: [Rule] = []
    let viewModel = PluginStoreViewModel(
        loadInstalled: { [plugin] },
        loadAvailable: { [] },
        loadRules: { _ in [preset] + savedRules },
        saveRule: { rule in
            savedRules.append(rule)
        },
        installPlugin: { _ in },
        canConfigurePlugin: { _ in true },
        loadAccounts: { _ in [account] }
    )

    await viewModel.reload()
    await viewModel.setRulePreset(preset, enabled: true, for: plugin)

    let savedRule = try #require(savedRules.first)
    #expect(savedRule.id == "rule_app_com_status_github_acc_work_rule_com_status_github_failed_workflow")
    #expect(savedRule.enabled == true)
    #expect(savedRule.scope == .app)
    #expect(savedRule.accountID == account.id)
    #expect(savedRule.provider == plugin.id)
}

@MainActor
@Test func pluginStoreViewModelBuildsOAuthConnectionURL() async throws {
    let plugin = InstalledPlugin(
        id: "com.status.oauthgithub",
        name: "OAuth GitHub",
        author: "Status Foundry",
        description: "OAuth GitHub checks.",
        category: "development",
        trustLevel: .official,
        installedVersion: "0.1.0",
        installPath: "/tmp/com.status.oauthgithub",
        auth: PackagedPluginAuth(
            type: .oauth2,
            provider: "github",
            applicationId: "status-foundry.github",
            oauth2: PackagedPluginOAuth2(
                authorizationURL: try #require(URL(string: "https://github.com/login/oauth/authorize")),
                tokenURL: try #require(URL(string: "https://github.com/login/oauth/access_token")),
                redirectURI: "status://oauth/github",
                scopes: ["repo"]
            )
        ),
        installedAt: Date(timeIntervalSince1970: 1_783_433_520),
        updatedAt: Date(timeIntervalSince1970: 1_783_433_520)
    )
    let viewModel = PluginStoreViewModel(
        loadInstalled: { [plugin] },
        loadAvailable: { [] },
        installPlugin: { _ in },
        canConfigurePlugin: { _ in true }
    )

    await viewModel.reload()
    viewModel.beginOAuthConnection(plugin)

    let selectedAccountID = viewModel.selectedAccountIDs[plugin.id]
    let url = try #require(viewModel.oauthConnectionURLs["\(plugin.id):\(selectedAccountID ?? "__new__:")"])
    let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
    let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item in
        item.value.map { (item.name, $0) }
    })
    #expect(url.host == "github.com")
    #expect(query["response_type"] == "code")
    #expect(query["client_id"] == "status-foundry.github")
    #expect(query["redirect_uri"] == "status://oauth/github")
    #expect(query["scope"] == "repo")
    #expect(query["code_challenge_method"] == "S256")
    #expect(query["code_challenge"]?.isEmpty == false)
    #expect(viewModel.oauthConnectionErrors["\(plugin.id):\(selectedAccountID ?? "__new__:")"] == nil)
}
