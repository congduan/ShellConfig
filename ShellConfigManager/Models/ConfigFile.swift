import Foundation

/// Represents a shell configuration file
struct ConfigFile: Identifiable, Hashable {
    let id = UUID()
    let path: String
    let shellType: ShellType
    var variables: [EnvVariable]
    var lastModified: Date?
    var exists: Bool
    var parseError: String?
    
    var fileName: String {
        (path as NSString).lastPathComponent
    }
    
    var directoryPath: String {
        (path as NSString).deletingLastPathComponent
    }
    
    var displayPath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
    
    init(path: String, shellType: ShellType, variables: [EnvVariable] = [], lastModified: Date? = nil, exists: Bool = true, parseError: String? = nil) {
        self.path = path
        self.shellType = shellType
        self.variables = variables
        self.lastModified = lastModified
        self.exists = exists
        self.parseError = parseError
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ConfigFile, rhs: ConfigFile) -> Bool {
        lhs.id == rhs.id
    }
}
