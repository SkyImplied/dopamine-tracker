import CoreMotion
import HealthKit
import SwiftUI
@preconcurrency import WatchConnectivity

struct WatchHomeView: View {
    let store: WatchCheckInStore
    @AppStorage("watch.discreetMode") private var discreetMode = true
    @AppStorage("watch.soundEffects") private var soundEffects = true
    @State private var savedTrigger = 0
    @State private var successKind: WatchCheckInKind?

    var body: some View {
        ZStack {
            NavigationStack {
                TabView {
                    PageBackdrop(style: .score) {
                        ScorePage(store: store)
                    }
                    PageBackdrop(style: .quick) {
                        QuickCheckInPage(
                            discreetMode: discreetMode,
                            onSave: save
                        )
                    }
                    PageBackdrop(style: .allRecords) {
                        AllCheckInsPage(
                            store: store,
                            discreetMode: discreetMode,
                            onSave: save
                        )
                    }
                    PageBackdrop(style: .recent) {
                        RecentCheckInsPage(store: store, discreetMode: discreetMode)
                    }
                    PageBackdrop(style: .settings) {
                        WatchSettingsView()
                    }
                    PageBackdrop(style: .flight) {
                        MotionFlightPage()
                    }
                }
                .tabViewStyle(.verticalPage)
                .background(.clear)
                .toolbar(.hidden, for: .navigationBar)
                .sensoryFeedback(.success, trigger: savedTrigger) { _, _ in
                    soundEffects
                }
                .task {
                    store.requestSummary()
                }
            }

            if let successKind {
                WatchCheckInSuccessView(kind: successKind) {
                    dismissSuccess()
                }
                .transition(.opacity.combined(with: .scale(scale: 1.05)))
                .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: successKind?.rawValue)
    }

    private func save(_ kind: WatchCheckInKind) {
        store.add(kind)
        savedTrigger += 1
        presentSuccess(kind)
    }

    private func presentSuccess(_ kind: WatchCheckInKind) {
        successKind = kind
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            guard successKind == kind else { return }
            dismissSuccess()
        }
    }

    private func dismissSuccess() {
        successKind = nil
    }
}

private struct ScorePage: View {
    let store: WatchCheckInStore
    @State private var showingDetails = false

    var body: some View {
        Button {
            showingDetails = true
        } label: {
            VStack(spacing: 10) {
                ScoreRingView(score: store.score)
                    .frame(width: 146, height: 146)

                VStack(spacing: 2) {
                    Text(store.scoreBandTitle)
                        .font(.headline)
                    Text("自律指数")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("自律指数 \(store.score)，点击查看计算方式")
        .sheet(isPresented: $showingDetails) {
            ScoreDetailView(store: store)
        }
    }
}

private struct ScoreRingView: View {
    let score: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(.black.opacity(0.2))
                .padding(9)

            Circle()
                .stroke(.white.opacity(0.11), lineWidth: 14)
                .padding(11)

            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(
                    LinearGradient(
                        colors: [.cyan, .mint, .white.opacity(0.9), .orange],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(11)
                .shadow(color: .cyan.opacity(0.38), radius: 8)

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .clear, .white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .padding(23)

            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.system(size: 37, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text("指数")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.56))
            }
        }
        .padding(3)
        .glassEffect(.regular, in: .circle)
    }
}

private struct ScoreDetailView: View {
    let store: WatchCheckInStore

    var body: some View {
        List {
            detailRow("基础分", store.baseScore, .cyan, signed: false)
            detailRow("近 14 天", store.recentAdjustment, store.recentAdjustment >= 0 ? .mint : .orange)
            detailRow("稳定奖励", store.stableBonus, .purple)
            HStack {
                Text("最终结果")
                Spacer()
                Text("\(store.score)")
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }
        }
        .navigationTitle("指数计算")
    }

    private func detailRow(_ title: String, _ value: Double, _ tint: Color, signed: Bool = true) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(formatted(value, signed: signed))
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(tint)
        }
    }

    private func formatted(_ value: Double, signed: Bool) -> String {
        let text = value.formatted(.number.precision(.fractionLength(1)))
        guard signed else { return text }
        return value >= 0 ? "+\(text)" : text
    }
}

private struct QuickCheckInPage: View {
    let discreetMode: Bool
    let onSave: (WatchCheckInKind) -> Void

    var body: some View {
        GlassEffectContainer(spacing: 10) {
            VStack(spacing: 10) {
                Text("快速记录")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 10) {
                    actionButton(.urge)
                    actionButton(.redirected)
                }
            }
        }
        .padding(.horizontal, 2)
    }

    private func actionButton(_ kind: WatchCheckInKind) -> some View {
        Button {
            onSave(kind)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: kind.symbol(discreetMode: discreetMode))
                    .font(.title3)
                Text(kind.title(discreetMode: discreetMode))
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 98)
            .contentShape(.rect(cornerRadius: 24))
            .glassEffect(.regular.tint(kindTint(kind).opacity(0.62)).interactive(), in: .rect(cornerRadius: 24))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("记录\(kind.title(discreetMode: discreetMode))")
    }
}

private struct AllCheckInsPage: View {
    let store: WatchCheckInStore
    let discreetMode: Bool
    let onSave: (WatchCheckInKind) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 7),
        GridItem(.flexible(), spacing: 7)
    ]

    var body: some View {
        VStack(spacing: 9) {
            Text("完整记录")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: columns, spacing: 7) {
                ForEach(WatchCheckInKind.allCases) { kind in
                    Button {
                        onSave(kind)
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: kind.symbol(discreetMode: discreetMode))
                                .font(.caption.weight(.semibold))
                            Text(kind.title(discreetMode: discreetMode))
                                .font(.caption2.weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(.capsule)
                        .glassEffect(.regular.tint(kindTint(kind).opacity(0.38)).interactive(), in: .capsule)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("记录\(kind.title(discreetMode: discreetMode))")
                }
            }
        }
    }
}

private struct RecentCheckInsPage: View {
    let store: WatchCheckInStore
    let discreetMode: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("最近记录")
                .font(.headline)

            if store.recentEntries.isEmpty {
                ContentUnavailableView("暂无记录", systemImage: "tray")
                    .font(.caption)
            } else {
                ForEach(store.recentEntries.prefix(4)) { entry in
                    HStack(spacing: 8) {
                        Image(systemName: entry.kind.symbol(discreetMode: discreetMode))
                            .frame(width: 20)
                            .foregroundStyle(kindTint(entry.kind))
                        Text(entry.kind.title(discreetMode: discreetMode))
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        Text(entry.date, format: .dateTime.hour().minute())
                            .font(.caption2)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct WatchSettingsView: View {
    @AppStorage("watch.discreetMode") private var discreetMode = true
    @AppStorage("watch.soundEffects") private var soundEffects = true

    var body: some View {
        List {
            Toggle(isOn: $discreetMode) {
                Label("低调显示", systemImage: "lock.fill")
            }

            Toggle(isOn: $soundEffects) {
                Label("音效", systemImage: "speaker.wave.2.fill")
            }
        }
        .navigationTitle("设置")
    }
}

private struct WatchCheckInSuccessView: View {
    let kind: WatchCheckInKind
    let onDismiss: () -> Void
    @State private var appeared = false

    var body: some View {
        Button(action: onDismiss) {
            ZStack {
                Color.black

                Circle()
                    .fill(kindTint(kind).opacity(0.22))
                    .frame(width: 170, height: 170)
                    .scaleEffect(appeared ? 1 : 0.72)
                    .opacity(appeared ? 1 : 0)

                VStack(spacing: 12) {
                    Image(systemName: successSymbol)
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(kindTint(kind))
                        .symbolEffect(.bounce, value: appeared)

                    Text(successTitle)
                        .font(.headline)
                        .multilineTextAlignment(.center)

                    Text("已记录")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .scaleEffect(appeared ? 1 : 0.88)
                .opacity(appeared ? 1 : 0)
            }
            .ignoresSafeArea()
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.spring(duration: 0.55, bounce: 0.28)) {
                appeared = true
            }
        }
    }

    private var successSymbol: String {
        kind == .redirected ? "checkmark.circle.fill" : kind.symbol(discreetMode: true)
    }

    private var successTitle: String {
        switch kind {
        case .urge: "已觉察此刻"
        case .redirected: "做得很好"
        case .masturbation, .intimacy, .explicitContent, .nocturnalEmission: "已安心记录"
        }
    }
}

private func kindTint(_ kind: WatchCheckInKind) -> Color {
    switch kind {
    case .urge: .orange
    case .redirected: .mint
    case .masturbation, .intimacy, .explicitContent, .nocturnalEmission: .purple
    }
}

private enum PageBackgroundStyle {
    case score
    case quick
    case allRecords
    case recent
    case settings
    case flight
}

private struct PageBackdrop<Content: View>: View {
    let style: PageBackgroundStyle
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            WatchAmbientBackground(style: style)
                .ignoresSafeArea()
            content
                .padding(.horizontal, 2)
        }
    }
}

private struct WatchAmbientBackground: View {
    let style: PageBackgroundStyle

    var body: some View {
        ZStack {
            Color.black

            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.52, 0.46], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ],
                colors: palette,
                smoothsColors: true
            )
            .blur(radius: 24)
            .saturation(0.82)
            .opacity(0.76)

            LinearGradient(
                colors: [.black.opacity(0.08), .black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var palette: [Color] {
        switch style {
        case .score:
            [.black, .indigo.opacity(0.62), .black,
             .cyan.opacity(0.32), .purple.opacity(0.42), .mint.opacity(0.22),
             .black, .orange.opacity(0.18), .black]
        case .quick:
            [.black, .orange.opacity(0.45), .black,
             .pink.opacity(0.2), .mint.opacity(0.38), .cyan.opacity(0.24),
             .black, .teal.opacity(0.28), .black]
        case .allRecords:
            [.black, .purple.opacity(0.46), .black,
             .indigo.opacity(0.34), .cyan.opacity(0.22), .pink.opacity(0.28),
             .black, .mint.opacity(0.18), .black]
        case .recent:
            [.black, .teal.opacity(0.38), .black,
             .blue.opacity(0.24), .mint.opacity(0.28), .indigo.opacity(0.32),
             .black, .cyan.opacity(0.18), .black]
        case .settings:
            [.black, .gray.opacity(0.26), .black,
             .indigo.opacity(0.28), .purple.opacity(0.22), .cyan.opacity(0.16),
             .black, .white.opacity(0.08), .black]
        case .flight:
            [.black, .orange.opacity(0.34), .black,
             .red.opacity(0.22), .pink.opacity(0.34), .purple.opacity(0.26),
             .black, .cyan.opacity(0.16), .black]
        }
    }
}

private struct MotionFlightPage: View {
    @State private var session = MotionFlightSession()
    @AppStorage("watch.flightTargetMode") private var targetModeRawValue = FlightTargetMode.time.rawValue
    @AppStorage("watch.flightTargetSeconds") private var targetSeconds = 180
    @AppStorage("watch.flightTargetCount") private var targetCount = 100
    @State private var showingHistory = false
    @State private var showingTargets = false
    @State private var showingVictory = false

    var body: some View {
        ZStack {
            VStack(spacing: 5) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("动感起飞")
                        .font(.subheadline.weight(.semibold))
                    Text(targetSummary)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 54)

                Button {
                    session.isRunning ? session.stop() : session.start(
                        targetMode: targetMode,
                        targetSeconds: targetSeconds,
                        targetCount: targetCount
                    )
                } label: {
                    Text(session.isRunning ? "停止" : "Go")
                        .font(.headline.weight(.semibold))
                        .frame(width: 58, height: 32)
                        .contentShape(.capsule)
                        .glassEffect(
                            .regular.tint((session.isRunning ? Color.pink : Color.orange).opacity(0.58)).interactive(),
                            in: .capsule
                        )
                }
                .buttonStyle(.plain)

                HStack(spacing: 6) {
                    FlightSmallAction(title: "排行", symbol: "list.number") {
                        showingHistory = true
                    }
                    FlightSmallAction(title: "目标", symbol: "target") {
                        showingTargets = true
                    }
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 5) {
                    FlightMetricCell(title: "心率", value: session.heartRateText, unit: "bpm")
                    FlightMetricCell(title: "频率", value: session.frequencyText, unit: "次/分")
                    FlightMetricCell(title: "次数", value: "\(session.count)", unit: "次")
                    FlightMetricCell(title: "时间", value: session.elapsedText, unit: "")
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, 14)
            .padding(.bottom, 18)

            if showingVictory {
                FlightVictoryView {
                    showingVictory = false
                }
                .transition(.opacity.combined(with: .scale(scale: 1.04)))
                .zIndex(5)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: showingVictory)
        .task {
            session.prepare()
        }
        .onChange(of: session.targetCelebrationCount) { _, newValue in
            guard newValue > 0 else { return }
            showingVictory = true
            Task {
                try? await Task.sleep(for: .seconds(1.45))
                showingVictory = false
            }
        }
        .sheet(isPresented: $showingHistory) {
            FlightHistoryView(records: session.records)
        }
        .sheet(isPresented: $showingTargets) {
            FlightTargetView(
                targetMode: Binding(
                    get: { targetMode },
                    set: { targetModeRawValue = $0.rawValue }
                ),
                targetSeconds: $targetSeconds,
                targetCount: $targetCount
            )
        }
    }

    private var targetMode: FlightTargetMode {
        FlightTargetMode(rawValue: targetModeRawValue) ?? .time
    }

    private var targetSummary: String {
        switch targetMode {
        case .time: "目标 \(formatDuration(TimeInterval(targetSeconds)))"
        case .count: "目标 \(targetCount) 次"
        }
    }
}

private struct FlightSmallAction: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.caption2.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 26)
                .contentShape(.capsule)
                .glassEffect(.regular.tint(.white.opacity(0.05)).interactive(), in: .capsule)
        }
        .buttonStyle(.plain)
    }
}

private struct FlightTargetView: View {
    @Binding var targetMode: FlightTargetMode
    @Binding var targetSeconds: Int
    @Binding var targetCount: Int

    var body: some View {
        VStack(spacing: 7) {
            Text("目标")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 6) {
                targetModeButton(.time)
                targetModeButton(.count)
            }

            if targetMode == .time {
                CompactTargetControl(
                    title: "时间",
                    value: formatDuration(TimeInterval(targetSeconds)),
                    decrementDisabled: targetSeconds <= 30,
                    incrementDisabled: targetSeconds >= 1800,
                    decrement: { targetSeconds = max(30, targetSeconds - 30) },
                    increment: { targetSeconds = min(1800, targetSeconds + 30) }
                )
            } else {
                CompactTargetControl(
                    title: "次数",
                    value: "\(targetCount)",
                    unit: "次",
                    decrementDisabled: targetCount <= 10,
                    incrementDisabled: targetCount >= 1000,
                    decrement: { targetCount = max(10, targetCount - 10) },
                    increment: { targetCount = min(1000, targetCount + 10) }
                )
            }
        }
        .padding(.horizontal, 2)
    }

    private func targetModeButton(_ mode: FlightTargetMode) -> some View {
        Button {
            targetMode = mode
        } label: {
            Text(mode.title)
                .font(.caption.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 30)
                .contentShape(.capsule)
                .glassEffect(
                    .regular.tint(targetMode == mode ? Color.orange.opacity(0.38) : Color.white.opacity(0.04)).interactive(),
                    in: .capsule
                )
        }
        .buttonStyle(.plain)
    }
}

private struct CompactTargetControl: View {
    let title: String
    let value: String
    var unit = ""
    let decrementDisabled: Bool
    let incrementDisabled: Bool
    let decrement: () -> Void
    let increment: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            targetButton("minus", disabled: decrementDisabled, action: decrement)
            VStack(spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.title3.weight(.semibold).monospacedDigit())
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .glassEffect(.regular.tint(.white.opacity(0.06)), in: .rect(cornerRadius: 18))
            targetButton("plus", disabled: incrementDisabled, action: increment)
        }
    }

    private func targetButton(_ symbol: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.headline.weight(.semibold))
                .frame(width: 34, height: 48)
                .contentShape(.capsule)
                .glassEffect(.regular.interactive(), in: .capsule)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.42 : 1)
    }
}

private struct FlightHistoryView: View {
    let records: [MotionFlightRecord]

    var body: some View {
        List {
            if records.isEmpty {
                Text("暂无排行")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(records.sortedForRanking().prefix(20).enumerated()), id: \.element.id) { index, record in
                    HStack(spacing: 8) {
                        Text("#\(index + 1)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 26, alignment: .leading)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(record.count) 次")
                                .font(.headline.monospacedDigit())
                            Text(record.startDate, format: .dateTime.month(.twoDigits).day(.twoDigits).hour().minute())
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(record.durationText)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("历史排行")
    }
}

private struct FlightMetricCell: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 30)
        .glassEffect(.regular.tint(.white.opacity(0.06)), in: .rect(cornerRadius: 12))
    }
}

private struct FlightVictoryView: View {
    let onDismiss: () -> Void
    @State private var appeared = false

    var body: some View {
        Button(action: onDismiss) {
            ZStack {
                Color.black.opacity(0.92)
                Circle()
                    .fill(.orange.opacity(0.22))
                    .frame(width: 168, height: 168)
                    .scaleEffect(appeared ? 1 : 0.72)
                VStack(spacing: 10) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(.orange)
                    Text("目标达成")
                        .font(.headline)
                    Text("继续记录中")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.88)
            }
            .ignoresSafeArea()
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.28)) {
                appeared = true
            }
        }
    }
}

private enum FlightTargetMode: String, Codable, Sendable {
    case time
    case count

    var title: String {
        switch self {
        case .time: "时间"
        case .count: "次数"
        }
    }
}

@MainActor
@Observable
private final class MotionFlightSession {
    private(set) var isRunning = false
    private(set) var count = 0
    private(set) var elapsed: TimeInterval = 0
    private(set) var heartRate: Double?
    private(set) var records: [MotionFlightRecord] = []
    private(set) var targetCelebrationCount = 0

    private let motionManager = CMMotionManager()
    private let healthStore = HKHealthStore()
    private let watchSession: WCSession?
    private let recordsKey = "watch.motionFlightRecords.v1"
    private var timer: Timer?
    private var startDate: Date?
    private var lastStrokeDate: Date?
    private var activeTargetMode = FlightTargetMode.time
    private var activeTargetSeconds = 180
    private var activeTargetCount = 100
    private var recentStrokeDates: [Date] = []
    private var wasAboveThreshold = false
    private var hasCelebratedTarget = false
    private var heartRateQuery: HKAnchoredObjectQuery?

    init() {
        watchSession = WCSession.isSupported() ? .default : nil
        loadRecords()
    }

    var heartRateText: String {
        guard let heartRate else { return "--" }
        return "\(Int(heartRate.rounded()))"
    }

    var frequencyText: String {
        let now = Date()
        let recent = recentStrokeDates.filter { now.timeIntervalSince($0) <= 20 }
        guard recent.count >= 2 else { return "0" }
        let span = max(1, now.timeIntervalSince(recent.first ?? now))
        return "\(Int((Double(recent.count) / span * 60).rounded()))"
    }

    var elapsedText: String {
        let total = Int(elapsed.rounded())
        return "\(total / 60):" + String(format: "%02d", total % 60)
    }

    func prepare() {
        requestHeartRateAccess()
    }

    func start(targetMode: FlightTargetMode, targetSeconds: Int, targetCount: Int) {
        guard !isRunning else { return }
        isRunning = true
        count = 0
        elapsed = 0
        activeTargetMode = targetMode
        activeTargetSeconds = targetSeconds
        activeTargetCount = targetCount
        hasCelebratedTarget = false
        recentStrokeDates = []
        wasAboveThreshold = false
        startDate = .now
        lastStrokeDate = nil
        startTimer()
        startMotion()
        startHeartRateQuery()
    }

    func stop() {
        let record = makeRecord()
        isRunning = false
        timer?.invalidate()
        timer = nil
        motionManager.stopAccelerometerUpdates()
        if let heartRateQuery {
            healthStore.stop(heartRateQuery)
        }
        heartRateQuery = nil
        if let record {
            save(record)
            syncToIPhone(record)
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let startDate = self.startDate else { return }
                self.elapsed = Date().timeIntervalSince(startDate)
                if self.activeTargetMode == .time, self.elapsed >= TimeInterval(self.activeTargetSeconds) {
                    self.celebrateTargetIfNeeded()
                }
            }
        }
    }

    private func startMotion() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 1.0 / 30.0
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let data else { return }
            Task { @MainActor in
                self?.handleAcceleration(data.acceleration)
            }
        }
    }

    private func handleAcceleration(_ acceleration: CMAcceleration) {
        let magnitude = sqrt(
            acceleration.x * acceleration.x +
            acceleration.y * acceleration.y +
            acceleration.z * acceleration.z
        )
        let above = magnitude > 1.55
        defer { wasAboveThreshold = above }
        guard above, !wasAboveThreshold else { return }

        let now = Date()
        if let lastStrokeDate, now.timeIntervalSince(lastStrokeDate) < 0.28 {
            return
        }

        lastStrokeDate = now
        count += 1
        recentStrokeDates.append(now)
        recentStrokeDates = recentStrokeDates.filter { now.timeIntervalSince($0) <= 20 }
        if activeTargetMode == .count, count >= activeTargetCount {
            celebrateTargetIfNeeded()
        }
    }

    private func celebrateTargetIfNeeded() {
        guard !hasCelebratedTarget else { return }
        hasCelebratedTarget = true
        targetCelebrationCount += 1
    }

    private func requestHeartRateAccess() {
        guard HKHealthStore.isHealthDataAvailable(),
              let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)
        else { return }

        healthStore.requestAuthorization(toShare: [], read: [heartRateType]) { [weak self] _, _ in
            Task { @MainActor in
                self?.startHeartRateQuery()
            }
        }
    }

    private func startHeartRateQuery() {
        guard isRunning,
              HKHealthStore.isHealthDataAvailable(),
              heartRateQuery == nil,
              let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)
        else { return }

        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            self?.handleHeartRateSamples(samples)
        }

        query.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.handleHeartRateSamples(samples)
        }

        heartRateQuery = query
        healthStore.execute(query)
    }

    private nonisolated func handleHeartRateSamples(_ samples: [HKSample]?) {
        guard let sample = samples?.compactMap({ $0 as? HKQuantitySample }).last else { return }
        let unit = HKUnit.count().unitDivided(by: .minute())
        let value = sample.quantity.doubleValue(for: unit)
        Task { @MainActor [weak self] in
            self?.heartRate = value
        }
    }

    private func makeRecord() -> MotionFlightRecord? {
        guard let startDate, elapsed >= 1 || count > 0 else { return nil }
        return MotionFlightRecord(
            id: UUID(),
            startDate: startDate,
            duration: elapsed,
            count: count,
            averageFrequency: elapsed > 0 ? Double(count) / elapsed * 60 : 0,
            heartRate: heartRate,
            targetMode: activeTargetMode,
            targetSeconds: activeTargetSeconds,
            targetCount: activeTargetCount
        )
    }

    private func save(_ record: MotionFlightRecord) {
        records.insert(record, at: 0)
        records = Array(records.prefix(50))
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: recordsKey)
    }

    private func loadRecords() {
        guard
            let data = UserDefaults.standard.data(forKey: recordsKey),
            let decoded = try? JSONDecoder().decode([MotionFlightRecord].self, from: data)
        else { return }
        records = decoded
    }

    private func syncToIPhone(_ record: MotionFlightRecord) {
        let payload: [String: Any] = [
            "type": "checkIn",
            "id": record.id.uuidString,
            "kind": WatchCheckInKind.masturbation.rawValue,
            "timestamp": record.startDate.timeIntervalSince1970,
            "note": record.note
        ]
        watchSession?.transferUserInfo(payload)
        if watchSession?.isReachable == true {
            watchSession?.sendMessage(payload, replyHandler: nil)
        }
    }
}

private struct MotionFlightRecord: Codable, Identifiable, Sendable {
    let id: UUID
    let startDate: Date
    let duration: TimeInterval
    let count: Int
    let averageFrequency: Double
    let heartRate: Double?
    let targetMode: FlightTargetMode
    let targetSeconds: Int
    let targetCount: Int

    var durationText: String {
        formatDuration(duration)
    }

    var note: String {
        var parts = [
            "动感起飞",
            "\(count) 次",
            durationText,
            "频率 \(Int(averageFrequency.rounded())) 次/分",
        ]
        switch targetMode {
        case .time:
            parts.append("目标 \(formatDuration(TimeInterval(targetSeconds)))")
        case .count:
            parts.append("目标 \(targetCount) 次")
        }
        if let heartRate {
            parts.append("心率 \(Int(heartRate.rounded())) bpm")
        }
        return parts.joined(separator: " · ")
    }
}

private extension Array where Element == MotionFlightRecord {
    func sortedForRanking() -> [MotionFlightRecord] {
        sorted {
            if $0.count == $1.count {
                return $0.duration < $1.duration
            }
            return $0.count > $1.count
        }
    }
}

private func formatDuration(_ duration: TimeInterval) -> String {
    let total = Int(duration.rounded())
    return "\(total / 60):" + String(format: "%02d", total % 60)
}
