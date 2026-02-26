import Foundation
import Combine

/// ViewModel for environment variable list
class EnvVariableViewModel: ObservableObject {
    @Published var variables: [EnvVariable] = []
    @Published var filteredVariables: [EnvVariable] = []
    @Published var searchText: String = ""
    @Published var selectedVariable: EnvVariable?
    
    private var configFile: ConfigFile?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Set up search filtering
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.filterVariables(with: query)
            }
            .store(in: &cancellables)
    }
    
    /// Set the current config file and load its variables
    func setConfigFile(_ configFile: ConfigFile?) {
        self.configFile = configFile
        self.variables = configFile?.variables ?? []
        filterVariables(with: searchText)
    }
    
    /// Load all variables
    func loadAllVariables() {
        self.variables = ShellConfigManager.shared.getAllVariables()
        filterVariables(with: searchText)
    }
    
    /// Filter variables by search query
    private func filterVariables(with query: String) {
        guard !query.isEmpty else {
            filteredVariables = variables
            return
        }
        
        let lowercasedQuery = query.lowercased()
        
        filteredVariables = variables.filter { variable in
            variable.name.lowercased().contains(lowercasedQuery) ||
            variable.value.lowercased().contains(lowercasedQuery) ||
            (variable.comment?.lowercased().contains(lowercasedQuery) ?? false)
        }
    }
    
    /// Clear search
    func clearSearch() {
        searchText = ""
    }
    
    /// Get variable count
    var variableCount: Int {
        filteredVariables.count
    }
    
    /// Get total count (including filtered out)
    var totalCount: Int {
        variables.count
    }
    
    /// Check if showing filtered results
    var isFiltered: Bool {
        !searchText.isEmpty && filteredVariables.count != variables.count
    }
    
    /// Copy variable name to clipboard
    func copyName(_ variable: EnvVariable) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(variable.name, forType: .string)
    }
    
    /// Copy variable value to clipboard
    func copyValue(_ variable: EnvVariable) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(variable.value, forType: .string)
    }
}

// Import AppKit for NSPasteboard
import AppKit
