import Foundation
import Testing
@testable import StatusCore

@Test func ruleMatchesEventTypeProviderAndConditions() throws {
    let event = workflowFailedEvent()
    let rule = Rule(
        id: "rul_workflow_failed",
        name: "Critical GitHub workflow",
        enabled: true,
        provider: "github",
        eventType: "github.workflow.failed",
        conditions: [
            RuleCondition(field: "severity", operation: .matchesSeverity, value: .string("warning")),
            RuleCondition(field: "resourceName", operation: .contains, value: .string("status"))
        ],
        actions: [
            RuleActionDefinition(action: "notification.show")
        ]
    )

    let matches = RuleEngine.matchingRules(for: event, rules: [rule])

    #expect(matches.count == 1)
    #expect(matches.first?.actions.first?.action == "notification.show")
}

@Test func disabledRulesDoNotMatch() throws {
    let event = workflowFailedEvent()
    let rule = Rule(
        id: "rul_disabled",
        name: "Disabled",
        enabled: false,
        provider: "github",
        eventType: "github.workflow.failed",
        conditions: [],
        actions: [RuleActionDefinition(action: "notification.show")]
    )

    #expect(RuleEngine.matchingRules(for: event, rules: [rule]).isEmpty)
}

@Test func fingerprintIsStableAndStateSensitive() {
    let first = EventFingerprint.make(
        EventFingerprintInput(
            provider: "github",
            eventType: "github.workflow.failed",
            resourceID: "res_status_repo",
            relevantState: "failure"
        )
    )
    let second = EventFingerprint.make(
        EventFingerprintInput(
            provider: "github",
            eventType: "github.workflow.failed",
            resourceID: "res_status_repo",
            relevantState: "failure"
        )
    )
    let different = EventFingerprint.make(
        EventFingerprintInput(
            provider: "github",
            eventType: "github.workflow.failed",
            resourceID: "res_status_repo",
            relevantState: "success"
        )
    )

    #expect(first == second)
    #expect(first != different)
    #expect(first.count == 64)
}

private func workflowFailedEvent() -> Event {
    Event(
        id: "evt_01workflowfailed",
        provider: "github",
        type: "github.workflow.failed",
        resourceID: "res_status_repo",
        resourceName: "status",
        severity: .critical,
        title: "Workflow failed",
        summary: "CI failed on main.",
        timestamp: Date(timeIntervalSince1970: 1_783_433_520),
        actionURL: URL(string: "https://github.com/statusfoundry/status/actions"),
        fingerprint: "github:workflow.failed:res_status_repo:failure"
    )
}
