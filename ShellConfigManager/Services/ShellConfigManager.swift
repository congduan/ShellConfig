import Foundation

/// Main service for managing shell configurations
class ShellConfigManager: ObservableObject {
    static let shared = ShellConfigManager()
    
    @Published var shells: [Shell] = []
    @Published var isLoading = false
    
    private let parser = ConfigFileParser()
    private let fileManager = FileManager.default
    
    private init() {
        loadConfigs()
    }
    
    /// Get the user's home directory
    private var homeDirectory: String {
        fileManager.homeDirectoryForCurrentUser.path
    }
    
    /// Load all shell configurations
    func loadConfigs() {
        isLoading = true
        
        var loadedShells: [Shell] = []
        
        // Load Bash configs
        let bashConfigs = loadConfigsForShell(.bash)
        loadedShells.append(Shell(type: .bash, configFiles: bashConfigs))
        
        // Load Zsh configs
        let zshConfigs = loadConfigsForShell(.zsh)
        loadedShells.append(Shell(type: .zsh, configFiles: zshConfigs))
        
        // Load Fish configs
        let fishConfigs = loadConfigsForShell(.fish)
        loadedShells.append(Shell(type: .fish, configFiles: fishConfigs))
        
        // Filter out shells with no existing config files
        shells = loadedShells.filter { !$0.configFiles.isEmpty }
        
        isLoading = false
    }
    
    /// Load configuration files for a specific shell type
    private func loadConfigsForShell(_ shellType: ShellType) -> [ConfigFile] {
        var configFiles: [ConfigFile] = []
        
        for fileName in shellType.configFileNames {
            let path = constructPath(for: fileName, shellType: shellType)
            let (variables, error) = parser.parseFile(at: path)
            
            // Get file attributes
            var lastModified: Date?
            var exists = false
            
            if fileManager.fileExists(atPath: path) {
                exists = true
                if let attributes = try? fileManager.attributesOfItem(atPath: path),
                   let modDate = attributes[.modificationDate] as? Date {
                    lastModified = modDate
                }
            }
            
            let configFile = ConfigFile(
                path: path,
                shellType: shellType,
                variables: variables,
                lastModified: lastModified,
                exists: exists,
                parseError: error
            )
            
            configFiles.append(configFile)
        }
        
        // Sort by priority: existing files first, then by name
        return configFiles.sorted { file1, file2 in
            if file1.exists != file2.exists {
                return file1.exists
            }
            return file1.fileName < file2.fileName
        }
    }
    
    /// Construct full path for a config file
    private func constructPath(for fileName: String, shellType: ShellType) -> String {
        if shellType == .fish {
            // Fish config is in ~/.config/fish/
            return "\(homeDirectory)/.config/fish/\(fileName)"
        }
        
        // Bash and Zsh configs are in home directory
        return "\(homeDirectory)/\(fileName)"
    }
    
    /// Refresh all configurations
    func refresh() {
        loadConfigs()
    }
    
    /// Get all variables from all config files
    func getAllVariables() -> [EnvVariable] {
        var allVariables: [EnvVariable] = []
        
        for shell in shells {
            for config in shell.configFiles where config.exists {
                allVariables.append(contentsOf: config.variables)
            }
        }
        
        return allVariables
    }
    
    /// Search variables by name or value
    func searchVariables(query: String, in configFile: ConfigFile?) -> [EnvVariable] {
        let variables: [EnvVariable]
        
        if let config = configFile {
            variables = config.variables
        } else {
            variables = getAllVariables()
        }
        
        guard !query.isEmpty else { return variables }
        
        let lowercasedQuery = query.lowercased()
        
        return variables.filter { variable in
            variable.name.lowercased().contains(lowercasedQuery) ||
            variable.value.lowercased().contains(lowercasedQuery) ||
            (variable.comment?.lowercased().contains(lowercasedQuery) ?? false)
        }
    }
    
    /// Get unique variable names across all configs
    func getUniqueVariableNames() -> [String] {
        let variables = getAllVariables()
        let names = Set(variables.map { $0.name })
        return Array(names).sorted()
    }
    
    /// Get count of total variables
    func getTotalVariableCount() -> Int {
        return getAllVariables().count
    }
}
