import Foundation

enum CodexRateLimitReader {
    private static var cachedCandidates: [URL] = []
    private static var lastDiscovery = Date.distantPast

    private struct Event: Decodable {
        let timestamp: String?
        let payload: Payload?
    }

    private struct Payload: Decodable {
        let rateLimits: RateLimits?

        enum CodingKeys: String, CodingKey {
            case rateLimits = "rate_limits"
        }
    }

    private struct RateLimits: Decodable {
        let limitId: String?
        let primary: Primary?
        let planType: String?

        enum CodingKeys: String, CodingKey {
            case limitId = "limit_id"
            case primary
            case planType = "plan_type"
        }
    }

    private struct Primary: Decodable {
        let usedPercent: Double?
        let windowMinutes: Int?
        let resetsAt: TimeInterval?

        enum CodingKeys: String, CodingKey {
            case usedPercent = "used_percent"
            case windowMinutes = "window_minutes"
            case resetsAt = "resets_at"
        }
    }

    private struct Reading {
        let timestamp: String
        let usedPercent: Double
        let windowMinutes: Int?
        let resetsAt: TimeInterval
        let planType: String?
    }

    static func latestSnapshot() -> UsageSnapshot? {
        guard let reading = latestReading() else { return nil }

        let used = min(100, max(0, reading.usedPercent))
        let remaining = Int((100 - used).rounded())
        let usedRounded = Int(used.rounded())
        let resetDate = Date(timeIntervalSince1970: reading.resetsAt)
        let updatedDate = isoDate(reading.timestamp) ?? Date()
        let plan = planLabel(reading.planType)
        let planTitle = plan.isEmpty ? "Codex" : "Codex \(plan)"

        return UsageSnapshot(
            plan: planTitle,
            title: "剩余用量",
            remainingPercent: remaining,
            remainingLabel: "\(remaining)%",
            usedLabel: "已用 \(usedRounded)%",
            resetLabel: "\(resetFormatter.string(from: resetDate)) 重置",
            status: "真实数据",
            updatedAt: timeFormatter.string(from: updatedDate),
            samples: [
                UsageSample(label: "当前", value: "\(remaining)%", detail: "可用"),
                UsageSample(label: "已用", value: "\(usedRounded)%", detail: "真实"),
                UsageSample(label: "更新", value: timeFormatter.string(from: updatedDate), detail: "日志"),
                UsageSample(label: "重置", value: shortDateFormatter.string(from: resetDate), detail: timeOnlyFormatter.string(from: resetDate))
            ]
        )
    }

    private static func latestReading() -> Reading? {
        var best: Reading?
        let decoder = JSONDecoder()

        for url in candidateFiles() {
            guard let text = tailText(from: url) else { continue }
            guard text.contains("\"rate_limits\"") else { continue }

            for line in text.split(separator: "\n") where line.contains("\"rate_limits\"") {
                guard let lineData = String(line).data(using: .utf8) else { continue }
                guard let event = try? decoder.decode(Event.self, from: lineData) else { continue }
                guard
                    let timestamp = event.timestamp,
                    let primary = event.payload?.rateLimits?.primary,
                    let used = primary.usedPercent,
                    let resetsAt = primary.resetsAt
                else {
                    continue
                }

                let reading = Reading(
                    timestamp: timestamp,
                    usedPercent: used,
                    windowMinutes: primary.windowMinutes,
                    resetsAt: resetsAt,
                    planType: event.payload?.rateLimits?.planType
                )

                if best == nil || reading.timestamp > best!.timestamp {
                    best = reading
                }
            }
        }

        return best
    }

    private static func candidateFiles() -> [URL] {
        if !cachedCandidates.isEmpty && Date().timeIntervalSince(lastDiscovery) < 60 {
            return cachedCandidates
        }

        let root = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".codex")
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey, .contentModificationDateKey],
            options: []
        ) else {
            return cachedCandidates
        }

        cachedCandidates = enumerator
            .compactMap { $0 as? URL }
            .filter { $0.pathExtension == "jsonl" }
            .compactMap { url -> (URL, Date)? in
                let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .contentModificationDateKey])
                guard values?.isRegularFile == true else { return nil }
                return (url, values?.contentModificationDate ?? .distantPast)
            }
            .sorted { $0.1 > $1.1 }
            .prefix(8)
            .map(\.0)
        lastDiscovery = Date()

        return cachedCandidates
    }

    private static func tailText(from url: URL, maxBytes: UInt64 = 2 * 1024 * 1024) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }

        let size = (try? handle.seekToEnd()) ?? 0
        let offset = size > maxBytes ? size - maxBytes : 0
        try? handle.seek(toOffset: offset)
        let data = handle.readDataToEndOfFile()
        guard var text = String(data: data, encoding: .utf8) else { return nil }

        if offset > 0, let newline = text.firstIndex(of: "\n") {
            text.removeSubrange(text.startIndex...newline)
        }
        return text
    }

    private static func planLabel(_ raw: String?) -> String {
        switch raw?.lowercased() {
        case "plus": return "Plus"
        case "pro": return "Pro"
        case "team": return "Team"
        case "enterprise": return "Enterprise"
        case .some(let value): return value.capitalized
        case nil: return ""
        }
    }

    private static func isoDate(_ string: String) -> Date? {
        ISO8601DateFormatter().date(from: string)
    }

    private static let resetFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    private static let timeOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}
