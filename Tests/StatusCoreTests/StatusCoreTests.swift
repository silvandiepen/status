import Foundation
import Testing
@testable import StatusCore

@Test func severitySortsByAttentionPriority() {
    #expect(Severity.ok < .notice)
    #expect(Severity.notice < .warning)
    #expect(Severity.warning < .critical)
}

@Test func mockDashboardAnswersAttentionQuestions() {
    let snapshot = MockDashboard.snapshot

    #expect(snapshot.statusItems.contains { $0.severity == .critical })
    #expect(snapshot.recentEvents.contains { $0.type == "github.workflow.failed" })
    #expect(snapshot.integrations.count >= 2)
    #expect(snapshot.auditEntries.isEmpty == false)
}
