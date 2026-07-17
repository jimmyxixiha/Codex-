import Foundation

struct UsageSample: Codable, Identifiable {
    var id: String { label }
    let label: String
    let value: String
    let detail: String?
}

struct UsageSnapshot: Codable {
    let plan: String
    let title: String
    let remainingPercent: Int
    let remainingLabel: String
    let usedLabel: String
    let resetLabel: String
    let status: String
    let updatedAt: String
    let samples: [UsageSample]

    static let sample = UsageSnapshot(
        plan: "Codex",
        title: "剩余用量",
        remainingPercent: 72,
        remainingLabel: "72%",
        usedLabel: "已用 28%",
        resetLabel: "明日 08:00 重置",
        status: "正常",
        updatedAt: "刚刚",
        samples: [
            UsageSample(label: "当前", value: "72%", detail: "可用"),
            UsageSample(label: "会话", value: "18", detail: "估计"),
            UsageSample(label: "本周", value: "5天", detail: "剩余"),
            UsageSample(label: "重置", value: "08:00", detail: "明日")
        ]
    )
}

enum UsagePaths {
    static var primaryFile: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("CodexUsageWidget/usage.json")
    }

    static var fallbackFile: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex/usage-widget.json")
    }

    static func ensureSampleFile() {
        let target = primaryFile
        guard !FileManager.default.fileExists(atPath: target.path) else { return }
        try? FileManager.default.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
        if let data = try? JSONEncoder.pretty.encode(UsageSnapshot.sample) {
            try? data.write(to: target, options: .atomic)
        }
    }
}

extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

final class UsageStore: ObservableObject {
    @Published private(set) var snapshot = UsageSnapshot.sample
    @Published private(set) var dataSourceNote = "示例数据"

    private var timer: Timer?
    private let refreshQueue = DispatchQueue(label: "local.codex.usage-widget.refresh", qos: .utility)
    private var refreshInFlight = false

    init() {
        UsagePaths.ensureSampleFile()
        reload()
        timer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in
            self?.reload()
        }
    }

    func reload() {
        refreshQueue.async { [weak self] in
            guard let self else { return }
            guard !self.refreshInFlight else { return }
            self.refreshInFlight = true
            defer { self.refreshInFlight = false }

            let result: (UsageSnapshot, String)? =
                CodexRateLimitReader.latestSnapshot().map { ($0, "Codex 日志") }
                ?? self.snapshot(from: UsagePaths.primaryFile, note: "本地数据")
                ?? self.snapshot(from: UsagePaths.fallbackFile, note: "~/.codex")

            guard let result else { return }

            DispatchQueue.main.async { [weak self] in
                self?.snapshot = result.0
                self?.dataSourceNote = result.1
            }
        }
    }

    private func snapshot(from url: URL, note: String) -> (UsageSnapshot, String)? {
        guard
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode(UsageSnapshot.self, from: data)
        else {
            return nil
        }
        return (decoded, note)
    }
}
