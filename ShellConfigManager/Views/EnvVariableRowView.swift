import SwiftUI

struct EnvVariableRowView: View {
    let variable: EnvVariable
    let onCopyName: () -> Void
    let onCopyValue: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    @State private var showCopiedName = false
    @State private var showCopiedValue = false
    
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(variable.type.color.swiftUIColor)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    TypeIconBadge(type: variable.type, isExport: variable.isExport)
                    
                    Text(variable.name)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                    
                    if variable.isConditional {
                        ConditionalBadge()
                    }
                    
                    Spacer()
                    
                    LineNumberBadge(lineNumber: variable.lineNumber)
                    
                    if isHovered {
                        ActionButtons(
                            onCopyName: {
                                onCopyName()
                                showCopiedName = true
                            },
                            onCopyValue: {
                                onCopyValue()
                                showCopiedValue = true
                            },
                            onDelete: onDelete,
                            showCopiedName: $showCopiedName,
                            showCopiedValue: $showCopiedValue
                        )
                    }
                }
                
                ConfigItemValueView(variable: variable)
                
                if let comment = variable.comment {
                    CommentView(comment: comment)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color(nsColor: .selectedContentBackgroundColor).opacity(0.15) : Color(nsColor: .controlBackgroundColor).opacity(0.3))
        )
        .cornerRadius(8)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct TypeIconBadge: View {
    let type: ConfigItemType
    let isExport: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(type.color.swiftUIColor.opacity(0.15))
                    .frame(width: 24, height: 24)
                
                Image(systemName: type.icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(type.color.swiftUIColor)
            }
            
            Text(badgeText)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(type.color.swiftUIColor)
        }
    }
    
    private var badgeText: String {
        switch type {
        case .environmentVariable: return isExport ? "export" : "var"
        case .function: return "function"
        case .alias: return "alias"
        case .source: return "source"
        case .export: return "export"
        case .other: return "other"
        }
    }
}

struct ConditionalBadge: View {
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 9))
            Text("conditional")
                .font(.system(size: 9, weight: .medium))
        }
        .foregroundColor(.orange)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(4)
    }
}

struct LineNumberBadge: View {
    let lineNumber: Int
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "text.line.first.and.arrowtriangle.forward")
                .font(.system(size: 9))
            Text("\(lineNumber)")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(4)
    }
}

struct ActionButtons: View {
    let onCopyName: () -> Void
    let onCopyValue: () -> Void
    let onDelete: () -> Void
    @Binding var showCopiedName: Bool
    @Binding var showCopiedValue: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            ActionButton(
                icon: showCopiedName ? "checkmark.circle.fill" : "doc.on.doc",
                label: showCopiedName ? "Copied" : "Name",
                color: showCopiedName ? .green : .secondary,
                action: onCopyName
            )
            
            ActionButton(
                icon: showCopiedValue ? "checkmark.circle.fill" : "doc.on.doc",
                label: showCopiedValue ? "Copied" : "Value",
                color: showCopiedValue ? .green : .secondary,
                action: onCopyValue
            )
            
            ActionButton(
                icon: "trash",
                label: "Delete",
                color: .red,
                action: onDelete
            )
        }
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                Text(label)
                    .font(.system(size: 9, weight: .medium))
            }
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
}

struct ConfigItemValueView: View {
    let variable: EnvVariable
    
    var body: some View {
        switch variable.type {
        case .environmentVariable:
            VariableValueView(variable: variable)
        case .function:
            FunctionValueView(variable: variable)
        case .alias:
            AliasValueView(variable: variable)
        case .source:
            SourceValueView(variable: variable)
        case .export:
            ExportValueView(variable: variable)
        case .other:
            OtherValueView(variable: variable)
        }
    }
}

struct VariableValueView: View {
    let variable: EnvVariable
    
    var body: some View {
        if variable.isPathVariable, let components = variable.pathComponents {
            PathComponentsView(components: components)
        } else {
            HStack(alignment: .top, spacing: 6) {
                Text("=")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 16)
                
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
        return Color(nsColor: NSColor(red: 0.345, green: 0.337, blue: 0.839, alpha: 1.0))
    }
}

struct PathComponentsView: View {
    let components: [String]
    let spacing: CGFloat = 4
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "folder.badge.gearshape")
                    .font(.system(size: 10))
                    .foregroundColor(.green)
                Text("PATH Components:")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: spacing) {
                    ForEach(components, id: \.self) { path in
                        PathChip(path: path, color: pathColor(for: path))
                    }
                }
            }
        }
        .padding(10)
        .background(Color.green.opacity(0.05))
        .cornerRadius(6)
    }
    
    private func pathColor(for path: String) -> Color {
        if path.hasPrefix("$") || path.hasPrefix("${") {
            return Color(nsColor: NSColor(red: 0.345, green: 0.337, blue: 0.839, alpha: 1.0))
        }
        
        let expandedPath = NSString(string: path).expandingTildeInPath
        if FileManager.default.fileExists(atPath: expandedPath) {
            return .green
        } else if path.hasPrefix("/") || path.hasPrefix("~") {
            return .orange
        }
        
        return Color(nsColor: NSColor(red: 0.345, green: 0.337, blue: 0.839, alpha: 1.0))
    }
}

struct PathChip: View {
    let path: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: pathIcon)
                .font(.system(size: 8))
            Text(path)
                .font(.system(size: 10, design: .monospaced))
                .lineLimit(1)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(4)
    }
    
    private var pathIcon: String {
        if path.hasPrefix("$") || path.hasPrefix("${") {
            return "dollarsign.circle"
        }
        let expandedPath = NSString(string: path).expandingTildeInPath
        if FileManager.default.fileExists(atPath: expandedPath) {
            return "checkmark.circle.fill"
        }
        return "exclamationmark.triangle"
    }
}

struct FunctionValueView: View {
    let variable: EnvVariable
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 28, height: 28)
                
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.purple)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Function Definition")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(variable.value)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.purple)
            }
            
            Spacer()
        }
        .padding(8)
        .background(Color.purple.opacity(0.05))
        .cornerRadius(6)
    }
}

struct AliasValueView: View {
    let variable: EnvVariable
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 28, height: 28)
                
                Image(systemName: "arrow.forward")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Maps to")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(variable.value.isEmpty ? "(empty)" : variable.value)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.orange)
                    .lineLimit(2)
                    .textSelection(.enabled)
            }
            
            Spacer()
        }
        .padding(8)
        .background(Color.orange.opacity(0.05))
        .cornerRadius(6)
    }
}

struct SourceValueView: View {
    let variable: EnvVariable
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.cyan.opacity(0.1))
                    .frame(width: 28, height: 28)
                
                Image(systemName: "arrow.down.doc")
                    .font(.system(size: 12))
                    .foregroundColor(.cyan)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Loads file")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: fileIcon)
                        .font(.system(size: 10))
                    
                    Text(variable.value)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(pathColor(for: variable.value))
                        .lineLimit(1)
                        .textSelection(.enabled)
                }
            }
            
            Spacer()
        }
        .padding(8)
        .background(Color.cyan.opacity(0.05))
        .cornerRadius(6)
    }
    
    private var fileIcon: String {
        let expandedPath = NSString(string: variable.value).expandingTildeInPath
        if FileManager.default.fileExists(atPath: expandedPath) {
            return "checkmark.circle.fill"
        }
        return "exclamationmark.triangle"
    }
    
    private func pathColor(for path: String) -> Color {
        let expandedPath = NSString(string: path).expandingTildeInPath
        if FileManager.default.fileExists(atPath: expandedPath) {
            return .green
        } else if path.hasPrefix("/") || path.hasPrefix("~") {
            return .orange
        }
        return .cyan
    }
}

struct ExportValueView: View {
    let variable: EnvVariable
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 28, height: 28)
                
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 12))
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Exports variable")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(variable.name)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.green)
            }
            
            Spacer()
        }
        .padding(8)
        .background(Color.green.opacity(0.05))
        .cornerRadius(6)
    }
}

struct OtherValueView: View {
    let variable: EnvVariable
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text("=")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 16)
            
            Text(variable.value.isEmpty ? "(empty)" : variable.value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
    }
}

struct CommentView: View {
    let comment: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "text.bubble")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            
            Text(comment)
                .font(.system(size: 11))
                .italic()
                .foregroundColor(.secondary)
        }
        .padding(.leading, 22)
    }
}
