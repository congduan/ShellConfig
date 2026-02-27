import SwiftUI

struct EnvVariableListView: View {
    @ObservedObject var viewModel: EnvVariableViewModel
    let selectedConfigFile: ConfigFile?
    
    var body: some View {
        VStack(spacing: 0) {
            if let config = selectedConfigFile {
                VariableListHeader(configFile: config, viewModel: viewModel)
                
                if !viewModel.variables.isEmpty {
                    StatisticsOverviewView(viewModel: viewModel)
                }
                
                SearchFieldView(
                    searchText: $viewModel.searchText,
                    placeholder: "Search items..."
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                if viewModel.filteredVariables.isEmpty {
                    EmptyVariableState(
                        hasSearch: !viewModel.searchText.isEmpty,
                        totalCount: viewModel.totalCount
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.filteredVariables) { variable in
                                EnvVariableRowView(
                                    variable: variable,
                                    onCopyName: { viewModel.copyName(variable) },
                                    onCopyValue: { viewModel.copyValue(variable) },
                                    onDelete: { viewModel.confirmDelete(variable) }
                                )
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                VariableListStatusBar(
                    count: viewModel.variableCount,
                    total: viewModel.totalCount,
                    isFiltered: viewModel.isFiltered
                )
            } else {
                EmptyStateView()
            }
        }
        .frame(minWidth: 400)
        .sheet(isPresented: $viewModel.showAddSheet) {
            AddConfigItemSheet(viewModel: viewModel)
        }
        .alert("Delete Configuration Item?", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.variableToDelete = nil
            }
            Button("Delete", role: .destructive) {
                viewModel.executeDelete()
            }
        } message: {
            if let variable = viewModel.variableToDelete {
                Text("Are you sure you want to delete '\(variable.name)' from line \(variable.lineNumber)? This action cannot be undone.")
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
}

struct StatisticsOverviewView: View {
    @ObservedObject var viewModel: EnvVariableViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ConfigItemType.allCases, id: \.self) { type in
                    StatCard(
                        type: type,
                        count: viewModel.typeCount(type),
                        isSelected: viewModel.selectedTypes.contains(type),
                        action: { viewModel.toggleType(type) }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct StatCard: View {
    let type: ConfigItemType
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(type.color.swiftUIColor.opacity(isSelected ? 0.2 : 0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: type.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(type.color.swiftUIColor)
                }
                
                Text("\(count)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(type.rawValue)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 70)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? type.color.swiftUIColor.opacity(0.1) : Color(nsColor: .controlBackgroundColor).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? type.color.swiftUIColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct TypeFilterView: View {
    @ObservedObject var viewModel: EnvVariableViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ConfigItemType.allCases, id: \.self) { type in
                    TypeFilterChip(
                        type: type,
                        count: viewModel.typeCount(type),
                        isSelected: viewModel.selectedTypes.contains(type),
                        action: { viewModel.toggleType(type) }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
    }
}

struct TypeFilterChip: View {
    let type: ConfigItemType
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: type.icon)
                    .font(.system(size: 9))
                
                Text(type.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                
                if count > 0 {
                    Text("(\(count))")
                        .font(.system(size: 9))
                }
            }
            .foregroundColor(isSelected ? type.color.swiftUIColor : .secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isSelected ? type.color.swiftUIColor.opacity(0.15) : Color.secondary.opacity(0.1))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? type.color.swiftUIColor : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct VariableListHeader: View {
    let configFile: ConfigFile
    @ObservedObject var viewModel: EnvVariableViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(configFile.fileName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text(configFile.displayPath)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    if let lastModified = configFile.lastModified {
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(lastModified.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: { viewModel.showAddSheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 12))
                        Text("Add")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                Menu {
                    Button(action: { viewModel.openInEditor() }) {
                        Label("Open in TextEdit", systemImage: "doc.text")
                    }
                    
                    Button(action: { viewModel.openInTerminal() }) {
                        Label("Open in Terminal", systemImage: "terminal")
                    }
                    
                    Divider()
                    
                    Button(action: { 
                        let expandedPath = NSString(string: configFile.path).expandingTildeInPath
                        if let url = URL(string: "file://\(expandedPath)") {
                            NSWorkspace.shared.activateFileViewerSelecting([url])
                        }
                    }) {
                        Label("Reveal in Finder", systemImage: "folder")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 28)
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

struct SearchFieldView: View {
    @Binding var searchText: String
    let placeholder: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color(nsColor: .textBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

struct EmptyVariableState: View {
    let hasSearch: Bool
    let totalCount: Int
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: hasSearch ? "magnifyingglass" : "tray")
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 4) {
                Text(hasSearch ? "No Matching Items" : "No Items Found")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if hasSearch {
                    Text("Try adjusting your search or filter criteria")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if totalCount == 0 {
                    Text("This configuration file doesn't contain any recognizable items.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct VariableListStatusBar: View {
    let count: Int
    let total: Int
    let isFiltered: Bool
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 10))
                
                if isFiltered {
                    Text("Showing \(count) of \(total) items")
                        .font(.system(size: 10))
                } else {
                    Text("\(count) items total")
                        .font(.system(size: 10))
                }
            }
            .foregroundColor(.secondary)
            
            Spacer()
            
            if isFiltered {
                Text("Filtered")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
