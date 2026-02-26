import Foundation

/// Represents a shell type (Bash, Zsh, Fish)
enum ShellType: String, CaseIterable, Identifiable, Codable {
    case bash = "Bash"
    case zsh = "Zsh"
    case fish = "Fish"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .bash: return "terminal"
        case .zsh: return "terminal.fill"
        case .fish: return "fish"
        }
    }
    
    var configFileNames: [String] {
        switch self {
        case .bash:
            return [".bashrc", ".bash_profile", ".bash_login", ".profile"]
        case .zsh:
            return [".zshrc", ".zprofile", ".zshenv"]
        case .fish:
            return ["config.fish"]
        }
    }
}

/// Model representing a shell with its configuration files
struct Shell: Identifiable, Hashable {
    let id = UUID()
    let type: ShellType
    var configFiles: [ConfigFile]
    
    var name: String { type.rawValue }
    var icon: String { type.icon }
    
    init(type: ShellType, configFiles: [ConfigFile] = []) {
        self.type = type
        self.configFiles = configFiles
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Shell, rhs: Shell) -> Bool {
        lhs.id == rhs.id
    }
}
