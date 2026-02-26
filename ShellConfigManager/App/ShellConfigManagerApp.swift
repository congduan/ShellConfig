import SwiftUI

@main
struct ShellConfigManagerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) { }
            
            CommandMenu("Config") {
                Button("Refresh") {
                    ShellConfigManager.shared.refresh()
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }
}
