import Foundation
import Testing
@testable import StatusCore

@Test func mappingSelectorReadsDotBracketAndIndexPaths() throws {
    let root = try decodeJSON("""
    {
      "data": [
        {
          "id": "app-1",
          "attributes": {
            "name": "Status",
            "odd.key": "value"
          }
        }
      ]
    }
    """)

    #expect(try MappingSelector("$.data[0].id").resolve(in: root) == .string("app-1"))
    #expect(try MappingSelector("$.data[0]['attributes'].name").resolve(in: root) == .string("Status"))
    #expect(try MappingSelector("$.data[0].attributes['odd.key']").resolve(in: root) == .string("value"))
}

@Test func mappingSelectorIteratesWildcardTailOnly() throws {
    let root = try decodeJSON("""
    {
      "data": [
        { "id": "one" },
        { "id": "two" }
      ]
    }
    """)

    let items = try MappingSelector("$.data[*]").resolveItems(in: root)

    #expect(items == [
        .object(["id": .string("one")]),
        .object(["id": .string("two")])
    ])
    #expect(throws: MappingSelectorError.wildcardMustBeTail("$.data[*].id")) {
        try MappingSelector("$.data[*].id")
    }
}

@Test func mappingSelectorMissingValuesAreNilNotErrors() throws {
    let root = try decodeJSON("{ \"items\": [] }")

    #expect(try MappingSelector("$.items[0].name").resolve(in: root) == nil)
    #expect(try MappingSelector("$.missing").resolve(in: root) == nil)
}

@Test func mappingSelectorRejectsUnsupportedSyntax() {
    #expect(throws: MappingSelectorError.unsupportedSyntax("$..data")) {
        try MappingSelector("$..data")
    }
    #expect(throws: MappingSelectorError.invalidArrayIndex("[-1]")) {
        try MappingSelector("$.data[-1]")
    }
    #expect(throws: MappingSelectorError.selectorMustStartAtRoot("data.id")) {
        try MappingSelector("data.id")
    }
}

@Test func mappingTemplateRendersScopesAndMissingValues() {
    let context = MappingTemplateContext(scopes: [
        "item": .object([
            "id": .string("42"),
            "ready": .bool(true),
            "count": .number(3)
        ]),
        "resource": .object([
            "name": .string("Status")
        ]),
        "event": .object([
            "severity": .string("warning")
        ])
    ])

    let rendered = MappingTemplateRenderer.render(
        "{{resource.name}} {{id}} {{ready}} {{count}} {{event.severity}} {{missing}}",
        context: context
    )

    #expect(rendered == "Status 42 true 3 warning ")
}

@Test func mappingTemplateEscapesLiteralOpeningBraces() {
    let context = MappingTemplateContext(scopes: [
        "item": .object(["name": .string("Status")])
    ])

    #expect(MappingTemplateRenderer.render("\\{{name}} {{name}}", context: context) == "{{name}} Status")
}

private func decodeJSON(_ string: String) throws -> MappingJSONValue {
    try JSONDecoder().decode(MappingJSONValue.self, from: Data(string.utf8))
}
