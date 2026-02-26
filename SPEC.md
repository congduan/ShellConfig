# ShellConfigManager - Specification Document

## 1. Project Overview

**Project Name:** ShellConfigManager  
**Bundle Identifier:** com.shellconfig.manager  
**Core Functionality:** A macOS desktop application for managing shell configuration files (Bash, Zsh, Fish) with the ability to view and analyze environment variables defined in these configuration files.  
**Target Users:** Developers, system administrators, and power users who work with multiple shell configurations.  
**macOS Version Support:** macOS 12.0 (Monterey) and later

---

## 2. UI/UX Specification

### Window Structure

- **Main Window:** Single-window application using NSSplitViewController
  - Left sidebar: Shell and configuration file browser
  - Right content area: Environment variable detail view
- **Window Size:** Default 900x600, minimum 700x500
- **Navigation:** Native NSSplitViewController with sidebar

### Visual Design

**Color Palette:**
- Primary Background: System background (NSColor.windowBackgroundColor)
- Sidebar Background: NSColor.controlBackgroundColor
- Accent Color: System accent color (NSColor.controlAccentColor)
- Text Primary: NSColor.labelColor
- Text Secondary: NSColor.secondaryLabelColor
- Success/Path: #34C759 (System Green)
- Warning: #FF9500 (System Orange)
- Error: #FF3B30 (System Red)
- Variable Name: #007AFF (System Blue)
- Variable Value: #5856D6 (System Purple)

**Typography:**
- Window Title: System Font, 13pt, Semibold
- Sidebar Items: System Font, 13pt, Regular
- Section Headers: System Font, 12pt, Bold
- Body Text: System Font, 13pt, Regular
- Monospace (Values): SF Mono / Menlo, 12pt, Regular

**Spacing System (8pt grid):**
- Sidebar item padding: 8pt horizontal, 6pt vertical
- Content margins: 16pt
- Section spacing: 24pt
- Item spacing in lists: 4pt

**macOS-Specific Elements:**
- Toolbar with refresh button and search field
- Standard menu bar with File, Edit, View, Window, Help menus
- Sidebar with source list style

### Views & Components

**1. Sidebar View (ShellListView)**
- Grouped by shell type (Bash, Zsh, Fish)
- Each group shows configuration files:
  - Bash: ~/.bashrc, ~/.bash_profile, ~/.bash_login
  - Zsh: ~/.zshrc, ~/.zprofile
  - Fish: ~/.config/fish/config.fish
- File icon with shell type indicator
- File path as subtitle (truncated)
- States: default, selected (highlighted), hover

**2. Detail View (EnvVariableListView)**
- Header with file path and last modified date
- Search/filter field
- Table/List of environment variables:
  - Variable name (bold, blue)
  - Variable value (monospace, purple)
  - Source line number
  - Comment (if present, gray italic)
- Empty state when no file selected
- Loading state while parsing

**3. Toolbar**
- Refresh button (SF Symbol: arrow.clockwise)
- Search field for filtering variables
- Status text showing file count

---

## 3. Functionality Specification

### Core Features

**P0 - Must Have:**
1. **Shell Detection**: Auto-detect installed shells (Bash, Zsh, Fish)
2. **Config File Discovery**: Find all standard config files for each shell
3. **File Parsing**: Parse shell config files to extract:
   - Environment variables (export VAR=value)
   - Variable assignments (VAR=value)
   - Comments related to variables
   - Source line numbers
4. **Variable Display**: Show all extracted variables in a clean list
5. **Search/Filter**: Filter variables by name or value
6. **Refresh**: Manual refresh to reload config files

**P1 - Should Have:**
1. **Variable Details**: Show full value, truncated if too long
2. **Copy to Clipboard**: Copy variable name or value
3. **Path Highlighting**: Highlight path-like values in green
4. **File Metadata**: Show last modified date

**P2 - Nice to Have:**
1. **Export**: Export variables to different formats
2. **Compare**: Compare variables between different configs

### User Interactions and Flows

1. **Launch Flow:**
   - App launches → Auto-scan for shell configs → Display in sidebar
   - Select first available config → Show variables in detail

2. **Browse Flow:**
   - User clicks shell type in sidebar → Expands to show config files
   - User clicks config file → Parses and displays variables

3. **Search Flow:**
   - User types in search field → Filters variables in real-time
   - Clear search → Shows all variables

4. **Refresh Flow:**
   - User clicks refresh → Re-scans and re-parses all config files
   - Updates sidebar and detail view

### Data Handling

- **Local Storage:** UserDefaults for app preferences (window position, last selected file)
- **File Access:** Direct file system read (no write operations)
- **Caching:** In-memory cache of parsed variables (refreshable)

### Architecture Pattern

**MVVM (Model-View-ViewModel)**
- Models: Shell, ConfigFile, EnvVariable
- ViewModels: ShellListViewModel, EnvVariableViewModel
- Views: SwiftUI views with AppKit integration where needed

### Edge Cases and Error Handling

1. **File not found**: Show empty state with message
2. **Permission denied**: Show error alert with instructions
3. **Invalid syntax**: Skip invalid lines, show warning
4. **Empty file**: Show "No variables found" message
5. **Large files**: Show loading indicator, parse in background

---

## 4. Technical Specification

### Dependencies

**Swift Package Manager:**
- None required (using native frameworks)

### UI Framework

- **SwiftUI** for main UI (macOS 12.0+)
- **AppKit** integration for window management and menus

### Required Frameworks

- Foundation
- SwiftUI
- AppKit
- UniformTypeIdentifiers

### Asset Requirements

**SF Symbols:**
- sidebar.left (sidebar toggle)
- arrow.clockwise (refresh)
- magnifyingglass (search)
- doc.text (config file)
- terminal (shell icon)
- checkmark.circle.fill (valid)
- exclamationmark.triangle.fill (warning)

**App Icon:**
- Terminal-style icon with gear/settings overlay
- Standard macOS icon sizes (16, 32, 64, 128, 256, 512, 1024)

### File Structure

```
ShellConfigManager/
├── App/
│   └── ShellConfigManagerApp.swift
├── Models/
│   ├── Shell.swift
│   ├── ConfigFile.swift
│   └── EnvVariable.swift
├── ViewModels/
│   ├── ShellListViewModel.swift
│   └── EnvVariableViewModel.swift
├── Views/
│   ├── ContentView.swift
│   ├── SidebarView.swift
│   ├── EnvVariableListView.swift
│   ├── EnvVariableRowView.swift
│   └── EmptyStateView.swift
├── Services/
│   ├── ShellConfigManager.swift
│   └── ConfigFileParser.swift
├── Resources/
│   └── Assets.xcassets/
└── Supporting/
    └── Info.plist
```

---

## 5. Shell Config File Locations

### Bash
- ~/.bashrc
- ~/.bash_profile
- ~/.bash_login
- /etc/profile
- /etc/bashrc

### Zsh
- ~/.zshrc
- ~/.zprofile
- ~/.zshenv
- /etc/zshrc
- /etc/zprofile

### Fish
- ~/.config/fish/config.fish
- ~/.config/fish/fish_variables

---

## 6. Parsing Patterns

### Environment Variable Patterns
```
export VAR=value
export VAR="value"
export VAR='value'
VAR=value
VAR="value"
VAR='value'
```

### Comments
```
# This is a comment
# export VAR=value # inline comment
```

### Special Cases
- PATH-like values: Split and display each path on new line
- Multi-line values: Show with line continuation indicator
- Conditional assignments: Parse but mark as conditional
