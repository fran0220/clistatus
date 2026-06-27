import Darwin
import Foundation

actor ProcessMonitorService {
    enum MonitorError: Error, LocalizedError {
        case processNotFound(Int32)
        case terminationFailed(Int32)

        var errorDescription: String? {
            switch self {
            case .processNotFound(let pid):
                return "进程 \(pid) 不存在或已经退出"
            case .terminationFailed(let pid):
                return "无法停止进程 \(pid)，可能权限不足"
            }
        }
    }

    private let shell = ShellExecutor()

    func snapshot() async throws -> ProcessMonitorSnapshot {
        let processes = try await loadProcesses()
        let resources = try await loadResourceSnapshot(processes: processes)
        return ProcessMonitorSnapshot(resources: resources, processes: processes)
    }

    func terminate(pid: Int32) throws {
        if kill(pid, 0) != 0 {
            throw MonitorError.processNotFound(pid)
        }

        if kill(pid, SIGTERM) != 0 {
            throw MonitorError.terminationFailed(pid)
        }
    }

    private func loadProcesses() async throws -> [ProcessStatus] {
        let output = try await shell.run([
            "/bin/ps",
            "-axo",
            "pid=,ppid=,pcpu=,pmem=,rss=,ucomm=",
            "-r"
        ], timeout: .seconds(5))

        return output
            .split(separator: "\n")
            .compactMap { parseProcessLine(String($0)) }
    }

    private func parseProcessLine(_ line: String) -> ProcessStatus? {
        let parts = line.split(maxSplits: 5, whereSeparator: { $0.isWhitespace }).map(String.init)
        guard parts.count == 6,
              let pid = Int32(parts[0]),
              let parentPid = Int32(parts[1]),
              let cpuPercent = Double(parts[2]),
              let memoryPercent = Double(parts[3]),
              let rssKB = Double(parts[4]) else {
            return nil
        }

        let name = parts[5].trimmingCharacters(in: .whitespacesAndNewlines)

        return ProcessStatus(
            pid: pid,
            parentPid: parentPid,
            name: name.isEmpty ? "PID \(pid)" : name,
            command: name.isEmpty ? "PID \(pid)" : name,
            cpuPercent: cpuPercent,
            memoryPercent: memoryPercent,
            residentMemoryMB: rssKB / 1024.0
        )
    }

    private func loadResourceSnapshot(processes: [ProcessStatus]) async throws -> SystemResourceSnapshot {
        let memoryTotalGB = Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824.0
        let memoryUsedGB = try await loadUsedMemoryGB(totalGB: memoryTotalGB)
        let memoryUsagePercent = memoryTotalGB > 0 ? min(100, max(0, memoryUsedGB / memoryTotalGB * 100)) : 0

        let cpuTotal = processes.reduce(0) { $0 + $1.cpuPercent }
        let coreCount = max(1, ProcessInfo.processInfo.activeProcessorCount)
        let cpuUsagePercent = min(100, max(0, cpuTotal / Double(coreCount)))

        return SystemResourceSnapshot(
            cpuUsagePercent: cpuUsagePercent,
            memoryUsedGB: memoryUsedGB,
            memoryTotalGB: memoryTotalGB,
            memoryUsagePercent: memoryUsagePercent
        )
    }

    private func loadUsedMemoryGB(totalGB: Double) async throws -> Double {
        let output = try await shell.run(["/usr/bin/vm_stat"], timeout: .seconds(5))
        let lines = output.split(separator: "\n").map(String.init)
        let pageSize = parsePageSize(from: lines.first) ?? 16_384
        let values = Dictionary(uniqueKeysWithValues: lines.compactMap(parseVMStatLine))

        let freePages = values["Pages free"] ?? 0
        let speculativePages = values["Pages speculative"] ?? 0
        let freeBytes = Double(freePages + speculativePages) * Double(pageSize)
        let freeGB = freeBytes / 1_073_741_824.0

        return min(totalGB, max(0, totalGB - freeGB))
    }

    private func parsePageSize(from header: String?) -> Int? {
        guard let header else { return nil }
        let digits = header.filter(\.isNumber)
        return Int(digits)
    }

    private func parseVMStatLine(_ line: String) -> (String, Int)? {
        let parts = line.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return nil }

        let key = parts[0]
        let valueText = parts[1].filter { $0.isNumber }
        guard let value = Int(valueText) else { return nil }
        return (key, value)
    }
}
