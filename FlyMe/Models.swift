import Foundation
import SwiftUI
import UniformTypeIdentifiers

enum CheckInKind: String, Codable, CaseIterable, Identifiable {
    case urge
    case redirected
    case masturbation
    case intimacy
    case explicitContent
    case nocturnalEmission

    var id: Self { self }

    var isSensitive: Bool {
        switch self {
        case .masturbation, .intimacy, .explicitContent, .nocturnalEmission: true
        case .urge, .redirected: false
        }
    }

    var title: String {
        switch self {
        case .urge: "欲望来袭"
        case .redirected: "成功转移"
        case .masturbation: "自慰"
        case .intimacy: "房事"
        case .explicitContent: "看黄"
        case .nocturnalEmission: "遗精"
        }
    }

    var subtitle: String {
        switch self {
        case .urge: "觉察当下，不评判"
        case .redirected: "做出了更好的选择"
        case .masturbation: "记录事实即可"
        case .intimacy: "亲密关系记录"
        case .explicitContent: "识别触发场景"
        case .nocturnalEmission: "自然生理现象"
        }
    }

    var symbol: String {
        switch self {
        case .urge: "waveform.path.ecg"
        case .redirected: "wind"
        case .masturbation: "hand.raised.fill"
        case .intimacy: "heart.fill"
        case .explicitContent: "eye.slash.fill"
        case .nocturnalEmission: "moon.stars.fill"
        }
    }

    var tint: Color {
        switch self {
        case .urge: .orange
        case .redirected: .mint
        case .masturbation: .purple
        case .intimacy: .pink
        case .explicitContent: .indigo
        case .nocturnalEmission: .cyan
        }
    }

    var scoreWeight: Double {
        switch self {
        case .urge: -1
        case .redirected: 3
        case .masturbation: -5
        case .intimacy: 0
        case .explicitContent: -7
        case .nocturnalEmission: 0
        }
    }

    var successTitle: String {
        switch self {
        case .urge: "你看见了此刻"
        case .redirected: "做得很好"
        case .masturbation: "已诚实记录"
        case .intimacy: "已记录亲密时刻"
        case .explicitContent: "觉察，就是改变"
        case .nocturnalEmission: "已记录身体状态"
        }
    }

    var successMessage: String {
        switch self {
        case .urge: "先慢慢呼吸。冲动像浪，会升起，也会退去。"
        case .redirected: "你把主动权留给了自己，这次选择值得记住。"
        case .masturbation: "一次记录不会定义你，下一刻仍然可以重新选择。"
        case .intimacy: "了解自己的节奏，也是在认真照顾关系。"
        case .explicitContent: "无需责备自己。识别触发场景，下一次会更清醒。"
        case .nocturnalEmission: "这是自然生理现象，不会影响你的自律指数。"
        }
    }
}

struct CheckIn: Codable, Identifiable {
    let id: UUID
    let kind: CheckInKind
    let date: Date
    let note: String

    init(kind: CheckInKind, date: Date = .now, note: String = "") {
        id = UUID()
        self.kind = kind
        self.date = date
        self.note = note
    }
}

struct DaySummary: Identifiable {
    let date: Date
    let count: Int
    let score: Int
    var id: Date { date }
}

enum TrendRange: String, CaseIterable, Identifiable {
    case week = "近一周"
    case month = "近一个月"
    case halfYear = "近半年"
    case year = "近 1 年"

    var id: Self { self }

    var bucketCount: Int {
        switch self {
        case .week: 7
        case .month: 30
        case .halfYear: 26
        case .year: 12
        }
    }

    var bucketComponent: Calendar.Component {
        switch self {
        case .week, .month: .day
        case .halfYear: .weekOfYear
        case .year: .month
        }
    }

    var bucketLabel: String {
        switch self {
        case .week, .month: "每天"
        case .halfYear: "每周"
        case .year: "每月"
        }
    }
}

enum TrendMetric: String, CaseIterable, Identifiable {
    case urge
    case redirected
    case masturbation
    case intimacy
    case explicitContent
    case nocturnalEmission

    var id: Self { self }

    var title: String {
        switch self {
        case .urge: CheckInKind.urge.title
        case .redirected: CheckInKind.redirected.title
        case .masturbation: CheckInKind.masturbation.title
        case .intimacy: CheckInKind.intimacy.title
        case .explicitContent: CheckInKind.explicitContent.title
        case .nocturnalEmission: CheckInKind.nocturnalEmission.title
        }
    }

    var symbol: String {
        switch self {
        case .urge: CheckInKind.urge.symbol
        case .redirected: CheckInKind.redirected.symbol
        case .masturbation: CheckInKind.masturbation.symbol
        case .intimacy: CheckInKind.intimacy.symbol
        case .explicitContent: CheckInKind.explicitContent.symbol
        case .nocturnalEmission: CheckInKind.nocturnalEmission.symbol
        }
    }

    var tint: Color {
        switch self {
        case .urge: CheckInKind.urge.tint
        case .redirected: CheckInKind.redirected.tint
        case .masturbation: CheckInKind.masturbation.tint
        case .intimacy: CheckInKind.intimacy.tint
        case .explicitContent: CheckInKind.explicitContent.tint
        case .nocturnalEmission: CheckInKind.nocturnalEmission.tint
        }
    }

    var kind: CheckInKind {
        switch self {
        case .urge: .urge
        case .redirected: .redirected
        case .masturbation: .masturbation
        case .intimacy: .intimacy
        case .explicitContent: .explicitContent
        case .nocturnalEmission: .nocturnalEmission
        }
    }
}

struct TrendPoint: Identifiable {
    let metric: TrendMetric
    let date: Date
    let value: Double
    var id: String { "\(metric.rawValue)-\(date.timeIntervalSinceReferenceDate)" }
}

struct ScoreTrendPoint: Identifiable {
    let date: Date
    let score: Double
    var id: Date { date }
}

@Observable
final class CheckInStore {
    private(set) var entries: [CheckIn] = []
    private let key = "private.checkins.v1"
    private let calendar = Calendar.current

    init() {
        load()
    }

    func add(_ kind: CheckInKind, date: Date = .now, note: String = "") {
        withAnimation(.spring(duration: 0.5, bounce: 0.22)) {
            entries.insert(CheckIn(kind: kind, date: date, note: note), at: 0)
            entries.sort { $0.date > $1.date }
        }
        save()
    }

    func delete(_ entry: CheckIn) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    func delete(ids: Set<UUID>) {
        withAnimation(.spring(duration: 0.4, bounce: 0.12)) {
            entries.removeAll { ids.contains($0.id) }
        }
        save()
    }

    func backupDocument() -> CheckInBackupDocument {
        CheckInBackupDocument(entries: entries)
    }

    func restoreBackup(from data: Data) throws {
        let restored = try JSONDecoder().decode([CheckIn].self, from: data)
        let merged = Dictionary(grouping: entries + restored, by: \.id)
            .compactMap { $0.value.max(by: { $0.date < $1.date }) }
            .sorted { $0.date > $1.date }
        entries = merged
        save()
    }

    var todayEntries: [CheckIn] {
        entries.filter { calendar.isDateInToday($0.date) }
    }

    var recentEntries: [CheckIn] {
        Array(entries.sorted { $0.date > $1.date }.prefix(12))
    }

    var score: Int {
        min(100, max(0, Int((82 + recentAdjustment + stableBonus).rounded())))
    }

    var recentAdjustment: Double {
        recentScoredEntries.reduce(0.0) { $0 + $1.kind.scoreWeight }
    }

    var stableBonus: Double {
        Double(min(stableDays, 7)) * 2.5
    }

    var recentScoredEntries: [CheckIn] {
        let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: .now))!
        return entries.filter { $0.date >= start }
    }

    var stableDays: Int {
        guard let earliestDate = entries.map(\.date).min() else { return 0 }
        let earliestDay = calendar.startOfDay(for: earliestDate)
        var days = 0
        for offset in 0..<60 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: .now) else { break }
            guard calendar.startOfDay(for: date) >= earliestDay else { break }
            let dayEntries = entries.filter { calendar.isDate($0.date, inSameDayAs: date) }
            if dayEntries.contains(where: { $0.kind == .explicitContent || $0.kind == .masturbation }) {
                break
            }
            days += 1
        }
        return days
    }

    var redirectRate: Int {
        let urges = entries.filter { $0.kind == .urge }.count
        let redirects = entries.filter { $0.kind == .redirected }.count
        guard urges + redirects > 0 else { return 0 }
        return Int((Double(redirects) / Double(urges + redirects) * 100).rounded())
    }

    var weekly: [DaySummary] {
        (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: .now) else { return nil }
            let matches = entries.filter { calendar.isDate($0.date, inSameDayAs: date) }
            let dayScore = min(100, max(30, Int(88 + matches.reduce(0.0) { $0 + $1.kind.scoreWeight })))
            return DaySummary(date: date, count: matches.count, score: dayScore)
        }
    }

    func trendPoints(range: TrendRange, metrics: Set<TrendMetric>) -> [TrendPoint] {
        let starts = (0..<range.bucketCount).reversed().compactMap { offset in
            calendar.date(byAdding: range.bucketComponent, value: -offset, to: calendar.startOfDay(for: .now))
        }

        return metrics.flatMap { metric in
            starts.map { start in
                let end = calendar.date(byAdding: range.bucketComponent, value: 1, to: start) ?? .now
                let bucketEntries = entries.filter { $0.date >= start && $0.date < end }
                let value = Double(bucketEntries.filter { $0.kind == metric.kind }.count)
                return TrendPoint(metric: metric, date: start, value: value)
            }
        }
    }

    func scoreTrendPoints(range: TrendRange) -> [ScoreTrendPoint] {
        (0..<range.bucketCount).reversed().compactMap { offset in
            guard let start = calendar.date(
                byAdding: range.bucketComponent,
                value: -offset,
                to: calendar.startOfDay(for: .now)
            ) else { return nil }
            let end = calendar.date(byAdding: range.bucketComponent, value: 1, to: start) ?? .now
            return ScoreTrendPoint(date: start, score: averageDailyScore(from: start, to: min(end, .now)))
        }
    }

    func trendTotal(for metric: TrendMetric, range: TrendRange) -> Int {
        guard let start = calendar.date(
            byAdding: range.bucketComponent,
            value: -(range.bucketCount - 1),
            to: calendar.startOfDay(for: .now)
        ) else { return 0 }
        return entries.filter { $0.kind == metric.kind && $0.date >= start }.count
    }

    func last35Days(for kind: CheckInKind) -> [DaySummary] {
        (0..<35).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: .now) else { return nil }
            let matches = entries.filter { $0.kind == kind && calendar.isDate($0.date, inSameDayAs: date) }
            return DaySummary(date: date, count: matches.count, score: 0)
        }
    }

    var kindCounts: [(kind: CheckInKind, count: Int)] {
        CheckInKind.allCases.map { kind in
            (kind, entries.filter { $0.kind == kind }.count)
        }
        .filter { $0.count > 0 }
        .sorted { $0.count > $1.count }
    }

    var recordedDays: Int {
        Set(entries.map { calendar.startOfDay(for: $0.date) }).count
    }

    var groupedEntries: [(date: Date, entries: [CheckIn])] {
        let groups = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.date) }
        return groups
            .map { (date: $0.key, entries: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.date > $1.date }
    }

    var encouragement: String {
        switch score {
        case 90...: "状态很稳，继续把注意力留给真正重要的事。"
        case 75..<90: "你正在建立节奏。觉察本身，就是改变的开始。"
        case 55..<75: "今天不需要完美，只需要做下一次更清醒的选择。"
        default: "先照顾好自己。一次记录不会定义你，下一刻仍可重新开始。"
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func averageDailyScore(from start: Date, to end: Date) -> Double {
        var date = calendar.startOfDay(for: start)
        var scores: [Double] = []
        while date <= end {
            let matches = entries.filter { calendar.isDate($0.date, inSameDayAs: date) }
            scores.append(Double(min(100, max(30, Int(88 + matches.reduce(0.0) { $0 + $1.kind.scoreWeight })))))
            guard let next = calendar.date(byAdding: .day, value: 1, to: date) else { break }
            date = next
        }
        return scores.isEmpty ? 88 : scores.reduce(0, +) / Double(scores.count)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode([CheckIn].self, from: data)
        else { return }
        entries = decoded
    }

}

struct CheckInBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    let entries: [CheckIn]

    init(entries: [CheckIn] = []) {
        self.entries = entries
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        entries = try JSONDecoder().decode([CheckIn].self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: try JSONEncoder().encode(entries))
    }
}
