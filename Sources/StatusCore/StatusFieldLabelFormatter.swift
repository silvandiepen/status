import Foundation

public enum StatusFieldLabelFormatter {
    public static func label(for field: String) -> String {
        switch field {
        case "actionUrl", "actionURL", "url", "link":
            return "Open"
        case "responseTimeMs":
            return "Response Time"
        case "statusCode":
            return "Status"
        default:
            break
        }

        let spaced = field
            .replacingOccurrences(of: #"([a-z0-9])([A-Z])"#, with: "$1 $2", options: .regularExpression)
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
        return spaced
            .split(separator: " ")
            .map { word in
                let lowercased = word.lowercased()
                if lowercased == "url" { return "URL" }
                if lowercased == "id" { return "ID" }
                if lowercased == "ms" { return "ms" }
                return word.prefix(1).uppercased() + word.dropFirst()
            }
            .joined(separator: " ")
    }
}
