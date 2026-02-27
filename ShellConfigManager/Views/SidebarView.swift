import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: ShellListViewModel
    
    var body: some View {
        List(selection: $viewModel.selectedConfigFile) {
            if viewModel.shells.isEmpty && !ShellConfigManager.shared.isLoading {
                emptyState
            } else {
                ForEach(viewModel.shells) { shell in
                    ShellSectionView(
                        shell: shell,
                        isExpanded: Binding(
                            get: { viewModel.isExpanded(shell) },
                            set: { _ in viewModel.toggleExpansion(for: shell) }
                        ),
                        onSelectConfig: { config in viewModel.selectConfigFile(config) },
                        onDeleteConfig: { config in viewModel.confirmDeleteConfigFile(config) },
                        onAddConfig: { viewModel.showAddFileSheet(for: shell.type) },
                        selectedConfigFile: viewModel.selectedConfigFile
                    )
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 220)
        .sheet(isPresented: $viewModel.showAddConfigFileSheet) {
            if let shellType = viewModel.selectedShellForNewFile {
                AddConfigFileSheet(viewModel: viewModel, shellType: shellType)
            }
        }
        .alert("Delete Configuration File?", isPresented: $viewModel.showDeleteConfigFileConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.configFileToDelete = nil
            }
            Button("Delete", role: .destructive) {
                viewModel.deleteConfigFile()
            }
        } message: {
            if let config = viewModel.configFileToDelete {
                Text("Are you sure you want to delete '\(config.fileName)'? This action cannot be undone and the file will be permanently removed.")
            }
        }
        .alert("Error", isPresented: $viewModel.showEditError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let error = viewModel.editError {
                Text(error)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 4) {
                Text("No Config Files")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("No shell configuration files were found in your home directory.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct ShellSectionView: View {
    let shell: Shell
    @Binding var isExpanded: Bool
    let onSelectConfig: (ConfigFile) -> Void
    let onDeleteConfig: (ConfigFile) -> Void
    let onAddConfig: () -> Void
    let selectedConfigFile: ConfigFile?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 20, height: 36)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isExpanded.toggle()
                    }
                
                ShellSectionHeader(
                    shell: shell,
                    configCount: shell.configFiles.filter { $0.exists }.count,
                    onAdd: onAddConfig
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    isExpanded.toggle()
                }
            }
            
            if isExpanded {
                ForEach(shell.configFiles.filter { $0.exists }) { config in
                    ConfigFileRowView(
                        configFile: config,
                        isSelected: selectedConfigFile?.id == config.id,
                        onDelete: { onDeleteConfig(config) }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelectConfig(config)
                    }
                    .tag(config)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

struct ShellSectionHeader: View {
    let shell: Shell
    let configCount: Int
    let onAdd: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(shellColor.opacity(0.15))
                    .frame(width: 28, height: 28)
                
                Image(systemName: shell.icon)
                    .font(.system(size: 13))
                    .foregroundColor(shellColor)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(shell.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("\(configCount) file\(configCount == 1 ? "" : "s")")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onAdd) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 14))
                    .foregroundColor(shellColor)
            }
            .buttonStyle(.plain)
            .help("Add new \(shell.name) config file")
            
            if configCount > 0 {
                Text("\(configCount)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(shellColor)
                    .cornerRadius(10)
            }
        }
        .frame(height: 36)
    }
    
    private var shellColor: Color {
        switch shell.type {
        case .bash: return .green
        case .zsh: return .blue
        case .fish: return .cyan
        }
    }
}

struct ConfigFileRowView: View {
    let configFile: ConfigFile
    let isSelected: Bool
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(isSelected ? Color.white.opacity(0.2) : Color.blue.opacity(0.1))
                    .frame(width: 26, height: 26)
                
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : .blue)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(configFile.fileName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
                
                Text(configFile.displayPath)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            if !configFile.variables.isEmpty {
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(configFile.variables.count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isSelected ? .white : .secondary)
                    
                    Text("items")
                        .font(.system(size: 8))
                        .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
                }
            }
            
            if isHovered {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct AddConfigFileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ShellListViewModel
    let shellType: ShellType
    
    @State private var fileName: String = ""
    @State private var showError: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("New \(shellType.rawValue) Config File")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("File Name")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    TextField("Enter file name", text: $fileName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, design: .monospaced))
                        .padding(10)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(fileNameError != nil ? Color.red : Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                    
                    if let error = fileNameError {
                        Text(error)
                            .font(.system(size: 10))
                            .foregroundColor(.red)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Location")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text(locationPath)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    
                    Text("A new empty configuration file will be created at the specified location.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
            }
            .padding(20)
            
            Spacer()
            
            Divider()
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Create") {
                    viewModel.createConfigFile(name: fileName, shellType: shellType)
                    dismiss()
                }
                .keyboardShortcut(.return)
                .disabled(!isValid)
            }
            .padding(20)
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(width: 400, height: 320)
        .onAppear {
            fileName = viewModel.getDefaultFileName(for: shellType)
        }
    }
    
    private var locationPath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        switch shellType {
        case .bash, .zsh:
            return "~\(fileName.isEmpty ? "" : "/\(fileName)")"
        case .fish:
            return "~/.config/fish\(fileName.isEmpty ? "" : "/\(fileName)")"
        }
    }
    
    private var fileNameError: String? {
        if fileName.isEmpty {
            return nil
        }
        
        if !fileName.hasPrefix(".") && (shellType == .bash || shellType == .zsh) {
            return "Config files usually start with a dot (.)"
        }
        
        if !viewModel.isValidFileName(fileName, for: shellType) {
            return "File name already exists or contains invalid characters"
        }
        
        return nil
    }
    
    private var isValid: Bool {
        !fileName.isEmpty && viewModel.isValidFileName(fileName, for: shellType)
    }
}
