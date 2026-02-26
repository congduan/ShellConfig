import SwiftUI

struct ContentView: View {
    @StateObject private var shellListVM = ShellListViewModel()
    @StateObject private var envVarVM = EnvVariableViewModel()
    
    var body: some View {
        NavigationView {
            SidebarView(viewModel: shellListVM)
                .frame(minWidth: 220)
            
            EnvVariableListView(
                viewModel: envVarVM,
                selectedConfigFile: shellListVM.selectedConfigFile
            )
        }
        .frame(minWidth: 700, minHeight: 500)
        .onChange(of: shellListVM.selectedConfigFile) { newValue in
            envVarVM.setConfigFile(newValue)
        }
    }
}
