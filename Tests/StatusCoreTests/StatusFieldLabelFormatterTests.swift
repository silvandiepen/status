import Testing
@testable import StatusCore

@Test func statusFieldLabelFormatterUsesProductLabelsForCommonPluginFields() {
    #expect(StatusFieldLabelFormatter.label(for: "statusCode") == "Status")
    #expect(StatusFieldLabelFormatter.label(for: "responseTimeMs") == "Response Time")
    #expect(StatusFieldLabelFormatter.label(for: "actionUrl") == "Open")
    #expect(StatusFieldLabelFormatter.label(for: "repository_id") == "Repository ID")
    #expect(StatusFieldLabelFormatter.label(for: "lastCommit") == "Last Commit")
}
