import Foundation

class ConfigFileParser {
    
    func parseFile(at path: String) -> (variables: [EnvVariable], error: String?) {
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: path) else {
            return ([], "File not found")
        }
        
        guard fileManager.isReadableFile(atPath: path) else {
            return ([], "Permission denied")
        }
        
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            return ([], "Unable to read file")
        }
        
        let lines = content.components(separatedBy: .newlines)
        var items: [EnvVariable] = []
        var i = 0
        
        while i < lines.count {
            let line = lines[i]
            let lineNumber = i + 1
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                i += 1
                continue
            }
            
            if let item = parseLine(trimmedLine, lineNumber: lineNumber, fullLine: line, allLines: lines, currentIndex: &i) {
                items.append(item)
            }
            
            i += 1
        }
        
        return (items, nil)
    }
    
    private func parseLine(_ line: String, lineNumber: Int, fullLine: String, allLines: [String], currentIndex: inout Int) -> EnvVariable? {
        var workingLine = line
        
        if workingLine.hasPrefix("source ") || workingLine.hasPrefix(". ") {
            return parseSourceStatement(workingLine, lineNumber: lineNumber, fullLine: fullLine)
        }
        
        if workingLine.hasPrefix("alias ") {
            return parseAlias(workingLine, lineNumber: lineNumber, fullLine: fullLine)
        }
        
        if isFunctionStart(workingLine) {
            return parseFunction(workingLine, lineNumber: lineNumber, fullLine: fullLine, allLines: allLines, currentIndex: &currentIndex)
        }
        
        if workingLine.hasPrefix("export ") {
            workingLine = String(workingLine.dropFirst(7))
            
            if !workingLine.contains("=") {
                return ConfigItem(
                    type: .export,
                    name: workingLine.trimmingCharacters(in: .whitespaces),
                    value: "",
                    lineNumber: lineNumber,
                    rawLine: fullLine
                )
            }
            
            return parseVariable(workingLine, lineNumber: lineNumber, fullLine: fullLine, isExport: true)
        }
        
        if workingLine.contains("=") {
            return parseVariable(workingLine, lineNumber: lineNumber, fullLine: fullLine, isExport: false)
        }
        
        return nil
    }
    
    private func parseSourceStatement(_ line: String, lineNumber: Int, fullLine: String) -> EnvVariable? {
        var path: String
        
        if line.hasPrefix("source ") {
            path = String(line.dropFirst(7)).trimmingCharacters(in: .whitespaces)
        } else if line.hasPrefix(". ") {
            path = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
        } else {
            return nil
        }
        
        path = removeQuotes(from: path)
        let (cleanPath, comment) = extractComment(from: path)
        
        return ConfigItem(
            type: .source,
            name: cleanPath,
            value: cleanPath,
            lineNumber: lineNumber,
            comment: comment,
            rawLine: fullLine
        )
    }
    
    private func parseAlias(_ line: String, lineNumber: Int, fullLine: String) -> EnvVariable? {
        let aliasContent = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
        
        guard let equalsIndex = aliasContent.firstIndex(of: "=") else {
            return nil
        }
        
        let name = String(aliasContent[..<equalsIndex]).trimmingCharacters(in: .whitespaces)
        var value = String(aliasContent[aliasContent.index(after: equalsIndex)...]).trimmingCharacters(in: .whitespaces)
        
        value = removeQuotes(from: value)
        let (cleanValue, comment) = extractComment(from: value)
        
        return ConfigItem(
            type: .alias,
            name: name,
            value: cleanValue,
            lineNumber: lineNumber,
            comment: comment,
            rawLine: fullLine
        )
    }
    
    private func isFunctionStart(_ line: String) -> Bool {
        let patterns = [
            "function ",
            "() {",
            "()\\s*{"
        ]
        
        for pattern in patterns {
            if line.contains(pattern) {
                return true
            }
        }
        
        if line.hasSuffix("()") {
            return true
        }
        
        let functionRegex = "^[a-zA-Z_][a-zA-Z0-9_]*\\s*\\(\\)\\s*\\{"
        if let regex = try? NSRegularExpression(pattern: functionRegex),
           let _ = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
            return true
        }
        
        return false
    }
    
    private func parseFunction(_ line: String, lineNumber: Int, fullLine: String, allLines: [String], currentIndex: inout Int) -> EnvVariable? {
        var functionName = ""
        var functionBody = line
        var braceCount = line.filter { $0 == "{" }.count - line.filter { $0 == "}" }.count
        
        if line.hasPrefix("function ") {
            let namePart = String(line.dropFirst(9))
            if let parenIndex = namePart.firstIndex(of: "(") {
                functionName = String(namePart[..<parenIndex]).trimmingCharacters(in: .whitespaces)
            } else if let braceIndex = namePart.firstIndex(of: "{") {
                functionName = String(namePart[..<braceIndex]).trimmingCharacters(in: .whitespaces)
            } else {
                functionName = namePart.trimmingCharacters(in: .whitespaces)
            }
        } else {
            if let parenIndex = line.firstIndex(of: "(") {
                functionName = String(line[..<parenIndex]).trimmingCharacters(in: .whitespaces)
            }
        }
        
        var endLineIndex = currentIndex
        if braceCount > 0 {
            for j in (currentIndex + 1)..<min(allLines.count, currentIndex + 100) {
                let nextLine = allLines[j]
                braceCount += nextLine.filter { $0 == "{" }.count
                braceCount -= nextLine.filter { $0 == "}" }.count
                endLineIndex = j
                if braceCount == 0 {
                    break
                }
            }
        }
        
        currentIndex = endLineIndex
        
        return ConfigItem(
            type: .function,
            name: functionName,
            value: "Function definition (lines \(lineNumber)-\(endLineIndex + 1))",
            lineNumber: lineNumber,
            rawLine: fullLine
        )
    }
    
    private func parseVariable(_ line: String, lineNumber: Int, fullLine: String, isExport: Bool) -> EnvVariable? {
        var workingLine = line
        var isConditional = false
        
        if workingLine.hasPrefix("if ") || workingLine.hasPrefix("case ") ||
           workingLine.hasPrefix("while ") || workingLine.hasPrefix("for ") {
            isConditional = true
        }
        
        guard let equalsIndex = workingLine.firstIndex(of: "=") else {
            return nil
        }
        
        let namePart = workingLine[..<equalsIndex].trimmingCharacters(in: .whitespaces)
        let valuePart = workingLine[workingLine.index(after: equalsIndex)...].trimmingCharacters(in: .whitespaces)
        
        guard let firstChar = namePart.first,
              firstChar.isLetter || firstChar == "_" else {
            return nil
        }
        
        let cleanedValue = removeQuotes(from: String(valuePart))
        let (cleanValue, comment) = extractComment(from: cleanedValue)
        
        return ConfigItem(
            type: .environmentVariable,
            name: namePart,
            value: cleanValue,
            lineNumber: lineNumber,
            comment: comment,
            isExport: isExport,
            isConditional: isConditional,
            rawLine: fullLine
        )
    }
    
    private func removeQuotes(from value: String) -> String {
        var result = value
        
        if result.hasPrefix("\"") && result.hasSuffix("\"") && result.count >= 2 {
            result = String(result.dropFirst().dropLast())
            result = result.replacingOccurrences(of: "\\\"", with: "\"")
            result = result.replacingOccurrences(of: "\\$", with: "$")
            result = result.replacingOccurrences(of: "\\n", with: "\n")
            result = result.replacingOccurrences(of: "\\t", with: "\t")
        }
        
        if result.hasPrefix("'") && result.hasSuffix("'") && result.count >= 2 {
            result = String(result.dropFirst().dropLast())
        }
        
        return result
    }
    
    private func extractComment(from value: String) -> (value: String, comment: String?) {
        guard let hashIndex = value.firstIndex(of: "#") else {
            return (value, nil)
        }
        
        let beforeHash = String(value[..<hashIndex])
        let beforeQuotesCount = beforeHash.filter { $0 == "\"" || $0 == "'" }.count
        
        if beforeQuotesCount % 2 == 0 {
            let cleanValue = String(value[..<hashIndex]).trimmingCharacters(in: .whitespaces)
            let comment = String(value[value.index(after: hashIndex)...]).trimmingCharacters(in: .whitespaces)
            return (cleanValue, comment.isEmpty ? nil : comment)
        }
        
        return (value, nil)
    }
}
