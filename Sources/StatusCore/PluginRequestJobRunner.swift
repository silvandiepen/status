import Foundation

public struct PluginHTTPRequest: Equatable, Sendable {
    public var method: String
    public var url: URL
    public var headers: [String: String]
    public var body: Data?
    public var timeoutSeconds: TimeInterval?

    public init(
        method: String,
        url: URL,
        headers: [String: String] = [:],
        body: Data? = nil,
        timeoutSeconds: TimeInterval? = nil
    ) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
        self.timeoutSeconds = timeoutSeconds
    }
}

public struct PluginHTTPResponse: Equatable, Sendable {
    public var data: Data
    public var statusCode: Int
    public var url: URL

    public init(data: Data, statusCode: Int, url: URL) {
        self.data = data
        self.statusCode = statusCode
        self.url = url
    }
}

public protocol PluginRequestHTTPTransport: Sendable {
    func response(for request: PluginHTTPRequest) async throws -> PluginHTTPResponse
}

public struct URLSessionPluginRequestTransport: PluginRequestHTTPTransport {
    public init() {}

    public func response(for request: PluginHTTPRequest) async throws -> PluginHTTPResponse {
        var urlRequest = URLRequest(url: request.url, timeoutInterval: request.timeoutSeconds ?? 30)
        urlRequest.httpMethod = request.method
        for (field, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: field)
        }
        urlRequest.httpBody = request.body
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 200
        return PluginHTTPResponse(data: data, statusCode: statusCode, url: request.url)
    }
}

public struct PluginRequestJobInput: Equatable, Sendable {
    public var pluginID: String
    public var accountID: String
    public var provider: String
    public var requestID: String
    public var variables: [String: String]
    public var headers: [String: String]
    public var jobID: String?
    public var capturedAt: Date

    public init(
        pluginID: String,
        accountID: String,
        provider: String,
        requestID: String,
        variables: [String: String] = [:],
        headers: [String: String] = [:],
        jobID: String? = nil,
        capturedAt: Date
    ) {
        self.pluginID = pluginID
        self.accountID = accountID
        self.provider = provider
        self.requestID = requestID
        self.variables = variables
        self.headers = headers
        self.jobID = jobID
        self.capturedAt = capturedAt
    }
}

public struct PluginRequestJobResult: Equatable, Sendable {
    public var request: PluginHTTPRequest
    public var payload: MappingJSONValue
    public var mappingOutput: PluginMappingExecutionOutput
    public var commitResult: PluginMappingCommitResult

    public init(
        request: PluginHTTPRequest,
        payload: MappingJSONValue,
        mappingOutput: PluginMappingExecutionOutput,
        commitResult: PluginMappingCommitResult
    ) {
        self.request = request
        self.payload = payload
        self.mappingOutput = mappingOutput
        self.commitResult = commitResult
    }
}

public enum PluginRequestJobRunnerError: Error, Equatable, LocalizedError, Sendable {
    case missingRequest(String)
    case invalidURL(String)
    case invalidPaginationURL(String)
    case invalidBody

    public var errorDescription: String? {
        switch self {
        case .missingRequest(let requestID):
            "Plugin request is not declared: \(requestID)"
        case .invalidURL(let url):
            "Plugin request URL is invalid: \(url)"
        case .invalidPaginationURL(let url):
            "Plugin pagination URL is invalid: \(url)"
        case .invalidBody:
            "Plugin request body could not be rendered."
        }
    }
}

public final class PluginRequestJobRunner {
    private let transport: PluginRequestHTTPTransport
    private let committer: PluginMappingOutputCommitter
    private let decoder = JSONDecoder()

    public init(
        transport: PluginRequestHTTPTransport = URLSessionPluginRequestTransport(),
        committer: PluginMappingOutputCommitter
    ) {
        self.transport = transport
        self.committer = committer
    }

    public func run(
        definition: PluginPackageDefinition,
        input: PluginRequestJobInput
    ) async throws -> PluginRequestJobResult {
        guard let requestDefinition = definition.requests.requests[input.requestID] else {
            throw PluginRequestJobRunnerError.missingRequest(input.requestID)
        }

        let request = try makeRequest(requestDefinition, input: input)
        let payload = try await fetchPayload(request: request, definition: requestDefinition, variables: input.variables)
        let mappingOutput = try PluginMappingExecutor.execute(
            definition.mappings,
            input: PluginMappingExecutionInput(
                pluginID: input.pluginID,
                accountID: input.accountID,
                provider: input.provider,
                requestID: input.requestID,
                payload: payload,
                capturedAt: input.capturedAt,
                account: .object(input.variables.mapValues(MappingJSONValue.string))
            )
        )
        let commitResult = try committer.commit(mappingOutput, jobID: input.jobID, capturedAt: input.capturedAt)

        return PluginRequestJobResult(
            request: request,
            payload: payload,
            mappingOutput: mappingOutput,
            commitResult: commitResult
        )
    }

    private func fetchPayload(
        request: PluginHTTPRequest,
        definition: PackagedPluginRequest,
        variables: [String: String]
    ) async throws -> MappingJSONValue {
        let firstResponse = try await transport.response(for: request)
        var payload = decodePayload(response: firstResponse, variables: variables)
        guard let pagination = definition.pagination else {
            return payload
        }

        var nextURL = try paginationNextURL(from: payload, pagination: pagination, originalURL: request.url)
        let maxPages = max(1, pagination.maxPages ?? 1)
        var fetchedPages = 1
        while let url = nextURL, fetchedPages < maxPages {
            let pageRequest = PluginHTTPRequest(
                method: definition.method,
                url: url,
                headers: request.headers,
                timeoutSeconds: definition.timeoutSeconds
            )
            let pageResponse = try await transport.response(for: pageRequest)
            let pagePayload = decodePayload(response: pageResponse, variables: variables)
            payload = payload.mergingTopLevelArrays(from: pagePayload)
            fetchedPages += 1
            nextURL = try paginationNextURL(from: pagePayload, pagination: pagination, originalURL: request.url)
        }
        return payload
    }

    private func makeRequest(_ definition: PackagedPluginRequest, input: PluginRequestJobInput) throws -> PluginHTTPRequest {
        let variables = MappingJSONValue.object(input.variables.mapValues(MappingJSONValue.string))
        let context = MappingTemplateContext(scopes: ["item": variables, "account": variables])
        let renderedURL = MappingTemplateRenderer.render(definition.url, context: context)
        guard var components = URLComponents(string: renderedURL) else {
            throw PluginRequestJobRunnerError.invalidURL(renderedURL)
        }
        let existingQueryItems = components.queryItems ?? []
        let queryItems = definition.query
            .sorted { $0.key < $1.key }
            .map { URLQueryItem(name: $0.key, value: MappingTemplateRenderer.render($0.value, context: context)) }
        components.queryItems = (existingQueryItems + queryItems).isEmpty ? nil : existingQueryItems + queryItems
        guard let url = components.url else {
            throw PluginRequestJobRunnerError.invalidURL(renderedURL)
        }

        var headers = definition.headers
            .mapValues { MappingTemplateRenderer.render($0, context: context) }
        for (field, value) in input.headers {
            headers[field] = value
        }
        let body = try definition.body.map { try renderBody($0, context: context) }
        if definition.body?.isJSONContainer == true,
           headers.keys.contains(where: { $0.lowercased() == "content-type" }) == false {
            headers["Content-Type"] = "application/json"
        }

        return PluginHTTPRequest(
            method: definition.method,
            url: url,
            headers: headers,
            body: body,
            timeoutSeconds: definition.timeoutSeconds
        )
    }

    private func decodePayload(response: PluginHTTPResponse, variables: [String: String]) -> MappingJSONValue {
        if let payload = try? decoder.decode(MappingJSONValue.self, from: response.data) {
            return payload.mergingObjectFields([
                "statusCode": .number(Double(response.statusCode))
            ])
        }

        var fields = variables.mapValues(MappingJSONValue.string)
        fields["statusCode"] = .number(Double(response.statusCode))
        fields["reachable"] = .bool((200..<500).contains(response.statusCode))
        fields["previousHealthy"] = .null
        return .object(fields)
    }

    private func renderBody(_ body: PackagedPluginRequestBody, context: MappingTemplateContext) throws -> Data {
        switch body {
        case .string(let value):
            return Data(MappingTemplateRenderer.render(value, context: context).utf8)
        case .object, .array:
            guard JSONSerialization.isValidJSONObject(body.renderedJSONObject(context: context)) else {
                throw PluginRequestJobRunnerError.invalidBody
            }
            return try JSONSerialization.data(
                withJSONObject: body.renderedJSONObject(context: context),
                options: [.sortedKeys]
            )
        case .number(let value):
            return Data(String(value).utf8)
        case .bool(let value):
            return Data((value ? "true" : "false").utf8)
        case .null:
            return Data("null".utf8)
        }
    }

    private func paginationNextURL(
        from payload: MappingJSONValue,
        pagination: PackagedPluginRequestPagination,
        originalURL: URL
    ) throws -> URL? {
        switch pagination.type {
        case "jsonapi-next-link", "next-link":
            guard let path = pagination.path,
                  let value = try MappingSelector(path).resolve(in: payload)?.scalarString,
                  value.isEmpty == false else {
                return nil
            }
            guard let url = URL(string: value, relativeTo: originalURL)?.absoluteURL,
                  url.scheme == "https",
                  url.host?.lowercased() == originalURL.host?.lowercased() else {
                throw PluginRequestJobRunnerError.invalidPaginationURL(value)
            }
            return url
        default:
            return nil
        }
    }
}

private extension MappingJSONValue {
    func mergingObjectFields(_ fields: [String: MappingJSONValue]) -> MappingJSONValue {
        guard case .object(var object) = self else { return self }
        for (key, value) in fields {
            object[key] = value
        }
        return .object(object)
    }

    func mergingTopLevelArrays(from next: MappingJSONValue) -> MappingJSONValue {
        guard case .object(var object) = self,
              case .object(let nextObject) = next else {
            return self
        }
        for (key, nextValue) in nextObject {
            if case .array(let existingArray) = object[key],
               case .array(let nextArray) = nextValue {
                object[key] = .array(existingArray + nextArray)
            } else if object[key] == nil {
                object[key] = nextValue
            }
        }
        return .object(object)
    }
}

private extension PackagedPluginRequestBody {
    var isJSONContainer: Bool {
        switch self {
        case .object, .array:
            true
        case .string, .number, .bool, .null:
            false
        }
    }

    func renderedJSONObject(context: MappingTemplateContext) -> Any {
        switch self {
        case .string(let value):
            MappingTemplateRenderer.render(value, context: context)
        case .object(let object):
            object.mapValues { $0.renderedJSONObject(context: context) }
        case .array(let values):
            values.map { $0.renderedJSONObject(context: context) }
        case .number(let value):
            value
        case .bool(let value):
            value
        case .null:
            NSNull()
        }
    }
}
