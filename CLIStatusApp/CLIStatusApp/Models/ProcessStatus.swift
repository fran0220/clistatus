import Foundation

struct ProcessStatus: Identifiable, Equatable, Sendable {
    let pid: Int32
    let parentPid: Int32
    let name: String
    let command: String
    let cpuPercent: Double
    let memoryPercent: Double
    let residentMemoryMB: Double
    let bundleIdentifier: String?
    let displayName: String
    let groupingKey: String
    let bundleURL: URL?

    var id: Int32 { pid }

    var canTerminate: Bool {
        pid > 1 && pid != ProcessInfo.processInfo.processIdentifier
    }
}

struct ProcessGroup: Identifiable, Equatable, Sendable {
    let id: String
    let displayName: String
    let bundleIdentifier: String?
    let bundleURL: URL?
    let members: [ProcessStatus]
    let totalCPU: Double
    let totalMemoryMB: Double
    /// Share of system physical memory (0...1).
    let memoryShareOfSystem: Double

    var memberCount: Int { members.count }

    var canTerminatePrimary: Bool {
        members.count == 1 && members[0].canTerminate
    }

    var primaryProcess: ProcessStatus? { members.first }
}

struct SystemResourceSnapshot: Equatable, Sendable {
    let cpuUsagePercent: Double
    let memoryUsedGB: Double
    let memoryTotalGB: Double
    let memoryUsagePercent: Double
}

struct ProcessMonitorSnapshot: Equatable, Sendable {
    let resources: SystemResourceSnapshot
    let processes: [ProcessStatus]
    let groups: [ProcessGroup]
}

enum ProcessSortMode: Int, CaseIterable, Identifiable, Sendable {
    case memory
    case cpu

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .cpu: return "CPU"
        case .memory: return "内存"
        }
    }
}

enum ProcessGrouping {
    static func normalizeName(_ name: String) -> String {
        name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ".app", with: "", options: .caseInsensitive)
            .lowercased()
    }

    /// Collapse helper / XPC style bundle IDs onto the owning app.
    static func normalizeBundleIdentifier(_ bundleIdentifier: String) -> String {
        var value = bundleIdentifier
        if let regex = try? NSRegularExpression(pattern: #"\.helper(\.|$).*"#) {
            let range = NSRange(value.startIndex..<value.endIndex, in: value)
            value = regex.stringByReplacingMatches(in: value, range: range, withTemplate: "")
        }
        if let regex = try? NSRegularExpression(pattern: #"\.(renderer|gpu|plugin|alerter)$"#, options: .caseInsensitive) {
            let range = NSRange(value.startIndex..<value.endIndex, in: value)
            value = regex.stringByReplacingMatches(in: value, range: range, withTemplate: "")
        }
        return value
    }

    static func appBundlePath(from bundleURL: URL?) -> String? {
        guard let path = bundleURL?.path, !path.isEmpty else { return nil }
        let lowered = path.lowercased()
        guard let range = lowered.range(of: ".app") else { return nil }
        return String(lowered[..<range.upperBound])
    }

    static func groupingKey(
        bundleIdentifier: String?,
        name: String,
        bundleURL: URL? = nil
    ) -> String {
        if let appPath = appBundlePath(from: bundleURL) {
            return "app:\(appPath)"
        }
        if let bundleIdentifier, !bundleIdentifier.isEmpty {
            return "bundle:\(normalizeBundleIdentifier(bundleIdentifier))"
        }
        return "name:\(normalizeName(name))"
    }

    static func groupProcesses(
        _ processes: [ProcessStatus],
        totalMemoryGB: Double
    ) -> [ProcessGroup] {
        let totalMemoryMB = max(totalMemoryGB * 1024, 0.0001)
        let grouped = Dictionary(grouping: processes, by: \.groupingKey)

        return grouped.map { key, members in
            let sortedMembers = members.sorted { lhs, rhs in
                if lhs.residentMemoryMB != rhs.residentMemoryMB {
                    return lhs.residentMemoryMB > rhs.residentMemoryMB
                }
                return lhs.cpuPercent > rhs.cpuPercent
            }

            let representative = preferredRepresentative(in: sortedMembers)
            let totalCPU = sortedMembers.reduce(0) { $0 + $1.cpuPercent }
            let totalMemoryMBValue = sortedMembers.reduce(0) { $0 + $1.residentMemoryMB }

            return ProcessGroup(
                id: key,
                displayName: representative.displayName,
                bundleIdentifier: representative.bundleIdentifier,
                bundleURL: representative.bundleURL,
                members: sortedMembers,
                totalCPU: totalCPU,
                totalMemoryMB: totalMemoryMBValue,
                memoryShareOfSystem: min(1, max(0, totalMemoryMBValue / totalMemoryMB))
            )
        }
    }

    /// Prefer a non-Helper localized name for the group title.
    private static func preferredRepresentative(in members: [ProcessStatus]) -> ProcessStatus {
        members.first { member in
            let name = member.displayName.lowercased()
            return !name.contains("helper") && !name.contains("renderer")
        } ?? members.first!
    }

    static func sortedGroups(
        _ groups: [ProcessGroup],
        by mode: ProcessSortMode
    ) -> [ProcessGroup] {
        switch mode {
        case .cpu:
            return groups.sorted {
                if $0.totalCPU != $1.totalCPU { return $0.totalCPU > $1.totalCPU }
                return $0.totalMemoryMB > $1.totalMemoryMB
            }
        case .memory:
            return groups.sorted {
                if $0.totalMemoryMB != $1.totalMemoryMB { return $0.totalMemoryMB > $1.totalMemoryMB }
                return $0.totalCPU > $1.totalCPU
            }
        }
    }
}
