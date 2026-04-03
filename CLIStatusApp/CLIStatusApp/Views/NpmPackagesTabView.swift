import SwiftUI

struct NpmPackagesTabView: View {
    @Environment(AppState.self) private var appState
    @State private var installSpec = ""
    @State private var isInstalling = false

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                TextField("包名称（如 lodash@latest）", text: $installSpec)
                    .textFieldStyle(.roundedBorder)

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
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }
                }
                .disabled(installSpec.isEmpty || isInstalling)
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)

            if appState.isCheckingNpm && appState.npmPackages.isEmpty {
                Spacer()
                ProgressView("正在加载...")
                Spacer()
            } else if appState.npmPackages.isEmpty {
                ContentUnavailableView("暂无全局 NPM 包", systemImage: "shippingbox", description: Text("在上方输入包名进行安装"))
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(appState.npmPackages) { package in
                            NpmPackageRowView(package: package)
                        }
                    }
                    .padding(8)
                }
            }
        }
    }
}
