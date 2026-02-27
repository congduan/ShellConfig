import Foundation
import Combine
import AppKit

class EnvVariableViewModel: ObservableObject {
    @Published var variables: [EnvVariable] = []
    @Published var filteredVariables: [EnvVariable] = []
    @Published var searchText: String = ""
    @Published var selectedVariable: EnvVariable?
    @Published var selectedTypes: Set<ConfigItemType> = Set(ConfigItemType.allCases)
    @Published var showAddSheet: Bool = false
    @Published var showEditSheet: Bool = false
    @Published var showDeleteConfirmation: Bool = false
    @Published var variableToDelete: EnvVariable?
    @Published var variableToEdit: EnvVariable?
    @Published var editError: String?
    @Published var showEditError: Bool = false
    
    private var configFile: ConfigFile?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        Publishers.CombineLatest($searchText, $selectedTypes)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query, types in
                self?.filterVariables(with: query, types: types)
            }
            .store(in: &cancellables)
    }
    
    func setConfigFile(_ configFile: ConfigFile?) {
        self.configFile = configFile
        self.variables = configFile?.variables ?? []
        filterVariables(with: searchText, types: selectedTypes)
    }
    
    func loadAllVariables() {
        self.variables = ShellConfigManager.shared.getAllVariables()
        filterVariables(with: searchText, types: selectedTypes)
    }
    
    func toggleType(_ type: ConfigItemType) {
        if selectedTypes.contains(type) {
            if selectedTypes.count > 1 {
                selectedTypes.remove(type)
            }
        } else {
            selectedTypes.insert(type)
        }
    }
    
    func selectAllTypes() {
        selectedTypes = Set(ConfigItemType.allCases)
    }
    
    private func filterVariables(with query: String, types: Set<ConfigItemType>) {
        var result = variables.filter { types.contains($0.type) }
        
        if !query.isEmpty {
            let lowercasedQuery = query.lowercased()
            result = result.filter { variable in
                variable.name.lowercased().contains(lowercasedQuery) ||
                variable.value.lowercased().contains(lowercasedQuery) ||
                (variable.comment?.lowercased().contains(lowercasedQuery) ?? false)
            }
        }
        
        filteredVariables = result
    }
    
    func clearSearch() {
        searchText = ""
    }
    
    var variableCount: Int {
        filteredVariables.count
    }
    
    var totalCount: Int {
        variables.count
    }
    
    var isFiltered: Bool {
        !searchText.isEmpty || selectedTypes.count < ConfigItemType.allCases.count
    }
    
    func typeCount(_ type: ConfigItemType) -> Int {
        variables.filter { $0.type == type }.count
    }
    
    func copyName(_ variable: EnvVariable) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(variable.name, forType: .string)
    }
    
    func copyValue(_ variable: EnvVariable) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(variable.value, forType: .string)
    }
    
    func addVariable(_ newVariable: EnvVariable) {
        guard let config = configFile else { return }
        
        let result = ConfigFileEditor.shared.addConfigItem(newVariable, to: config.path)
        
        switch result {
        case .success:
            ShellConfigManager.shared.refresh()
            if let updatedConfig = findUpdatedConfig(for: config.path) {
                setConfigFile(updatedConfig)
            }
            
        case .failure(let error):
            editError = error.errorDescription
            showEditError = true
        }
    }
    
    func updateVariable(_ updatedVariable: EnvVariable) {
        guard let config = configFile,
              let originalVariable = variableToEdit else { return }
        
        let result = ConfigFileEditor.shared.updateConfigItem(
            at: originalVariable.lineNumber,
            in: config.path,
            with: updatedVariable
        )
        
        switch result {
        case .success:
            ShellConfigManager.shared.refresh()
            if let updatedConfig = findUpdatedConfig(for: config.path) {
                setConfigFile(updatedConfig)
            }
            
        case .failure(let error):
            editError = error.errorDescription
            showEditError = true
        }
        
        variableToEdit = nil
    }
    
    func deleteVariable(_ variable: EnvVariable) {
        guard let config = configFile else { return }
        
        let result = ConfigFileEditor.shared.deleteConfigItem(at: variable.lineNumber, from: config.path)
        
        switch result {
        case .success:
            ShellConfigManager.shared.refresh()
            if let updatedConfig = findUpdatedConfig(for: config.path) {
                setConfigFile(updatedConfig)
            }
            
        case .failure(let error):
            editError = error.errorDescription
            showEditError = true
        }
    }
    
    func confirmDelete(_ variable: EnvVariable) {
        variableToDelete = variable
        showDeleteConfirmation = true
    }
    
    func executeDelete() {
        guard let variable = variableToDelete else { return }
        deleteVariable(variable)
        variableToDelete = nil
    }
    
    func startEdit(_ variable: EnvVariable) {
        variableToEdit = variable
        showEditSheet = true
    }
    
    func openInEditor() {
        guard let config = configFile else { return }
        let expandedPath = NSString(string: config.path).expandingTildeInPath
        NSWorkspace.shared.openFile(expandedPath, withApplication: "TextEdit")
    }
    
    func openInTerminal() {
        guard let config = configFile else { return }
        let expandedPath = NSString(string: config.path).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)
        NSWorkspace.shared.openFile(url.deletingLastPathComponent().path, withApplication: "Terminal")
    }
    
    private func findUpdatedConfig(for path: String) -> ConfigFile? {
        for shell in ShellConfigManager.shared.shells {
            for config in shell.configFiles {
                if config.path == path {
                    return config
                }
            }
        }
        return nil
    }
    
    var currentConfigPath: String? {
        configFile?.path
    }
}
