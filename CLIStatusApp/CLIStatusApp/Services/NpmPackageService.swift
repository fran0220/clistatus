import Foundation

actor NpmPackageService {
    private let shell = ShellExecutor()
    
    struct NpmListOutput: Codable {
        let dependencies: [String: PackageInfo]?
        
        struct PackageInfo: Codable {
            let version: String?
            let overridden: Bool?
        }
    }
    
    func listGlobals() async throws -> [(name: String, current: VersionInfo?)] {
        let output = try await shell.run(["npm", "ls", "-g", "--depth=0", "--json"], timeout: .seconds(30))
        
        guard let data = output.data(using: .utf8) else {
            return []
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(NpmListOutput.self, from: data)
        
        guard let deps = result.dependencies else {
            return []
        }
        
        return deps.map { (name, info) in
            let version = info.version.flatMap { VersionInfo(string: $0) }
            return (name: name, current: version)
        }.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
    
    func fetchLatestVersion(name: String) async -> VersionInfo? {
        do {
            let output = try await shell.run(["npm", "view", name, "version"], timeout: .seconds(15))
            return VersionInfo(string: output.trimmingCharacters(in: .whitespacesAndNewlines))
        } catch {
            return nil
        }
    }
    
    func install(spec: String) async throws {
        _ = try await shell.run(["npm", "install", "-g", spec], timeout: .seconds(120))
    }
    
    func upgrade(name: String) async throws {
        _ = try await shell.run(["npm", "install", "-g", "\(name)@latest"], timeout: .seconds(120))
    }
    
    func uninstall(name: String) async throws {
        _ = try await shell.run(["npm", "uninstall", "-g", name], timeout: .seconds(60))
    }
}
