import SwiftUI

struct AddConfigItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: EnvVariableViewModel
    
    @State private var selectedType: ConfigItemType = .environmentVariable
    @State private var name: String = ""
    @State private var value: String = ""
    @State private var comment: String = ""
    @State private var isExport: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Add New Configuration")
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
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    TypeSelectorSection(selectedType: $selectedType)
                    
                    NameSection(name: $name, selectedType: selectedType)
                    
                    if selectedType != .export {
                        ValueSection(value: $value, selectedType: selectedType)
                    }
                    
                    if selectedType == .environmentVariable {
                        ExportToggle(isExport: $isExport)
                    }
                    
                    CommentSection(comment: $comment)
                    
                    if let path = viewModel.currentConfigPath {
                        ConfigPathInfo(path: path)
                    }
                }
                .padding(20)
            }
            
            Divider()
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Add") {
                    addItem()
                }
                .keyboardShortcut(.return)
                .disabled(!isValid)
            }
            .padding(20)
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(width: 500, height: 520)
    }
    
    private var isValid: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        
        if selectedType == .source {
            return !value.trimmingCharacters(in: .whitespaces).isEmpty
        }
        
        return true
    }
    
    private func addItem() {
        let newItem = EnvVariable(
            type: selectedType,
            name: name.trimmingCharacters(in: .whitespaces),
            value: value.trimmingCharacters(in: .whitespaces),
            lineNumber: 0,
            comment: comment.trimmingCharacters(in: .whitespaces).isEmpty ? nil : comment.trimmingCharacters(in: .whitespaces),
            isExport: isExport,
            rawLine: ""
        )
        
        viewModel.addVariable(newItem)
        dismiss()
    }
}

struct TypeSelectorSection: View {
    @Binding var selectedType: ConfigItemType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Type")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                ForEach([ConfigItemType.environmentVariable, .alias, .source], id: \.self) { type in
                    TypeSelectorButton(
                        type: type,
                        isSelected: selectedType == type,
                        action: { selectedType = type }
                    )
                }
            }
        }
    }
}

struct TypeSelectorButton: View {
    let type: ConfigItemType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 12))
                
                Text(type.rawValue)
                    .font(.system(size: 11, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundColor(isSelected ? type.color.swiftUIColor : .secondary)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? type.color.swiftUIColor.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? type.color.swiftUIColor : Color.secondary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct NameSection: View {
    @Binding var name: String
    let selectedType: ConfigItemType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(nameLabel)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            
            TextField(namePlaceholder, text: $name)
                .textFieldStyle(.plain)
                .font(.system(size: 13, design: .monospaced))
                .padding(10)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    private var nameLabel: String {
        switch selectedType {
        case .environmentVariable, .export:
            return "Variable Name"
        case .alias:
            return "Alias Name"
        case .function:
            return "Function Name"
        case .source:
            return "Name (optional)"
        case .other:
            return "Name"
        }
    }
    
    private var namePlaceholder: String {
        switch selectedType {
        case .environmentVariable, .export:
            return "e.g., MY_VAR"
        case .alias:
            return "e.g., ll"
        case .function:
            return "e.g., my_function"
        case .source:
            return "Optional identifier"
        case .other:
            return "Name"
        }
    }
}

struct ValueSection: View {
    @Binding var value: String
    let selectedType: ConfigItemType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(valueLabel)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            
            if selectedType == .alias {
                TextEditor(text: $value)
                    .font(.system(size: 13, design: .monospaced))
                    .frame(height: 60)
                    .padding(4)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            } else {
                TextField(valuePlaceholder, text: $value)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, design: .monospaced))
                    .padding(10)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            }
            
            Text(valueHint)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }
    
    private var valueLabel: String {
        switch selectedType {
        case .environmentVariable:
            return "Value"
        case .alias:
            return "Command"
        case .source:
            return "File Path"
        case .function:
            return "Function Body"
        case .other:
            return "Value"
        case .export:
            return ""
        }
    }
    
    private var valuePlaceholder: String {
        switch selectedType {
        case .environmentVariable:
            return "e.g., /usr/local/bin"
        case .alias:
            return "e.g., ls -la"
        case .source:
            return "e.g., ~/.bashrc or /path/to/file"
        case .function:
            return "Function body"
        case .other:
            return "Value"
        case .export:
            return ""
        }
    }
    
    private var valueHint: String {
        switch selectedType {
        case .environmentVariable:
            return "Use $VAR or ${VAR} to reference other variables"
        case .alias:
            return "The command that will be executed when the alias is used"
        case .source:
            return "Path to the file to be sourced. Use ~ for home directory"
        default:
            return ""
        }
    }
}

struct ExportToggle: View {
    @Binding var isExport: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            Toggle("Export to environment", isOn: $isExport)
                .font(.system(size: 12))
            
            Spacer()
            
            Text(isExport ? "Will be available to child processes" : "Shell variable only")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
}

struct CommentSection: View {
    @Binding var comment: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Comment (optional)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            
            TextField("Add a descriptive comment...", text: $comment)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .padding(10)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

struct ConfigPathInfo: View {
    let path: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Will be added to:")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Text(path)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
    }
}
