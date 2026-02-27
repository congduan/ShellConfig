import Foundation

class ConfigFileEditor {
    
    static let shared = ConfigFileEditor()
    
    private let fileManager = FileManager.default
    
    private init() {}
    
    func addConfigItem(_ item: EnvVariable, to filePath: String) -> Result<Void, ConfigEditError> {
        do {
            var content = try readFile(at: filePath)
            
            let lineToAdd = generateLine(for: item)
            
            if !content.isEmpty && !content.hasSuffix("\n") {
                content += "\n"
            }
            
            content += lineToAdd + "\n"
            
            try writeFile(content: content, to: filePath)
            return .success(())
        } catch let error as ConfigEditError {
            return .failure(error)
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }
    
    func addConfigItem(_ item: EnvVariable, to filePath: String, afterLine lineNumber: Int) -> Result<Void, ConfigEditError> {
        do {
            let content = try readFile(at: filePath)
            var lines = content.components(separatedBy: "\n")
            
            let insertIndex = min(lineNumber, lines.count)
            let lineToAdd = generateLine(for: item)
            
            lines.insert(lineToAdd, at: insertIndex)
            
            let newContent = lines.joined(separator: "\n")
            try writeFile(content: newContent, to: filePath)
            
            return .success(())
        } catch let error as ConfigEditError {
            return .failure(error)
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }
    
    func deleteConfigItem(at lineNumber: Int, from filePath: String) -> Result<Void, ConfigEditError> {
        do {
            let content = try readFile(at: filePath)
            var lines = content.components(separatedBy: "\n")
            
            guard lineNumber > 0 && lineNumber <= lines.count else {
                return .failure(.invalidLineNumber)
            }
            
            lines.remove(at: lineNumber - 1)
            
            let newContent = lines.joined(separator: "\n")
            try writeFile(content: newContent, to: filePath)
            
            return .success(())
        } catch let error as ConfigEditError {
            return .failure(error)
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }
    
    func updateConfigItem(at lineNumber: Int, in filePath: String, with newItem: EnvVariable) -> Result<Void, ConfigEditError> {
        do {
            let content = try readFile(at: filePath)
            var lines = content.components(separatedBy: "\n")
            
            guard lineNumber > 0 && lineNumber <= lines.count else {
                return .failure(.invalidLineNumber)
            }
            
            lines[lineNumber - 1] = generateLine(for: newItem)
            
            let newContent = lines.joined(separator: "\n")
            try writeFile(content: newContent, to: filePath)
            
            return .success(())
        } catch let error as ConfigEditError {
            return .failure(error)
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }
    
    func deleteMultipleItems(at lineNumbers: [Int], from filePath: String) -> Result<Void, ConfigEditError> {
        do {
            let content = try readFile(at: filePath)
            var lines = content.components(separatedBy: "\n")
            
            let sortedLines = lineNumbers.sorted(by: >)
            
            for lineNum in sortedLines {
                guard lineNum > 0 && lineNum <= lines.count else {
                    continue
                }
                lines.remove(at: lineNum - 1)
            }
            
            let newContent = lines.joined(separator: "\n")
            try writeFile(content: newContent, to: filePath)
            
            return .success(())
        } catch let error as ConfigEditError {
            return .failure(error)
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }
    
    func createConfigFile(at path: String, shellType: ShellType) -> Result<Void, ConfigEditError> {
        let expandedPath = NSString(string: path).expandingTildeInPath
        
        let directory = (expandedPath as NSString).deletingLastPathComponent
        
        do {
            if !fileManager.fileExists(atPath: directory) {
                try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
            }
            
            let headerComment = "# Configuration file created by ShellConfigManager\n"
            try headerComment.write(toFile: expandedPath, atomically: true, encoding: .utf8)
            
            return .success(())
        } catch {
            return .failure(.writeError)
        }
    }
    
    func deleteConfigFile(at path: String) -> Result<Void, ConfigEditError> {
        let expandedPath = NSString(string: path).expandingTildeInPath
        
        guard fileManager.fileExists(atPath: expandedPath) else {
            return .failure(.fileNotFound)
        }
        
        do {
            try fileManager.removeItem(atPath: expandedPath)
            return .success(())
        } catch {
            return .failure(.writeError)
        }
    }
    
    func fileExists(at path: String) -> Bool {
        let expandedPath = NSString(string: path).expandingTildeInPath
        return fileManager.fileExists(atPath: expandedPath)
    }
    
    private func generateLine(for item: EnvVariable) -> String {
        var line = ""
        
        switch item.type {
        case .environmentVariable:
            if item.isExport {
                line = "export "
            }
            line += "\(item.name)=\"\(item.value)\""
            
        case .alias:
            line = "alias \(item.name)='\(item.value)'"
            
        case .function:
            line = "\(item.name)() {\n    # Function body\n}"
            
        case .source:
            line = "source \(item.value)"
            
        case .export:
            line = "export \(item.name)"
            
        case .other:
            line = item.rawLine
        }
        
        if let comment = item.comment, !comment.isEmpty {
            line += "  # \(comment)"
        }
        
        return line
    }
    
    private func readFile(at path: String) throws -> String {
        let expandedPath = NSString(string: path).expandingTildeInPath
        
        guard fileManager.fileExists(atPath: expandedPath) else {
            throw ConfigEditError.fileNotFound
        }
        
        guard fileManager.isReadableFile(atPath: expandedPath) else {
            throw ConfigEditError.permissionDenied
        }
        
        guard let content = try? String(contentsOfFile: expandedPath, encoding: .utf8) else {
            throw ConfigEditError.readError
        }
        
        return content
    }
    
    private func writeFile(content: String, to path: String) throws {
        let expandedPath = NSString(string: path).expandingTildeInPath
        
        guard fileManager.isWritableFile(atPath: expandedPath) else {
            throw ConfigEditError.permissionDenied
        }
        
        do {
            try content.write(toFile: expandedPath, atomically: true, encoding: .utf8)
        } catch {
            throw ConfigEditError.writeError
        }
    }
    
    func createBackup(of filePath: String) -> Result<URL, ConfigEditError> {
        let expandedPath = NSString(string: filePath).expandingTildeInPath
        
        guard fileManager.fileExists(atPath: expandedPath) else {
            return .failure(.fileNotFound)
        }
        
        let sourceURL = URL(fileURLWithPath: expandedPath)
        let backupURL = sourceURL.appendingPathExtension("backup.\(Date().timeIntervalSince1970)")
        
        do {
            try fileManager.copyItem(at: sourceURL, to: backupURL)
            return .success(backupURL)
        } catch {
            return .failure(.backupFailed)
        }
    }
}

enum ConfigEditError: LocalizedError {
    case fileNotFound
    case permissionDenied
    case readError
    case writeError
    case invalidLineNumber
    case backupFailed
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Configuration file not found"
        case .permissionDenied:
            return "Permission denied. Please check file permissions."
        case .readError:
            return "Failed to read configuration file"
        case .writeError:
            return "Failed to write to configuration file"
        case .invalidLineNumber:
            return "Invalid line number"
        case .backupFailed:
            return "Failed to create backup"
        case .unknown(let message):
            return message
        }
    }
}
