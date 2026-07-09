import Foundation

public struct LocalPluginInstallResult: Equatable, Sendable {
    public var plugin: InstalledPlugin
    public var version: InstalledPluginVersion
    public var warnings: [LocalPluginInstallWarning]

    public init(
        plugin: InstalledPlugin,
        version: InstalledPluginVersion,
        warnings: [LocalPluginInstallWarning]
    ) {
        self.plugin = plugin
        self.version = version
        self.warnings = warnings
    }
}

public enum LocalPluginInstallWarning: Equatable, Sendable {
    case unsignedLocalDevPlugin(pluginID: String, permissions: [PluginPermission], domains: [String])
}

public enum LocalPluginValidationSeverity: String, Codable, Equatable, Sendable {
    case error
    case warning
}

public struct LocalPluginValidationDiagnostic: Equatable, Sendable, Identifiable {
    public var id: String
    public var severity: LocalPluginValidationSeverity
    public var file: String
    public var message: String

    public init(
        id: String,
        severity: LocalPluginValidationSeverity,
        file: String,
        message: String
    ) {
        self.id = id
        self.severity = severity
        self.file = file
        self.message = message
    }
}

public struct LocalPluginValidationReport: Equatable, Sendable {
    public var diagnostics: [LocalPluginValidationDiagnostic]

    public init(diagnostics: [LocalPluginValidationDiagnostic]) {
        self.diagnostics = diagnostics
    }

    public var errors: [LocalPluginValidationDiagnostic] {
        diagnostics.filter { $0.severity == .error }
    }

    public var warnings: [LocalPluginValidationDiagnostic] {
        diagnostics.filter { $0.severity == .warning }
    }

    public var isValid: Bool {
        errors.isEmpty
    }

    public var formattedSummary: String {
        guard diagnostics.isEmpty == false else {
            return "Local plugin validation passed."
        }
        return diagnostics
            .map { diagnostic in
                let prefix = diagnostic.severity == .error ? "Error" : "Warning"
                return "\(prefix) in \(diagnostic.file): \(diagnostic.message)"
            }
            .joined(separator: "\n")
    }
}

public enum LocalPluginInstallerError: Error, Equatable, LocalizedError, Sendable {
    case invalidRequestURL(requestID: String, url: String)
    case validationFailed(LocalPluginValidationReport)

    public var errorDescription: String? {
        switch self {
        case .invalidRequestURL(let requestID, let url):
            "Local plugin request \(requestID) has an invalid URL: \(url)"
        case .validationFailed(let report):
            "Local plugin validation failed.\n\(report.formattedSummary)"
        }
    }
}

public final class LocalPluginInstaller {
    private let store: StatusPersistenceStore
    private let installRoot: URL
    private let fileManager: FileManager
    private let decoder = JSONDecoder()

    public init(
        store: StatusPersistenceStore,
        installRoot: URL,
        fileManager: FileManager = .default
    ) {
        self.store = store
        self.installRoot = installRoot
        self.fileManager = fileManager
    }

    public func install(pluginDirectory: URL, installedAt: Date = Date()) throws -> LocalPluginInstallResult {
        let validatedPackage = try validatedPackage(pluginDirectory: pluginDirectory)
        let manifest = validatedPackage.manifest
        let manifestData = validatedPackage.manifestData
        let packageData = validatedPackage.packageData
        let packageDefinition = validatedPackage.packageDefinition

        let installDirectory = installRoot
            .appendingPathComponent(manifest.id, isDirectory: true)
            .appendingPathComponent(manifest.version, isDirectory: true)
        try fileManager.createDirectory(at: installDirectory, withIntermediateDirectories: true)

        let installedManifestURL = installDirectory.appendingPathComponent("manifest.json")
        let packageURL = installDirectory.appendingPathComponent("\(manifest.id)-\(manifest.version).statusplugin.zip")
        try manifestData.write(to: installedManifestURL, options: .atomic)
        try packageData.write(to: packageURL, options: .atomic)

        try store.installPlugin(
            PluginInstallRecord(
                manifest: manifest,
                trustLevel: .localDev,
                installPath: installDirectory.path,
                packagePath: packageURL.path,
                verification: PluginPackageVerificationResult(
                    pluginID: manifest.id,
                    version: manifest.version,
                    sha256: PluginPackageVerifier.sha256Hex(packageData),
                    signedBy: "local-dev"
                ),
                packageDefinition: packageDefinition,
                installedAt: installedAt
            )
        )

        guard let plugin = try store.installedPlugin(id: manifest.id),
              let version = try store.installedPluginVersions(pluginID: manifest.id).first(where: { $0.version == manifest.version }) else {
            throw PluginInstallerError.installRecordMissing(manifest.id, manifest.version)
        }

        return LocalPluginInstallResult(
            plugin: plugin,
            version: version,
            warnings: [
                .unsignedLocalDevPlugin(
                    pluginID: manifest.id,
                    permissions: manifest.permissions,
                    domains: manifest.domains
                )
            ]
        )
    }

    public func validate(pluginDirectory: URL) -> LocalPluginValidationReport {
        do {
            let validatedPackage = try validatedPackage(pluginDirectory: pluginDirectory)
            return LocalPluginValidationReport(diagnostics: localDevWarnings(for: validatedPackage.manifest))
        } catch LocalPluginInstallerError.validationFailed(let report) {
            return report
        } catch {
            return LocalPluginValidationReport(diagnostics: [
                diagnostic(
                    severity: .error,
                    file: pluginDirectory.lastPathComponent,
                    message: error.localizedDescription
                )
            ])
        }
    }

    private struct ValidatedLocalPluginPackage {
        var manifest: PluginManifest
        var manifestData: Data
        var packageData: Data
        var packageDefinition: PluginPackageDefinition
    }

    private func validatedPackage(pluginDirectory: URL) throws -> ValidatedLocalPluginPackage {
        var diagnostics: [LocalPluginValidationDiagnostic] = []
        let manifestURL = pluginDirectory.appendingPathComponent("manifest.json")
        let manifestData: Data
        do {
            manifestData = try Data(contentsOf: manifestURL)
        } catch {
            throw LocalPluginInstallerError.validationFailed(
                LocalPluginValidationReport(diagnostics: [
                    diagnostic(severity: .error, file: "manifest.json", message: error.localizedDescription)
                ])
            )
        }

        let manifest: PluginManifest
        do {
            manifest = try decoder.decode(PluginManifest.self, from: manifestData)
        } catch {
            throw LocalPluginInstallerError.validationFailed(
                LocalPluginValidationReport(diagnostics: [
                    diagnostic(severity: .error, file: "manifest.json", message: decodingMessage(error))
                ])
            )
        }

        let packageData: Data
        do {
            packageData = try PluginPackageBuilder.packageData(fromDirectory: pluginDirectory, fileManager: fileManager)
        } catch {
            diagnostics.append(diagnostic(severity: .error, file: pluginDirectory.lastPathComponent, message: error.localizedDescription))
            throw LocalPluginInstallerError.validationFailed(LocalPluginValidationReport(diagnostics: diagnostics))
        }

        let packageDefinition: PluginPackageDefinition
        do {
            packageDefinition = try PluginPackageDefinition.decode(from: packageData)
        } catch {
            diagnostics.append(diagnostic(severity: .error, file: "plugin package", message: error.localizedDescription))
            throw LocalPluginInstallerError.validationFailed(LocalPluginValidationReport(diagnostics: diagnostics))
        }

        do {
            try PluginManifestValidator.validate(
                PluginValidationInput(
                    manifest: manifest,
                    authKinds: packageDefinition.auth.map { [$0.type] } ?? [],
                    authDefinitions: packageDefinition.auth.map { [$0] } ?? [],
                    requests: try validationRequests(from: packageDefinition.requests),
                    actions: packageDefinition.actions.map { action in
                        PluginActionDeclaration(
                            type: action.id,
                            label: action.label,
                            requiresWritePermission: action.requiresWritePermission
                        )
                    }
                )
            )
        } catch {
            diagnostics.append(diagnostic(severity: .error, file: "manifest.json", message: error.localizedDescription))
        }

        diagnostics.append(contentsOf: localDevWarnings(for: manifest))
        guard diagnostics.contains(where: { $0.severity == .error }) == false else {
            throw LocalPluginInstallerError.validationFailed(LocalPluginValidationReport(diagnostics: diagnostics))
        }
        return ValidatedLocalPluginPackage(
            manifest: manifest,
            manifestData: manifestData,
            packageData: packageData,
            packageDefinition: packageDefinition
        )
    }

    private func validationRequests(from requests: PackagedPluginRequests) throws -> [PluginRequestDefinition] {
        try requests.requests.map { requestID, request in
            guard let url = URL(string: request.url) else {
                throw LocalPluginInstallerError.invalidRequestURL(requestID: requestID, url: request.url)
            }
            return PluginRequestDefinition(id: requestID, method: request.method, url: url)
        }
    }

    private func localDevWarnings(for manifest: PluginManifest) -> [LocalPluginValidationDiagnostic] {
        [
            diagnostic(
                severity: .warning,
                file: "manifest.json",
                message: "Local-dev plugins are unsigned. Review permissions and domains before enabling automation."
            )
        ]
    }

    private func diagnostic(
        severity: LocalPluginValidationSeverity,
        file: String,
        message: String
    ) -> LocalPluginValidationDiagnostic {
        LocalPluginValidationDiagnostic(
            id: "\(severity.rawValue):\(file):\(message)",
            severity: severity,
            file: file,
            message: message
        )
    }

    private func decodingMessage(_ error: Error) -> String {
        if let decodingError = error as? DecodingError {
            switch decodingError {
            case .keyNotFound(let key, let context):
                return "Missing key '\(key.stringValue)' at \(codingPath(context.codingPath))."
            case .typeMismatch(_, let context):
                return "Type mismatch at \(codingPath(context.codingPath)): \(context.debugDescription)"
            case .valueNotFound(_, let context):
                return "Missing value at \(codingPath(context.codingPath)): \(context.debugDescription)"
            case .dataCorrupted(let context):
                return "Invalid JSON at \(codingPath(context.codingPath)): \(context.debugDescription)"
            @unknown default:
                return error.localizedDescription
            }
        }
        return error.localizedDescription
    }

    private func codingPath(_ path: [CodingKey]) -> String {
        let rendered = path.map(\.stringValue).joined(separator: ".")
        return rendered.isEmpty ? "<root>" : rendered
    }
}
