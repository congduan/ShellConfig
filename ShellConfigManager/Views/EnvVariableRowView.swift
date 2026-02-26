import SwiftUI

/// Row view for a single environment variable
struct EnvVariableRowView: View {
    let variable: EnvVariable
    let onCopyName: () -> Void
    let onCopyValue: () -> Void
    
    @State private var isHovered = false
    @State private var showCopiedName = false
    @State private var showCopiedValue = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Variable name and actions
            HStack {
                // Export indicator
                if variable.isExport {
                    Text("export")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.green)
                        .cornerRadius(3)
                }
                
                // Variable name
                Text(variable.name)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(.blue)
                
                // Conditional indicator
                if variable.isConditional {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                        .help("Conditional assignment")
                }
                
                Spacer()
                
                // Line number
                Text("Line \(variable.lineNumber)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                
                // Copy buttons (shown on hover)
                if isHovered {
                    HStack(spacing: 8) {
                        CopyButton(
                            label: "Name",
                            action: {
                                onCopyName()
                                showCopiedName = true
                            },
                            showFeedback: $showCopiedName
                        )
                        
                        CopyButton(
                            label: "Value",
                            action: {
                                onCopyValue()
                                showCopiedValue = true
                            },
                            showFeedback: $showCopiedValue
                        )
                    }
                }
            }
            
            // Variable value
            VariableValueView(variable: variable)
            
            // Comment (if present)
            if let comment = variable.comment {
                HStack(spacing: 4) {
                    Image(systemName: "text.quote")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    
                    Text(comment)
                        .font(.system(size: 11))
                        .italic()
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isHovered ? Color(nsColor: .selectedContentBackgroundColor).opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

/// View for displaying variable value with special formatting
struct VariableValueView: View {
    let variable: EnvVariable
    
    var body: some View {
        if variable.isPathVariable, let components = variable.pathComponents {
            // Special display for PATH-like variables
            VStack(alignment: .leading, spacing: 2) {
                Text("=")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)

                ForEach(components, id: \.self) { path in
                    HStack(spacing: 4) {
                        Text(path)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(pathColor(for: path))
                            .lineLimit(1)
                        
                        Spacer()
                    }
                    .padding(.leading, 16)
                }
            }
        } else {
            // Regular value display
            HStack(alignment: .top, spacing: 4) {
                Text("=")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
                
                Text(variable.value.isEmpty ? "(empty)" : variable.value)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(variable.value.isEmpty ? .secondary : valueColor)
                    .lineLimit(3)
                    .textSelection(.enabled)
            }
        }
    }
    
    private var valueColor: Color {
        if variable.isPathValue {
            return .green
        }
        return Color(nsColor: NSColor(red: 0.345, green: 0.337, blue: 0.839, alpha: 1.0)) // System Purple
    }
    
    private func pathColor(for path: String) -> Color {
        // Check if path exists
        if path.hasPrefix("$") || path.hasPrefix("${") {
            return Color(nsColor: NSColor(red: 0.345, green: 0.337, blue: 0.839, alpha: 1.0)) // Purple for variables
        }
        
        let expandedPath = NSString(string: path).expandingTildeInPath
        if FileManager.default.fileExists(atPath: expandedPath) {
            return .green // Green for existing paths
        } else if path.hasPrefix("/") || path.hasPrefix("~") {
            return .orange // Orange for non-existing absolute paths
        }
        
        return Color(nsColor: NSColor(red: 0.345, green: 0.337, blue: 0.839, alpha: 1.0)) // Purple for relative paths
    }
}

/// Copy button with feedback
struct CopyButton: View {
    let label: String
    let action: () -> Void
    @Binding var showFeedback: Bool
    
    var body: some View {
        Button(action: {
            action()
            // Reset after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showFeedback = false
            }
        }) {
            HStack(spacing: 2) {
                Image(systemName: showFeedback ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 10))
                
                Text(showFeedback ? "Copied!" : label)
                    .font(.system(size: 10))
            }
            .foregroundColor(showFeedback ? .green : .secondary)
        }
        .buttonStyle(.plain)
        .onAppear {
            // Watch for feedback changes
        }
    }
}
