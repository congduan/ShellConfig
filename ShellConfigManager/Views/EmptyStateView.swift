import SwiftUI

/// Empty state view when no config file is selected
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sidebar.left")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("Select a Configuration File")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("Choose a shell configuration file from the sidebar to view its environment variables.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            HStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "terminal")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    Text("Bash")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 8) {
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    Text("Zsh")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 8) {
                    Image(systemName: "fish")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                    Text("Fish")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
