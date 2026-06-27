import Foundation

struct ProcessStatus: Identifiable, Equatable {
    let pid: Int32
    let parentPid: Int32
    let name: String
    let command: String
    let cpuPercent: Double
    let memoryPercent: Double
    let residentMemoryMB: Double

    var id: Int32 { pid }

    var canTerminate: Bool {
        pid > 1 && pid != ProcessInfo.processInfo.processIdentifier
    }
}

struct SystemResourceSnapshot: Equatable {
    let cpuUsagePercent: Double
    let memoryUsedGB: Double
    let memoryTotalGB: Double
    let memoryUsagePercent: Double
}

struct ProcessMonitorSnapshot: Equatable {
    let resources: SystemResourceSnapshot
    let processes: [ProcessStatus]
}
