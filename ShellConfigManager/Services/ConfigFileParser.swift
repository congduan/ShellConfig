import Foundation

/// Service for parsing shell configuration files
class ConfigFileParser {
    
    /// Parse a shell config file and extract environment variables
    func parseFile(at path: String) -> (variables: [EnvVariable], error: String?) {
        let fileManager = FileManager.default
        
        // Check if file exists
        guard fileManager.fileExists(atPath: path) else {
            return ([], "File not found")
        }
        
        // Check if readable
        guard fileManager.isReadableFile(atPath: path) else {
            return ([], "Permission denied")
        }
        
        // Read file content
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            return ([], "Unable to read file")
        }
        
        // Parse lines
        let lines = content.components(separatedBy: .newlines)
        var variables: [EnvVariable] = []
        
        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Skip empty lines and comments
            if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                continue
            }
            
            // Try to parse export statements
            if let variable = parseLine(trimmedLine, lineNumber: lineNumber, fullLine: line) {
                variables.append(variable)
            }
        }
        
        return (variables, nil)
    }
    
    /// Parse a single line to extract environment variable
    private func parseLine(_ line: String, lineNumber: Int, fullLine: String) -> EnvVariable? {
        var workingLine = line
        var isExport = false
        var isConditional = false
        
        // Check for export keyword
        if workingLine.hasPrefix("export ") {
            isExport = true
            workingLine = String(workingLine.dropFirst(7))
        }
        
        // Check for conditional (if, case, etc.)
        if workingLine.hasPrefix("if ") || workingLine.hasPrefix("case ") || 
           workingLine.hasPrefix("while ") || workingLine.hasPrefix("for ") {
            isConditional = true
        }
        
        // Find the first equals sign
        guard let equalsIndex = workingLine.firstIndex(of: "=") else {
            return nil
        }
        
        // Extract variable name and value
        let namePart = workingLine[..<equalsIndex].trimmingCharacters(in: .whitespaces)
        let valuePart = workingLine[workingLine.index(after: equalsIndex)...].trimmingCharacters(in: .whitespaces)
        
        // Validate variable name (must start with letter or underscore)
        guard let firstChar = namePart.first,
              firstChar.isLetter || firstChar == "_" else {
            return nil
        }
        
        // Remove quotes from value
        let cleanedValue = removeQuotes(from: valuePart)
        
        // Extract inline comment if present
        let (cleanValue, comment) = extractComment(from: cleanedValue)
        
        return EnvVariable(
            name: namePart,
            value: cleanValue,
            lineNumber: lineNumber,
            comment: comment,
            isExport: isExport,
            isConditional: isConditional,
            rawLine: fullLine
        )
    }
    
    /// Remove surrounding quotes from a string
    private func removeQuotes(from value: String) -> String {
        var result = value
        
        // Handle double-quoted strings
        if result.hasPrefix("\"") && result.hasSuffix("\"") && result.count >= 2 {
            result = String(result.dropFirst().dropLast())
            // Unescape common escape sequences
            result = result.replacingOccurrences(of: "\\\"", with: "\"")
            result = result.replacingOccurrences(of: "\\$", with: "$")
            result = result.replacingOccurrences(of: "\\n", with: "\n")
            result = result.replacingOccurrences(of: "\\t", with: "\t")
        }
        
        // Handle single-quoted strings
        if result.hasPrefix("'") && result.hasSuffix("'") && result.count >= 2 {
            result = String(result.dropFirst().dropLast())
        }
        
        return result
    }
    
    /// Extract inline comment from value
    private func extractComment(from value: String) -> (value: String, comment: String?) {
        // Find # that is not inside quotes
        guard let hashIndex = value.firstIndex(of: "#") else {
            return (value, nil)
        }
        
        // Check if # is inside quotes
        let beforeHash = String(value[..<hashIndex])
        let beforeQuotesCount = beforeHash.filter { $0 == "\"" || $0 == "'" }.count
        
        if beforeQuotesCount % 2 == 0 {
            // # is not inside quotes
            let cleanValue = String(value[..<hashIndex]).trimmingCharacters(in: .whitespaces)
            let comment = String(value[value.index(after: hashIndex)...]).trimmingCharacters(in: .whitespaces)
            return (cleanValue, comment.isEmpty ? nil : comment)
        }
        
        return (value, nil)
    }
}
