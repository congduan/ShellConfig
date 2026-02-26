import SwiftUI

/// Sidebar view showing shell types and their config files
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
                        isExpanded: viewModel.isExpanded(shell),
                        onToggle: { viewModel.toggleExpansion(for: shell) },
                        onSelectConfig: { config in viewModel.selectConfigFile(config) },
                        selectedConfigFile: viewModel.selectedConfigFile
                    )
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 220)
    }
    
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            Text("No Configuration Files Found")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("No shell configuration files were found in your home directory.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

/// Section for a single shell type
struct ShellSectionView: View {
    let shell: Shell
    let isExpanded: Bool
    let onToggle: () -> Void
    let onSelectConfig: (ConfigFile) -> Void
    let selectedConfigFile: ConfigFile?
    
    var body: some View {
        Section {
            ForEach(shell.configFiles.filter { $0.exists }) { config in
                ConfigFileRowView(
                    configFile: config,
                    isSelected: selectedConfigFile?.id == config.id
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelectConfig(config)
                }
                .tag(config)
            }
        } header: {
            ShellSectionHeader(
                shell: shell,
                isExpanded: isExpanded,
                configCount: shell.configFiles.filter { $0.exists }.count,
                onToggle: onToggle
            )
        }
    }
}

/// Header for shell section
struct ShellSectionHeader: View {
    let shell: Shell
    let isExpanded: Bool
    let configCount: Int
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
            
            Image(systemName: shell.icon)
                .foregroundColor(.accentColor)
            
            Text(shell.name)
                .font(.system(size: 12, weight: .semibold))
            
            Spacer()
            
            Text("\(configCount)")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
    }
}

/// Row view for a config file
struct ConfigFileRowView: View {
    let configFile: ConfigFile
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.text")
                .foregroundColor(isSelected ? .white : .blue)
                .font(.system(size: 12))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(configFile.fileName)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(configFile.displayPath)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            if !configFile.variables.isEmpty {
                Text("\(configFile.variables.count)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .white : .secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
