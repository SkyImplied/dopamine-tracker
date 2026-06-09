import Foundation
@preconcurrency import WatchConnectivity

private struct CompanionCheckInPayload: Sendable {
    let id: UUID
    let kind: CheckInKind
    let date: Date
    let note: String
}
private func checkInPayload(from payload: [String: Any]) -> CompanionCheckInPayload? {
    guard
        payload["type"] as? String == "checkIn",
        let idString = payload["id"] as? String,
        let id = UUID(uuidString: idString),
        let kindValue = payload["kind"] as? String,
        let kind = CheckInKind(rawValue: kindValue),
        let timestamp = payload["timestamp"] as? Double
    else { return nil }

    let note = payload["note"] as? String ?? ""
    return CompanionCheckInPayload(
        id: id,
        kind: kind,
        date: Date(timeIntervalSince1970: timestamp),
        note: note
    )
}

@MainActor
final class PhoneWatchConnectivity: NSObject, WCSessionDelegate {
    private let store: CheckInStore
    private let session: WCSession?

    init(store: CheckInStore) {
        self.store = store
        session = WCSession.isSupported() ? .default : nil
        super.init()
        session?.delegate = self
        session?.activate()
    }

    func syncSummary() {
        guard let session, session.activationState == .activated else { return }
        try? session.updateApplicationContext(summaryPayload())
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        guard activationState == .activated else { return }
        Task { @MainActor [weak self] in
            self?.syncSummary()
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        if let payload = checkInPayload(from: userInfo) {
            Task { @MainActor [weak self] in
                self?.receive(payload)
            }
        } else if userInfo["type"] as? String == "summaryRequest" {
            Task { @MainActor [weak self] in
                self?.syncSummary()
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let payload = checkInPayload(from: message) {
            Task { @MainActor [weak self] in
                self?.receive(payload)
            }
        } else if message["type"] as? String == "summaryRequest" {
            Task { @MainActor [weak self] in
                self?.syncSummary()
            }
        }
    }

    private func receive(_ payload: CompanionCheckInPayload) {
        let entry = CheckIn(id: payload.id, kind: payload.kind, date: payload.date, note: payload.note)
        _ = store.addFromCompanion(entry)
        syncSummary()
    }

    private func summaryPayload() -> [String: Any] {
        let discreetMode = UserDefaults.standard.object(forKey: "discreetMode") as? Bool ?? true
        let recent = store.recentEntries.prefix(3).map { entry in
            [
                "id": entry.id.uuidString,
                "kind": entry.kind.rawValue,
                "timestamp": entry.date.timeIntervalSince1970
            ] as [String: Any]
        }

        return [
            "type": "summary",
            "score": store.score,
            "baseScore": store.baseScore,
            "recentAdjustment": store.recentAdjustment,
            "stableBonus": store.stableBonus,
            "scoreBandTitle": store.scoreBand.title,
            "stableDays": store.stableDays,
            "todayCount": store.todayEntries.count,
            "discreetMode": discreetMode,
            "recent": recent
        ]
    }
}
