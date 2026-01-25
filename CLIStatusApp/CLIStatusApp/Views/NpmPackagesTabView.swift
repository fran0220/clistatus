import SwiftUI

struct NpmPackagesTabView: View {
    @Environment(AppState.self) private var appState
    @State private var installSpec = ""
    @State private var isInstalling = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                TextField("Package name", text: $installSpec)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                
                Button {
                    guard !installSpec.isEmpty else { return }
                    isInstalling = true
                    Task {
                        await appState.installNpmPackage(spec: installSpec)
                        installSpec = ""
                        isInstalling = false
                    }
                } label: {
                    if isInstalling {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Text("Install")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(installSpec.isEmpty || isInstalling)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
            
            if appState.isCheckingNpm && appState.npmPackages.isEmpty {
                VStack {
                    ProgressView()
                    Text("Loading packages...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else if appState.npmPackages.isEmpty {
                Text("No global npm packages found")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(appState.npmPackages) { package in
                            NpmPackageRowView(package: package)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}
