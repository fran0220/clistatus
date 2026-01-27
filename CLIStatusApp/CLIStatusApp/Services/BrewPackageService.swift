import Foundation

actor BrewPackageService {
    private let shell = ShellExecutor()

    struct OutdatedReport: Codable {
        let formulae: [OutdatedFormula]
        let casks: [OutdatedCask]

        struct OutdatedFormula: Codable {
            let name: String
            let installed_versions: [String]?
            let current_version: String?
        }

        struct OutdatedCask: Codable {
            let name: String
            let installed_versions: [String]?
            let current_version: String?
        }
    }

    struct InstalledPackage {
        let name: String
        let version: String?
        let kind: BrewPackageStatus.Kind
    }

    func listInstalled() async throws -> [InstalledPackage] {
        async let formulaOutput = shell.run(["brew", "list", "--formula", "--versions"], timeout: .seconds(30))
        async let caskOutput = shell.run(["brew", "list", "--cask", "--versions"], timeout: .seconds(30))

        let formulaOutputString = try await formulaOutput
        let caskOutputString = try await caskOutput

        let formulaLines = formulaOutputString.split(separator: "\n")
        let caskLines = caskOutputString.split(separator: "\n")

        let formulaPackages: [InstalledPackage] = formulaLines.compactMap { line in
            let parts = line.split(separator: " ").map(String.init)
            guard let name = parts.first else { return nil }
            let version = parts.count > 1 ? parts.last : nil
            return InstalledPackage(name: name, version: version, kind: .formula)
        }

        let caskPackages: [InstalledPackage] = caskLines.compactMap { line in
            let parts = line.split(separator: " ").map(String.init)
            guard let name = parts.first else { return nil }
            let version = parts.count > 1 ? parts.last : nil
            return InstalledPackage(name: name, version: version, kind: .cask)
        }

        let combined = formulaPackages + caskPackages
        return combined.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    func fetchOutdated() async -> (formulae: [String: String], casks: [String: String]) {
        do {
            let output = try await shell.run(["brew", "outdated", "--formula", "--cask", "--json=v2"], timeout: .seconds(30))
            guard let data = output.data(using: .utf8) else { return ([:], [:]) }
            let report = try JSONDecoder().decode(OutdatedReport.self, from: data)
            var formulaLatest: [String: String] = [:]
            var caskLatest: [String: String] = [:]
            for formula in report.formulae {
                if let latest = formula.current_version {
                    formulaLatest[formula.name] = latest
                }
            }
            for cask in report.casks {
                if let latest = cask.current_version {
                    caskLatest[cask.name] = latest
                }
            }
            return (formulaLatest, caskLatest)
        } catch {
            return ([:], [:])
        }
    }

    func install(spec: String, kind: BrewPackageStatus.Kind) async throws {
        switch kind {
        case .formula:
            _ = try await shell.run(["brew", "install", spec], timeout: .seconds(180))
        case .cask:
            _ = try await shell.run(["brew", "install", "--cask", spec], timeout: .seconds(180))
        }
    }

    func upgrade(name: String, kind: BrewPackageStatus.Kind) async throws {
        switch kind {
        case .formula:
            _ = try await shell.run(["brew", "upgrade", name], timeout: .seconds(180))
        case .cask:
            _ = try await shell.run(["brew", "upgrade", "--cask", name], timeout: .seconds(180))
        }
    }

    func uninstall(name: String, kind: BrewPackageStatus.Kind) async throws {
        switch kind {
        case .formula:
            _ = try await shell.run(["brew", "uninstall", name], timeout: .seconds(120))
        case .cask:
            _ = try await shell.run(["brew", "uninstall", "--cask", name], timeout: .seconds(120))
        }
    }
}
