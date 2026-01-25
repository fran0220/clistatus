import SwiftUI

struct NpmPackageRowView: View {
    @Environment(AppState.self) private var appState
    @Bindable var package: NpmPackageStatus
    
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(package.name)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                
                versionText
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            actionButtons
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(backgroundColor)
        )
        .padding(.horizontal, 8)
    }
    
    @ViewBuilder
    private var versionText: some View {
        switch package.state {
        case .idle, .checking:
            Text("Checking...")
        case .upToDate(let current):
            Text("v\(current.display)")
                .foregroundStyle(.green)
        case .updateAvailable(let current, let latest):
            HStack(spacing: 2) {
                Text("v\(current.display)")
                Image(systemName: "arrow.right")
                    .font(.caption2)
                Text("v\(latest.display)")
                    .foregroundStyle(.green)
            }
        case .updating:
            Text("Updating...")
        case .uninstalling:
            Text("Uninstalling...")
        case .error(let message):
            Text(message)
                .foregroundStyle(.red)
                .lineLimit(1)
        }
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        switch package.state {
        case .checking, .updating, .uninstalling:
            ProgressView()
                .controlSize(.mini)
        case .updateAvailable:
            HStack(spacing: 4) {
                Button("Up") {
                    Task { await appState.upgradeNpmPackage(name: package.name) }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
                
                Button {
                    Task { await appState.uninstallNpmPackage(name: package.name) }
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
        case .upToDate:
            Button {
                Task { await appState.uninstallNpmPackage(name: package.name) }
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
        case .error:
            Button {
                Task { await appState.checkNpmPackages() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
        case .idle:
            EmptyView()
        }
    }
    
    private var backgroundColor: Color {
        switch package.state {
        case .updateAvailable:
            return Color.orange.opacity(0.1)
        case .error:
            return Color.red.opacity(0.1)
        default:
            return Color.clear
        }
    }
}
