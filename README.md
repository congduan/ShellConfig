# ShellConfigManager

A macOS desktop application for managing shell configuration files (Bash, Zsh, Fish) with the ability to view, edit, and manage environment variables, aliases, functions, and more.

## Features

### Configuration Management
- **Shell Detection**: Auto-detect installed shells (Bash, Zsh, Fish)
- **Config File Discovery**: Find all standard config files for each shell
- **Create Config Files**: Create new configuration files for any shell
- **Delete Config Files**: Remove unwanted configuration files

### Configuration Item Support
- **Environment Variables**: Parse and display `export VAR=value` statements
- **Aliases**: Parse and display `alias name='command'` statements
- **Functions**: Parse and display shell function definitions
- **Source Statements**: Parse and display `source` / `.` statements
- **Export Statements**: Parse standalone `export VAR` statements

### Editing Capabilities
- **Add Items**: Add new environment variables, aliases, or source statements
- **Edit Items**: Modify existing configuration items inline
- **Delete Items**: Remove configuration items with confirmation

### User Interface
- **Visual Card Layout**: Clean card-based display for each configuration item
- **Type Filtering**: Filter items by type (variables, aliases, functions, source)
- **Search**: Search items by name, value, or comment
- **Copy to Clipboard**: Copy variable name or value with one click
- **Path Highlighting**: Highlight path-like values with color coding
- **External Editors**: Open files in TextEdit or Terminal

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
│   ├── SidebarView.swift
│   ├── AddConfigItemSheet.swift
│   ├── EditConfigItemSheet.swift
│   └── AddConfigFileSheet.swift
├── Services/
│   ├── ConfigFileParser.swift
│   ├── ConfigFileEditor.swift
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

## Usage

### Adding a Configuration Item
1. Select a configuration file from the sidebar
2. Click the "Add" button in the header
3. Choose the type (Environment Variable, Alias, or Source)
4. Enter the name and value
5. Click "Add" to save

### Editing a Configuration Item
1. Hover over the item you want to edit
2. Click the "Edit" button (blue pencil icon)
3. Modify the values in the form
4. Click "Save Changes"

### Deleting a Configuration Item
1. Hover over the item you want to delete
2. Click the "Delete" button (red trash icon)
3. Confirm the deletion in the dialog

### Creating a New Config File
1. Click the "+" button next to a shell type in the sidebar
2. Enter the file name
3. Click "Create"

### Deleting a Config File
1. Hover over the config file in the sidebar
2. Click the trash icon
3. Confirm the deletion

## Technology Stack

- **Language**: Swift 5.9
- **UI Framework**: SwiftUI
- **Architecture**: MVVM
- **Project Generation**: XcodeGen
- **Minimum Deployment**: macOS 12.0

## License

MIT License
