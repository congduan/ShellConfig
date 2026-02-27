import Foundation
import Combine

class ShellListViewModel: ObservableObject {
    @Published var shells: [Shell] = []
    @Published var selectedConfigFile: ConfigFile?
    @Published var expandedShells: Set<UUID> = []
    @Published var showAddConfigFileSheet: Bool = false
    @Published var showDeleteConfigFileConfirmation: Bool = false
    @Published var configFileToDelete: ConfigFile?
    @Published var editError: String?
    @Published var showEditError: Bool = false
    @Published var selectedShellForNewFile: ShellType?
    
    private var configManager = ShellConfigManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        configManager.$shells
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shells in
                self?.shells = shells
                self?.autoExpandShells(with: shells)
            }
            .store(in: &cancellables)
    }
    
    private func autoExpandShells(with shells: [Shell]) {
        for shell in shells {
            let hasExistingFiles = shell.configFiles.contains { $0.exists }
            if hasExistingFiles {
                expandedShells.insert(shell.id)
            }
        }
    }
    
    func toggleExpansion(for shell: Shell) {
        if expandedShells.contains(shell.id) {
            expandedShells.remove(shell.id)
        } else {
            expandedShells.insert(shell.id)
        }
    }
    
    func isExpanded(_ shell: Shell) -> Bool {
        expandedShells.contains(shell.id)
    }
    
    func selectConfigFile(_ configFile: ConfigFile) {
        selectedConfigFile = configFile
    }
    
    var totalConfigFileCount: Int {
        shells.reduce(0) { $0 + $1.configFiles.filter { $0.exists }.count }
    }
    
    func showAddFileSheet(for shellType: ShellType) {
        selectedShellForNewFile = shellType
        showAddConfigFileSheet = true
    }
    
    func createConfigFile(name: String, shellType: ShellType) {
        let path = constructPath(for: name, shellType: shellType)
        
        let result = ConfigFileEditor.shared.createConfigFile(at: path, shellType: shellType)
        
        switch result {
        case .success:
            configManager.refresh()
            if let newConfig = findConfigFile(at: path) {
                selectConfigFile(newConfig)
            }
            
        case .failure(let error):
            editError = error.errorDescription
            showEditError = true
        }
    }
    
    func confirmDeleteConfigFile(_ configFile: ConfigFile) {
        configFileToDelete = configFile
        showDeleteConfigFileConfirmation = true
    }
    
    func deleteConfigFile() {
        guard let configFile = configFileToDelete else { return }
        
        let result = ConfigFileEditor.shared.deleteConfigFile(at: configFile.path)
        
        switch result {
        case .success:
            if selectedConfigFile?.id == configFile.id {
                selectedConfigFile = nil
            }
            configManager.refresh()
            
        case .failure(let error):
            editError = error.errorDescription
            showEditError = true
        }
        
        configFileToDelete = nil
    }
    
    private func constructPath(for name: String, shellType: ShellType) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        
        switch shellType {
        case .bash, .zsh:
            return "\(home)/\(name)"
        case .fish:
            return "\(home)/.config/fish/\(name)"
        }
    }
    
    private func findConfigFile(at path: String) -> ConfigFile? {
        for shell in shells {
            for config in shell.configFiles {
                if config.path == path {
                    return config
                }
            }
        }
        return nil
    }
    
    func getDefaultFileName(for shellType: ShellType) -> String {
        switch shellType {
        case .bash:
            return ".bashrc"
        case .zsh:
            return ".zshrc"
        case .fish:
            return "config.fish"
        }
    }
    
    func isValidFileName(_ name: String, for shellType: ShellType) -> Bool {
        guard !name.isEmpty else { return false }
        
        let invalidCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|")
        guard name.rangeOfCharacter(from: invalidCharacters) == nil else { return false }
        
        for shell in shells {
            for config in shell.configFiles {
                if config.fileName == name {
                    return false
                }
            }
        }
        
        return true
    }
}
