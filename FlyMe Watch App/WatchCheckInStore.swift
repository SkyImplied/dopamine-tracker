import Foundation
import Observation
@preconcurrency import WatchConnectivity

enum WatchCheckInKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case urge
    case redirected
    case masturbation
    case intimacy
    case explicitContent
    case nocturnalEmission

    var id: Self { self }

    func title(discreetMode: Bool) -> String {
        if discreetMode {
            return switch self {
            case .urge: "欲望来袭"
            case .redirected: "成功转移"
            case .masturbation: "私密 A"
            case .intimacy: "私密 B"
            case .explicitContent: "私密 C"
            case .nocturnalEmission: "私密 D"
            }
        }

        return switch self {
        case .urge: "欲望来袭"
        case .redirected: "成功转移"
        case .masturbation: "自慰"
        case .intimacy: "房事"
        case .explicitContent: "看黄"
        case .nocturnalEmission: "遗精"
        }
    }

    func symbol(discreetMode: Bool) -> String {
        if discreetMode {
            return switch self {
            case .urge: "waveform.path.ecg"
            case .redirected: "wind"
            case .masturbation, .intimacy, .explicitContent, .nocturnalEmission: "lock.fill"
            }
        }

        return switch self {
        case .urge: "waveform.path.ecg"
        case .redirected: "wind"
        case .masturbation: "hand.raised.fill"
        case .intimacy: "heart.fill"
        case .explicitContent: "eye.slash.fill"
        case .nocturnalEmission: "moon.stars.fill"
        }
    }

    var tintName: String {
        switch self {
        case .urge: "orange"
        case .redirected: "mint"
        case .masturbation, .intimacy, .explicitContent, .nocturnalEmission: "purple"
        }
    }
}

struct WatchRecentEntry: Codable, Identifiable, Sendable {
    let id: UUID
    let kind: WatchCheckInKind
    let date: Date
}

@Observable
@MainActor
final class WatchCheckInStore: NSObject, @preconcurrency WCSessionDelegate {
    private(set) var score = 80
    private(set) var baseScore = 80.0
    private(set) var recentAdjustment = 0.0
    private(set) var stableBonus = 0.0
    private(set) var scoreBandTitle = "节奏良好"
    private(set) var stableDays = 0
    private(set) var todayCount = 0
    private(set) var recentEntries: [WatchRecentEntry] = []
    private(set) var lastSavedKind: WatchCheckInKind?
    private(set) var isPhoneReachable = false

    private let session: WCSession?
    private let defaults = UserDefaults.standard
    private let recentKey = "watch.recentEntries.v1"

    override init() {
        session = WCSession.isSupported() ? .default : nil
        super.init()
        loadRecent()
        session?.delegate = self
        session?.activate()
    }

    func add(_ kind: WatchCheckInKind) {
        let entry = WatchRecentEntry(id: UUID(), kind: kind, date: .now)
        recentEntries.insert(entry, at: 0)
        recentEntries = Array(recentEntries.prefix(6))
        todayCount += 1
        lastSavedKind = kind
        saveRecent()

        let payload: [String: Any] = [
            "type": "checkIn",
            "id": entry.id.uuidString,
            "kind": kind.rawValue,
            "timestamp": entry.date.timeIntervalSince1970,
            "note": ""
        ]
        session?.transferUserInfo(payload)
        if session?.isReachable == true {
            session?.sendMessage(payload, replyHandler: nil)
        }
    }

    func requestSummary() {
        guard session?.isReachable == true else { return }
        session?.sendMessage(["type": "summaryRequest"], replyHandler: nil)
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        Task { @MainActor [weak self] in
            self?.isPhoneReachable = session.isReachable
            self?.requestSummary()
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor [weak self] in
            self?.isPhoneReachable = session.isReachable
            self?.requestSummary()
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        let summary = WatchSummaryPayload(payload: applicationContext)
        Task { @MainActor [weak self] in
            self?.applySummary(summary)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        let summary = WatchSummaryPayload(payload: message)
        Task { @MainActor [weak self] in
            self?.applySummary(summary)
        }
    }

    private func applySummary(_ payload: WatchSummaryPayload?) {
        guard let payload else { return }
        score = payload.score
        baseScore = payload.baseScore
        recentAdjustment = payload.recentAdjustment
        stableBonus = payload.stableBonus
        scoreBandTitle = payload.scoreBandTitle
        stableDays = payload.stableDays
        todayCount = payload.todayCount
        recentEntries = payload.recent
        saveRecent()
    }

    private func saveRecent() {
        guard let data = try? JSONEncoder().encode(recentEntries) else { return }
        defaults.set(data, forKey: recentKey)
    }

    private func loadRecent() {
        guard
            let data = defaults.data(forKey: recentKey),
            let decoded = try? JSONDecoder().decode([WatchRecentEntry].self, from: data)
        else { return }
        recentEntries = decoded
    }
}

private struct WatchSummaryPayload: Sendable {
    let score: Int
    let baseScore: Double
    let recentAdjustment: Double
    let stableBonus: Double
    let scoreBandTitle: String
    let stableDays: Int
    let todayCount: Int
    let recent: [WatchRecentEntry]

    init?(payload: [String: Any]) {
        guard payload["type"] as? String == "summary" else { return nil }
        score = payload["score"] as? Int ?? 80
        baseScore = payload["baseScore"] as? Double ?? 80
        recentAdjustment = payload["recentAdjustment"] as? Double ?? 0
        stableBonus = payload["stableBonus"] as? Double ?? 0
        scoreBandTitle = payload["scoreBandTitle"] as? String ?? "节奏良好"
        stableDays = payload["stableDays"] as? Int ?? 0
        todayCount = payload["todayCount"] as? Int ?? 0

        let recentPayload = payload["recent"] as? [[String: Any]] ?? []
        recent = recentPayload.compactMap { item in
            guard
                let idValue = item["id"] as? String,
                let id = UUID(uuidString: idValue),
                let kindValue = item["kind"] as? String,
                let kind = WatchCheckInKind(rawValue: kindValue),
                let timestamp = item["timestamp"] as? Double
            else { return nil }
            return WatchRecentEntry(id: id, kind: kind, date: Date(timeIntervalSince1970: timestamp))
        }
    }
}
