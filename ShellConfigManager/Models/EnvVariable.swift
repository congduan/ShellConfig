import Foundation

/// Represents an environment variable extracted from a config file
struct EnvVariable: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let value: String
    let lineNumber: Int
    let comment: String?
    let isExport: Bool
    let isConditional: Bool
    let rawLine: String
    
    /// Check if the value looks like a path
    var isPathValue: Bool {
        value.contains("/") && (value.hasPrefix("/") || value.hasPrefix("~") || value.contains(":"))
    }
    
    /// Check if the value is a PATH-like variable (contains colons)
    var isPathVariable: Bool {
        name.uppercased() == "PATH" || name.uppercased().hasSuffix("PATH")
    }
    
    /// Split PATH-like values into individual paths
    var pathComponents: [String]? {
        guard isPathVariable else { return nil }
        return value.split(separator: ":").map(String.init)
    }
    
    /// Check if value contains environment variable references
    var containsVariableRefs: Bool {
        value.contains("$") || value.contains("${")
    }
    
    init(name: String, value: String, lineNumber: Int, comment: String? = nil, isExport: Bool = true, isConditional: Bool = false, rawLine: String = "") {
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
    
    static func == (lhs: EnvVariable, rhs: EnvVariable) -> Bool {
        lhs.id == rhs.id
    }
}
