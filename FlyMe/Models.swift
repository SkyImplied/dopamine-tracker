import Foundation
import SwiftUI
import UniformTypeIdentifiers

enum CheckInKind: String, Codable, CaseIterable, Identifiable, Sendable {
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

    func displayTitle(discreetMode: Bool, coded: Bool = false) -> String {
        guard discreetMode && isSensitive else { return title }
        guard coded else { return "私密记录" }
        return switch self {
        case .masturbation: "私密 A"
        case .intimacy: "私密 B"
        case .explicitContent: "私密 C"
        case .nocturnalEmission: "私密 D"
        case .urge, .redirected: title
        }
    }

    func displaySymbol(discreetMode: Bool) -> String {
        discreetMode && isSensitive ? "lock.fill" : symbol
    }

    func displayTint(discreetMode: Bool) -> Color {
        discreetMode && isSensitive ? .purple : tint
    }

    func displaySubtitle(discreetMode: Bool) -> String {
        discreetMode && isSensitive ? "安全记录，不显示具体类型" : subtitle
    }
}

struct CheckIn: Codable, Identifiable, Sendable {
    let id: UUID
    let kind: CheckInKind
    let date: Date
    let note: String

    init(id: UUID = UUID(), kind: CheckInKind, date: Date = .now, note: String = "") {
        self.id = id
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

    func displayTitle(discreetMode: Bool, coded: Bool = true) -> String {
        kind.displayTitle(discreetMode: discreetMode, coded: coded)
    }

    func displaySymbol(discreetMode: Bool) -> String {
        kind.displaySymbol(discreetMode: discreetMode)
    }

    func displayTint(discreetMode: Bool) -> Color {
        kind.displayTint(discreetMode: discreetMode)
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

enum ScoreBand: String, CaseIterable, Identifiable {
    case steady
    case growing
    case adjusting
    case caring

    var id: Self { self }

    static func band(for score: Int) -> Self {
        switch score {
        case 85...: .steady
        case 70..<85: .growing
        case 55..<70: .adjusting
        default: .caring
        }
    }

    var rangeLabel: String {
        switch self {
        case .steady: "85–100"
        case .growing: "70–84"
        case .adjusting: "55–69"
        case .caring: "0–54"
        }
    }

    var title: String {
        switch self {
        case .steady: "稳定前行"
        case .growing: "节奏良好"
        case .adjusting: "正在调整"
        case .caring: "需要关怀"
        }
    }

    var symbol: String {
        switch self {
        case .steady: "sparkles"
        case .growing: "leaf.fill"
        case .adjusting: "arrow.trianglehead.2.clockwise"
        case .caring: "heart.fill"
        }
    }

    var tint: Color {
        switch self {
        case .steady: .mint
        case .growing: .cyan
        case .adjusting: .orange
        case .caring: .pink
        }
    }

    var encouragement: String {
        switch self {
        case .steady: "状态很稳，继续把注意力留给真正重要的事。"
        case .growing: "你正在建立节奏。觉察本身，就是改变的开始。"
        case .adjusting: "今天不需要完美，只需要做下一次更清醒的选择。"
        case .caring: "先照顾好自己。分数只是信号，下一刻仍可重新开始。"
        }
    }
}

enum ScoreAlertReason {
    case rapidDrop
    case lowScore
}

struct ScoreAlert: Identifiable {
    let id = UUID()
    let previousScore: Int
    let currentScore: Int
    let reason: ScoreAlertReason

    var band: ScoreBand { .band(for: currentScore) }
    var drop: Int { max(0, previousScore - currentScore) }
}

@Observable
final class CheckInStore {
    private(set) var entries: [CheckIn] = []
    private let key = "private.checkins.v1"
    private let calendar = Calendar.current
    let baseScore = 80.0

    init() {
        load()
    }

    @discardableResult
    func add(_ kind: CheckInKind, date: Date = .now, note: String = "") -> ScoreAlert? {
        let previousScore = score
        withAnimation(.spring(duration: 0.5, bounce: 0.22)) {
            entries.insert(CheckIn(kind: kind, date: date, note: note), at: 0)
            entries.sort { $0.date > $1.date }
        }
        save()
        return scoreAlert(previousScore: previousScore, currentScore: score, kind: kind, date: date)
    }

    @discardableResult
    func addFromCompanion(_ entry: CheckIn) -> Bool {
        guard !entries.contains(where: { $0.id == entry.id }) else { return false }
        entries.append(entry)
        entries.sort { $0.date > $1.date }
        save()
        return true
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
        score(at: .now)
    }

    var recentAdjustment: Double {
        dynamicAdjustment(at: .now)
    }

    var stableBonus: Double {
        stableBonus(at: .now)
    }

    var recentScoredEntries: [CheckIn] {
        let start = calendar.date(byAdding: .day, value: -13, to: calendar.startOfDay(for: .now))!
        return entries.filter { $0.date >= start && $0.date <= .now }
    }

    var stableDays: Int {
        stableDays(at: .now)
    }

    var scoreBand: ScoreBand {
        .band(for: score)
    }

    private func stableDays(at referenceDate: Date) -> Int {
        let eligibleEntries = entries.filter { $0.date <= referenceDate }
        guard let earliestDate = eligibleEntries.map(\.date).min() else { return 0 }
        let earliestDay = calendar.startOfDay(for: earliestDate)
        var days = 0
        for offset in 0..<60 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: referenceDate) else { break }
            guard calendar.startOfDay(for: date) >= earliestDay else { break }
            let dayEntries = eligibleEntries.filter { calendar.isDate($0.date, inSameDayAs: date) }
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
            return DaySummary(date: date, count: matches.count, score: score(at: endOfDay(for: date)))
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
        scoreBand.encouragement
    }

    func aiTrendContext(includeDetailedCategories: Bool, discreetMode: Bool = false) -> String {
        let recent = recentScoredEntries
        let recentDays = Set(recent.map { calendar.startOfDay(for: $0.date) }).count
        let previousWeekStart = calendar.date(byAdding: .day, value: -13, to: calendar.startOfDay(for: .now)) ?? .now
        let thisWeekStart = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: .now)) ?? .now
        let previousWeekCount = recent.filter { $0.date >= previousWeekStart && $0.date < thisWeekStart }.count
        let thisWeekCount = recent.filter { $0.date >= thisWeekStart }.count
        let direction = thisWeekCount < previousWeekCount ? "减少" : thisWeekCount > previousWeekCount ? "增加" : "持平"

        var lines = [
            "当前自律指数：\(score)/100（\(scoreBand.title)）",
            "当前稳定节奏：\(stableDays) 天",
            "成功转移率：\(redirectRate)%",
            "近 14 天共记录 \(recent.count) 次，覆盖 \(recentDays) 天",
            "近 7 天记录次数相较此前 7 天：\(direction)",
            "说明：分数仅用于观察趋势，不代表医学、心理诊断或人的价值。"
        ]

        if includeDetailedCategories {
            let details = CheckInKind.allCases.map { kind in
                "\(kind.displayTitle(discreetMode: discreetMode, coded: true)) \(recent.filter { $0.kind == kind }.count) 次"
            }.joined(separator: "；")
            lines.append("近 14 天详细分类：\(details)")
        }
        return lines.joined(separator: "\n")
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func averageDailyScore(from start: Date, to end: Date) -> Double {
        var date = calendar.startOfDay(for: start)
        var scores: [Double] = []
        while date <= end {
            scores.append(Double(score(at: min(endOfDay(for: date), end))))
            guard let next = calendar.date(byAdding: .day, value: 1, to: date) else { break }
            date = next
        }
        return scores.isEmpty ? baseScore : scores.reduce(0, +) / Double(scores.count)
    }

    private func score(at referenceDate: Date) -> Int {
        min(100, max(0, Int((baseScore + dynamicAdjustment(at: referenceDate) + stableBonus(at: referenceDate)).rounded())))
    }

    private func stableBonus(at referenceDate: Date) -> Double {
        Double(min(stableDays(at: referenceDate), 7)) * 2.2
    }

    private func dynamicAdjustment(at referenceDate: Date) -> Double {
        let referenceDay = calendar.startOfDay(for: referenceDate)
        guard let start = calendar.date(byAdding: .day, value: -13, to: referenceDay) else { return 0 }
        let relevant = entries
            .filter { $0.date >= start && $0.date <= referenceDate }
            .sorted { $0.date < $1.date }

        var repeatedNegativeByDay: [Date: Int] = [:]
        var recentPressureDates: [Date] = []

        return relevant.reduce(into: 0.0) { total, entry in
            let entryDay = calendar.startOfDay(for: entry.date)
            let daysAgo = max(0, calendar.dateComponents([.day], from: entryDay, to: referenceDay).day ?? 0)
            let recency = max(0.35, 1 - Double(daysAgo) * 0.05)
            var multiplier = 1.0

            if entry.kind == .explicitContent || entry.kind == .masturbation {
                let repeats = repeatedNegativeByDay[entryDay, default: 0]
                multiplier = min(1.75, 1 + Double(repeats) * 0.25)
                repeatedNegativeByDay[entryDay] = repeats + 1
                recentPressureDates.append(entry.date)
            } else if entry.kind == .redirected {
                let recentPressure = recentPressureDates.filter {
                    entry.date.timeIntervalSince($0) <= 3 * 24 * 60 * 60
                }.count
                multiplier = 1 + min(0.5, Double(recentPressure) * 0.1)
            }

            total += entry.kind.scoreWeight * recency * multiplier
        }
    }

    private func scoreAlert(
        previousScore: Int,
        currentScore: Int,
        kind: CheckInKind,
        date: Date
    ) -> ScoreAlert? {
        guard kind == .explicitContent || kind == .masturbation else { return nil }
        guard let recentStart = calendar.date(byAdding: .day, value: -13, to: calendar.startOfDay(for: .now)),
              date >= recentStart
        else { return nil }

        let drop = previousScore - currentScore
        if currentScore < 55 {
            return ScoreAlert(previousScore: previousScore, currentScore: currentScore, reason: .lowScore)
        }
        if drop >= 6 {
            return ScoreAlert(previousScore: previousScore, currentScore: currentScore, reason: .rapidDrop)
        }
        return nil
    }

    private func endOfDay(for date: Date) -> Date {
        calendar.date(byAdding: DateComponents(day: 1, second: -1), to: calendar.startOfDay(for: date)) ?? date
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
