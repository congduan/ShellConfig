import Foundation
import Combine

/// ViewModel for the shell list sidebar
class ShellListViewModel: ObservableObject {
    @Published var shells: [Shell] = []
    @Published var selectedConfigFile: ConfigFile?
    @Published var expandedShells: Set<UUID> = []
    
    private var configManager = ShellConfigManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Subscribe to config manager updates
        configManager.$shells
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shells in
                self?.shells = shells
                // Auto-expand shells with existing files
                self?.autoExpandShells(with: shells)
            }
            .store(in: &cancellables)
    }
    
    /// Auto-expand shells that have config files
    private func autoExpandShells(with shells: [Shell]) {
        for shell in shells {
            let hasExistingFiles = shell.configFiles.contains { $0.exists }
            if hasExistingFiles {
                expandedShells.insert(shell.id)
            }
        }
    }
    
    /// Toggle shell expansion
    func toggleExpansion(for shell: Shell) {
        if expandedShells.contains(shell.id) {
            expandedShells.remove(shell.id)
        } else {
            expandedShells.insert(shell.id)
        }
    }
    
    /// Check if shell is expanded
    func isExpanded(_ shell: Shell) -> Bool {
        expandedShells.contains(shell.id)
    }
    
    /// Select a config file
    func selectConfigFile(_ configFile: ConfigFile) {
        selectedConfigFile = configFile
    }
    
    /// Get total config file count
    var totalConfigFileCount: Int {
        shells.reduce(0) { $0 + $1.configFiles.filter { $0.exists }.count }
    }
    
    /// Refresh configs
    func refresh() {
        configManager.refresh()
    }
}
