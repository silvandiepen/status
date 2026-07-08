import SwiftUI

#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

extension Color {
    static var statusBackground: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #elseif canImport(UIKit)
        Color(uiColor: .systemBackground)
        #else
        Color(.background)
        #endif
    }

    static var statusSurface: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #elseif canImport(UIKit)
        Color(uiColor: .secondarySystemBackground)
        #else
        Color(.secondary)
        #endif
    }
}
