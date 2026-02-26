import SwiftUI

/// Detail view showing environment variables for selected config file
struct EnvVariableListView: View {
    @ObservedObject var viewModel: EnvVariableViewModel
    let selectedConfigFile: ConfigFile?
    
    var body: some View {
        VStack(spacing: 0) {
            if let config = selectedConfigFile {
                // Header with file info
                VariableListHeader(configFile: config)
                
                // Search field
                SearchFieldView(
                    searchText: $viewModel.searchText,
                    placeholder: "Filter variables..."
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                // Variable list
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
                                    onCopyValue: { viewModel.copyValue(variable) }
                                )
                                Divider()
                                    .padding(.leading, 16)
                            }
                        }
                    }
                }
                
                // Status bar
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
    }
}

/// Header showing selected file info
struct VariableListHeader: View {
    let configFile: ConfigFile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.blue)
                
                Text(configFile.fileName)
                    .font(.headline)
                
                Spacer()
                
                if let lastModified = configFile.lastModified {
                    Text("Modified: \(lastModified.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(configFile.displayPath)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

/// Search field
struct SearchFieldView: View {
    @Binding var searchText: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $searchText)
                .textFieldStyle(.plain)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color(nsColor: .textBackgroundColor))
        .cornerRadius(6)
    }
}

/// Empty state when no variables found
struct EmptyVariableState: View {
    let hasSearch: Bool
    let totalCount: Int
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: hasSearch ? "magnifyingglass" : "tray")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text(hasSearch ? "No Matching Variables" : "No Variables Found")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if hasSearch {
                Text("Try adjusting your search query")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if totalCount == 0 {
                Text("This configuration file doesn't contain any environment variables.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Status bar showing variable count
struct VariableListStatusBar: View {
    let count: Int
    let total: Int
    let isFiltered: Bool
    
    var body: some View {
        HStack {
            if isFiltered {
                Text("\(count) of \(total) variables")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("\(count) variables")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
