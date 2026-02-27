import SwiftUI

struct EditConfigItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: EnvVariableViewModel
    let originalVariable: EnvVariable
    
    @State private var selectedType: ConfigItemType
    @State private var name: String
    @State private var value: String
    @State private var comment: String
    @State private var isExport: Bool
    
    init(viewModel: EnvVariableViewModel, variable: EnvVariable) {
        self.viewModel = viewModel
        self.originalVariable = variable
        
        _selectedType = State(initialValue: variable.type)
        _name = State(initialValue: variable.name)
        _value = State(initialValue: variable.value)
        _comment = State(initialValue: variable.comment ?? "")
        _isExport = State(initialValue: variable.isExport)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Edit Configuration")
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
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        
                        Text("Editing line \(originalVariable.lineNumber)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(8)
                    
                    TypeSelectorSection(selectedType: $selectedType)
                    
                    NameSection(name: $name, selectedType: selectedType)
                    
                    if selectedType != .export {
                        ValueSection(value: $value, selectedType: selectedType)
                    }
                    
                    if selectedType == .environmentVariable {
                        ExportToggle(isExport: $isExport)
                    }
                    
                    CommentSection(comment: $comment)
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
                
                Button("Save Changes") {
                    saveChanges()
                }
                .keyboardShortcut(.return)
                .disabled(!isValid)
            }
            .padding(20)
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(width: 500, height: 560)
    }
    
    private var isValid: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        
        if selectedType == .source {
            return !value.trimmingCharacters(in: .whitespaces).isEmpty
        }
        
        return true
    }
    
    private func saveChanges() {
        let updatedVariable = EnvVariable(
            type: selectedType,
            name: name.trimmingCharacters(in: .whitespaces),
            value: value.trimmingCharacters(in: .whitespaces),
            lineNumber: originalVariable.lineNumber,
            comment: comment.trimmingCharacters(in: .whitespaces).isEmpty ? nil : comment.trimmingCharacters(in: .whitespaces),
            isExport: isExport,
            rawLine: ""
        )
        
        viewModel.updateVariable(updatedVariable)
        dismiss()
    }
}
