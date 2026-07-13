import XCTest
@testable import CLIStatusApp

final class CLIStatusAppTests: XCTestCase {
    func testVersionParsing() {
        let version = VersionInfo(string: "1.2.3")
        XCTAssertNotNil(version)
        XCTAssertEqual(version?.display, "1.2.3")
    }

    func testParseProcessLineValid() {
        let line = "  123  1  12.5  1.2  204800  Google Chrome"
        let process = ProcessMonitorService.parseProcessLine(line)
        XCTAssertEqual(process?.pid, 123)
        XCTAssertEqual(process?.parentPid, 1)
        XCTAssertEqual(process?.cpuPercent, 12.5)
        XCTAssertEqual(process?.memoryPercent, 1.2)
        XCTAssertEqual(process?.residentMemoryMB, 200)
        XCTAssertEqual(process?.name, "Google Chrome")
        XCTAssertEqual(process?.groupingKey, "name:google chrome")
    }

    func testParseProcessLineWithIdentity() {
        let line = "456 1 1.0 0.5 102400 Helper"
        let identity = ProcessMonitorService.AppIdentity(
            bundleIdentifier: "com.google.Chrome",
            displayName: "Google Chrome",
            bundleURL: URL(fileURLWithPath: "/Applications/Google Chrome.app")
        )
        let process = ProcessMonitorService.parseProcessLine(line, identities: [456: identity])
        XCTAssertEqual(process?.bundleIdentifier, "com.google.Chrome")
        XCTAssertEqual(process?.displayName, "Google Chrome")
        XCTAssertEqual(process?.groupingKey, "app:/applications/google chrome.app")
    }

    func testParseProcessLineRejectsMalformed() {
        XCTAssertNil(ProcessMonitorService.parseProcessLine("not a process"))
        XCTAssertNil(ProcessMonitorService.parseProcessLine("1 2 3"))
    }

    func testGroupProcessesMergesSameBundle() {
        let a = makeProcess(pid: 1, name: "Chrome", cpu: 10, memoryMB: 100, bundle: "com.google.Chrome", display: "Google Chrome")
        let b = makeProcess(pid: 2, name: "Helper", cpu: 5, memoryMB: 50, bundle: "com.google.Chrome.helper", display: "Google Chrome Helper")
        let c = makeProcess(pid: 3, name: "node", cpu: 2, memoryMB: 80, bundle: nil, display: "node")

        let groups = ProcessGrouping.groupProcesses([a, b, c], totalMemoryGB: 16)
        XCTAssertEqual(groups.count, 2)

        let chrome = groups.first { $0.displayName == "Google Chrome" }
        XCTAssertEqual(chrome?.memberCount, 2)
        XCTAssertEqual(chrome?.totalCPU, 15)
        XCTAssertEqual(chrome?.totalMemoryMB, 150)
        XCTAssertEqual(chrome?.memoryShareOfSystem ?? 0, 150 / (16 * 1024), accuracy: 0.0001)
    }

    func testGroupProcessesMergesByAppBundlePath() {
        let url = URL(fileURLWithPath: "/Applications/Google Chrome.app")
        let a = ProcessStatus(
            pid: 1,
            parentPid: 1,
            name: "Chrome",
            command: "Chrome",
            cpuPercent: 1,
            memoryPercent: 1,
            residentMemoryMB: 100,
            bundleIdentifier: "com.google.Chrome",
            displayName: "Google Chrome",
            groupingKey: ProcessGrouping.groupingKey(
                bundleIdentifier: "com.google.Chrome",
                name: "Chrome",
                bundleURL: url
            ),
            bundleURL: url
        )
        let helperURL = URL(fileURLWithPath: "/Applications/Google Chrome.app/Contents/Frameworks/Google Chrome Framework.framework/Helpers/Chrome Helper.app")
        let b = ProcessStatus(
            pid: 2,
            parentPid: 1,
            name: "Helper",
            command: "Helper",
            cpuPercent: 2,
            memoryPercent: 1,
            residentMemoryMB: 50,
            bundleIdentifier: "com.google.Chrome.helper",
            displayName: "Google Chrome Helper",
            groupingKey: ProcessGrouping.groupingKey(
                bundleIdentifier: "com.google.Chrome.helper",
                name: "Helper",
                bundleURL: helperURL
            ),
            bundleURL: helperURL
        )

        let groups = ProcessGrouping.groupProcesses([a, b], totalMemoryGB: 16)
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].memberCount, 2)
        XCTAssertEqual(groups[0].displayName, "Google Chrome")
    }

    func testGroupProcessesMergesNormalizedNames() {
        let a = makeProcess(pid: 1, name: "Node", cpu: 1, memoryMB: 10, bundle: nil, display: "Node")
        let b = makeProcess(pid: 2, name: "node", cpu: 2, memoryMB: 20, bundle: nil, display: "node")
        let groups = ProcessGrouping.groupProcesses([a, b], totalMemoryGB: 8)
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].totalMemoryMB, 30)
    }

    func testSortedGroupsByMemoryRankStable() {
        let low = makeGroup(id: "a", cpu: 50, memoryMB: 100)
        let high = makeGroup(id: "b", cpu: 10, memoryMB: 400)
        let mid = makeGroup(id: "c", cpu: 20, memoryMB: 200)

        let sorted = ProcessGrouping.sortedGroups([low, high, mid], by: .memory)
        XCTAssertEqual(sorted.map(\.id), ["b", "c", "a"])
    }

    func testSortedGroupsByCPU() {
        let a = makeGroup(id: "a", cpu: 5, memoryMB: 500)
        let b = makeGroup(id: "b", cpu: 40, memoryMB: 10)
        let sorted = ProcessGrouping.sortedGroups([a, b], by: .cpu)
        XCTAssertEqual(sorted.map(\.id), ["b", "a"])
    }

    func testFileContextPathTextJoinsAbsolutePaths() {
        let a = URL(fileURLWithPath: "/tmp/one.txt")
        let b = URL(fileURLWithPath: "/Users/fan/two.txt")
        let text = FileContextService.pathText(for: [a, b])
        XCTAssertEqual(text, "/tmp/one.txt\n/Users/fan/two.txt")
    }

    func testFileContextCopyPathsWritesPasteboard() {
        let urls = [
            URL(fileURLWithPath: "/tmp/alpha"),
            URL(fileURLWithPath: "/tmp/beta")
        ]
        XCTAssertTrue(FileContextService.copyPaths(urls))
        let pasted = NSPasteboard.general.string(forType: .string)
        XCTAssertEqual(pasted, "/tmp/alpha\n/tmp/beta")
    }

    func testFileContextDeletePermanentlyWithoutConfirm() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("cliadmin-delete-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("victim.txt")
        try "x".write(to: file, atomically: true, encoding: .utf8)

        let failures = FileContextService.deletePermanently([file], confirm: false)
        XCTAssertTrue(failures.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
        try? FileManager.default.removeItem(at: dir)
    }

    func testFileContextCutSetsFinderCutMarker() {
        let url = URL(fileURLWithPath: "/tmp/cut-me.txt")
        XCTAssertTrue(FileContextService.cutFiles([url]))
        let marker = NSPasteboard.general.string(forType: FileContextService.finderCutPasteboardType)
        XCTAssertEqual(marker, "1")
    }

    private func makeProcess(
        pid: Int32,
        name: String,
        cpu: Double,
        memoryMB: Double,
        bundle: String?,
        display: String
    ) -> ProcessStatus {
        ProcessStatus(
            pid: pid,
            parentPid: 1,
            name: name,
            command: name,
            cpuPercent: cpu,
            memoryPercent: 1,
            residentMemoryMB: memoryMB,
            bundleIdentifier: bundle,
            displayName: display,
            groupingKey: ProcessGrouping.groupingKey(bundleIdentifier: bundle, name: name, bundleURL: nil),
            bundleURL: nil
        )
    }

    private func makeGroup(id: String, cpu: Double, memoryMB: Double) -> ProcessGroup {
        ProcessGroup(
            id: id,
            displayName: id,
            bundleIdentifier: nil,
            bundleURL: nil,
            members: [
                makeProcess(pid: 1, name: id, cpu: cpu, memoryMB: memoryMB, bundle: nil, display: id)
            ],
            totalCPU: cpu,
            totalMemoryMB: memoryMB,
            memoryShareOfSystem: 0
        )
    }
}
