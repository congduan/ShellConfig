# ShellConfigManager

A macOS desktop application for managing shell configuration files (Bash, Zsh, Fish) with the ability to view and analyze environment variables.

## Features

- **Shell Detection**: Auto-detect installed shells (Bash, Zsh, Fish)
- **Config File Discovery**: Find all standard config files for each shell
- **File Parsing**: Parse shell config files to extract environment variables
- **Variable Display**: Show all extracted variables in a clean list
- **Search/Filter**: Filter variables by name or value
- **Copy to Clipboard**: Copy variable name or value
- **Path Highlighting**: Highlight path-like values with color coding

## Requirements

- macOS 12.0 (Monterey) or later
- Xcode 15.0 or later
- XcodeGen (for project generation)

## Installation

### Install XcodeGen

```bash
brew install xcodegen
```

### Build & Run

```bash
# Generate project and build
./build.sh build

# Build and run the application
./build.sh run

# Clean build files
./build.sh clean
```

## Project Structure

```
ShellConfigManager/
├── App/
│   └── ShellConfigManagerApp.swift
├── Models/
│   ├── ConfigFile.swift
│   ├── EnvVariable.swift
│   └── Shell.swift
├── ViewModels/
│   ├── EnvVariableViewModel.swift
│   └── ShellListViewModel.swift
├── Views/
│   ├── ContentView.swift
│   ├── EmptyStateView.swift
│   ├── EnvVariableListView.swift
│   ├── EnvVariableRowView.swift
│   └── SidebarView.swift
├── Services/
│   ├── ConfigFileParser.swift
│   └── ShellConfigManager.swift
└── Resources/
    └── Assets.xcassets/
```

## Supported Config Files

### Bash
- `~/.bashrc`
- `~/.bash_profile`
- `~/.bash_login`
- `/etc/profile`
- `/etc/bashrc`

### Zsh
- `~/.zshrc`
- `~/.zprofile`
- `~/.zshenv`
- `/etc/zshrc`
- `/etc/zprofile`

### Fish
- `~/.config/fish/config.fish`
- `~/.config/fish/fish_variables`

## Technology Stack

- **Language**: Swift 5.9
- **UI Framework**: SwiftUI
- **Architecture**: MVVM
- **Project Generation**: XcodeGen

## License

MIT License
