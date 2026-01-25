import Foundation

actor ShellExecutor {
    enum ShellError: Error, LocalizedError {
        case commandNotFound(String)
        case executionFailed(stderr: String, exitCode: Int32)
        case timeout

        var errorDescription: String? {
            switch self {
            case .commandNotFound(let cmd): return "Command not found: \(cmd)"
            case .executionFailed(let stderr, let code): return "Exit \(code): \(stderr)"
            case .timeout: return "Command timed out"
            }
        }
    }

    func run(_ arguments: [String], timeout: Duration = .seconds(30)) async throws -> String {
        guard !arguments.isEmpty else { throw ShellError.commandNotFound("empty") }

        let process = Process()
        let stdout = Pipe()
        let stderr = Pipe()

        let executablePath = try await findExecutable(arguments[0])
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = Array(arguments.dropFirst())
        process.standardOutput = stdout
        process.standardError = stderr

        var env = ProcessInfo.processInfo.environment
        let additionalPaths = [
            "/usr/local/bin",
            "/opt/homebrew/bin",
            NSHomeDirectory() + "/.local/bin",
            NSHomeDirectory() + "/.npm-global/bin",
            NSHomeDirectory() + "/.amp/bin"
        ]
        env["PATH"] = (additionalPaths + [env["PATH"] ?? ""]).joined(separator: ":")
        process.environment = env

        return try await withThrowingTaskGroup(of: String.self) { group in
            group.addTask {
                try await Task.sleep(for: timeout)
                process.terminate()
                throw ShellError.timeout
            }

            group.addTask {
                try process.run()
                process.waitUntilExit()

                let outputData = stdout.fileHandleForReading.readDataToEndOfFile()
                let errorData = stderr.fileHandleForReading.readDataToEndOfFile()
                let output = String(decoding: outputData, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
                let errorOutput = String(decoding: errorData, as: UTF8.self)

                if process.terminationStatus != 0 {
                    throw ShellError.executionFailed(stderr: errorOutput, exitCode: process.terminationStatus)
                }
                return output
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    private func findExecutable(_ name: String) async throws -> String {
        if name.hasPrefix("/") {
            return name
        }

        let searchPaths = [
            "/usr/local/bin",
            "/opt/homebrew/bin",
            NSHomeDirectory() + "/.local/bin",
            NSHomeDirectory() + "/.npm-global/bin",
            NSHomeDirectory() + "/.amp/bin",
            "/usr/bin"
        ]

        for path in searchPaths {
            let fullPath = "\(path)/\(name)"
            if FileManager.default.isExecutableFile(atPath: fullPath) {
                return fullPath
            }
        }

        throw ShellError.commandNotFound(name)
    }
}
