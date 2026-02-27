import Foundation
import SwiftUI

enum ConfigItemType: String, CaseIterable {
    case environmentVariable = "Environment Variable"
    case function = "Function"
    case alias = "Alias"
    case source = "Source"
    case export = "Export"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .environmentVariable: return "variable"
        case .function: return "function"
        case .alias: return "arrow.forward"
        case .source: return "arrow.down.doc"
        case .export: return "square.and.arrow.up"
        case .other: return "ellipsis.circle"
        }
    }
    
    var color: ConfigItemColor {
        switch self {
        case .environmentVariable: return .blue
        case .function: return .purple
        case .alias: return .orange
        case .source: return .cyan
        case .export: return .green
        case .other: return .gray
        }
    }
}

enum ConfigItemColor {
    case blue, purple, orange, cyan, green, gray, red
    
    var swiftUIColor: SwiftUI.Color {
        switch self {
        case .blue: return .blue
        case .purple: return SwiftUI.Color(nsColor: NSColor(red: 0.345, green: 0.337, blue: 0.839, alpha: 1.0))
        case .orange: return .orange
        case .cyan: return .cyan
        case .green: return .green
        case .gray: return .secondary
        case .red: return .red
        }
    }
}

struct ConfigItem: Identifiable, Hashable {
    let id = UUID()
    let type: ConfigItemType
    let name: String
    let value: String
    let lineNumber: Int
    let comment: String?
    let isExport: Bool
    let isConditional: Bool
    let rawLine: String
    
    var isPathValue: Bool {
        type == .environmentVariable && value.contains("/") && (value.hasPrefix("/") || value.hasPrefix("~") || value.contains(":"))
    }
    
    var isPathVariable: Bool {
        type == .environmentVariable && (name.uppercased() == "PATH" || name.uppercased().hasSuffix("PATH"))
    }
    
    var pathComponents: [String]? {
        guard isPathVariable else { return nil }
        return value.split(separator: ":").map(String.init)
    }
    
    var containsVariableRefs: Bool {
        value.contains("$") || value.contains("${")
    }
    
    var functionName: String? {
        guard type == .function else { return nil }
        return name
    }
    
    var aliasCommand: String? {
        guard type == .alias else { return nil }
        return value
    }
    
    var sourcePath: String? {
        guard type == .source else { return nil }
        return value
    }
    
    init(type: ConfigItemType = .environmentVariable, name: String, value: String, lineNumber: Int, comment: String? = nil, isExport: Bool = false, isConditional: Bool = false, rawLine: String = "") {
        self.type = type
        self.name = name
        self.value = value
        self.lineNumber = lineNumber
        self.comment = comment
        self.isExport = isExport
        self.isConditional = isConditional
        self.rawLine = rawLine
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ConfigItem, rhs: ConfigItem) -> Bool {
        lhs.id == rhs.id
    }
}

typealias EnvVariable = ConfigItem
