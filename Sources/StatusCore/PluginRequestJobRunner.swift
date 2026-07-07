import Foundation

public struct PluginHTTPRequest: Equatable, Sendable {
    public var method: String
    public var url: URL
    public var headers: [String: String]
    public var timeoutSeconds: TimeInterval?

    public init(method: String, url: URL, headers: [String: String] = [:], timeoutSeconds: TimeInterval? = nil) {
        self.method = method
        self.url = url
        self.headers = headers
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

    public var errorDescription: String? {
        switch self {
        case .missingRequest(let requestID):
            "Plugin request is not declared: \(requestID)"
        case .invalidURL(let url):
            "Plugin request URL is invalid: \(url)"
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
        let response = try await transport.response(for: request)
        let payload = decodePayload(response: response, variables: input.variables)
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

        return PluginHTTPRequest(
            method: definition.method,
            url: url,
            headers: input.headers,
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
}

private extension MappingJSONValue {
    func mergingObjectFields(_ fields: [String: MappingJSONValue]) -> MappingJSONValue {
        guard case .object(var object) = self else { return self }
        for (key, value) in fields {
            object[key] = value
        }
        return .object(object)
    }
}
