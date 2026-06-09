import Charts
import SwiftUI

enum CheckInMode: Identifiable {
    case now
    case past

    var id: Self { self }
}

struct RootView: View {
    @State private var selectedTab = 0
    @State private var showingAI = false
    @State private var checkInMode: CheckInMode?
    @State private var successKind: CheckInKind?
    @State private var pendingSuccessKind: CheckInKind?
    @State private var scoreAlert: ScoreAlert?
    @State private var pendingScoreAlert: ScoreAlert?

    var body: some View {
        ZStack {
            AuroraBackground()

            TabView(selection: $selectedTab) {
                DashboardView(
                    checkInMode: $checkInMode,
                    onOpenAI: openAI
                )
                    .tag(0)
                    .tabItem { Label("今天", systemImage: "circle.grid.2x2.fill") }

                InsightsView()
                    .tag(1)
                    .tabItem { Label("趋势", systemImage: "chart.xyaxis.line") }

                HistoryView(checkInMode: $checkInMode)
                    .tag(2)
                    .tabItem { Label("历史", systemImage: "calendar") }

                SettingsView()
                    .tag(3)
                    .tabItem { Label("设置", systemImage: "slider.horizontal.3") }
            }
            .tint(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            successOverlay
        }
        .overlay {
            scoreCareOverlay
        }
        .sheet(item: $checkInMode, onDismiss: {
            guard let pendingSuccessKind else { return }
            self.pendingSuccessKind = nil
            withAnimation(.easeIn(duration: 0.25)) {
                successKind = pendingSuccessKind
            }
        }) { mode in
            CheckInSheet(mode: mode) { kind, alert in
                pendingSuccessKind = kind
                pendingScoreAlert = alert
                checkInMode = nil
            }
                .presentationDetents([.large])
                .presentationBackground(.ultraThinMaterial)
        }
        .fullScreenCover(isPresented: $showingAI) {
            AIView(
                onReturnHome: closeAI
            )
        }
    }

    @ViewBuilder
    private var successOverlay: some View {
        if let successKind {
            CheckInSuccessView(kind: successKind) {
                finishSuccess()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .transition(.opacity)
            .zIndex(10)
        }
    }

    @ViewBuilder
    private var scoreCareOverlay: some View {
        if let scoreAlert, successKind == nil {
            ScoreCareView(alert: scoreAlert) {
                withAnimation(.easeOut(duration: 0.22)) {
                    self.scoreAlert = nil
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .transition(.opacity)
            .zIndex(11)
        }
    }

    private func openAI() {
        selectedTab = 0
        showingAI = true
    }

    private func closeAI() {
        selectedTab = 0
        showingAI = false
    }

    private func finishSuccess() {
        withAnimation(.easeOut(duration: 0.25)) {
            successKind = nil
        }
        guard let pendingScoreAlert else { return }
        self.pendingScoreAlert = nil
        withAnimation(.easeIn(duration: 0.3).delay(0.15)) {
            scoreAlert = pendingScoreAlert
        }
    }

    private func presentCheckInSuccess(kind: CheckInKind, alert: ScoreAlert?) {
        pendingScoreAlert = alert
        withAnimation(.easeIn(duration: 0.25)) {
            successKind = kind
        }
    }
}

struct DashboardView: View {
    @Environment(CheckInStore.self) private var store
    @Binding var checkInMode: CheckInMode?
    let onOpenAI: () -> Void
    @State private var appeared = false
    @State private var scrollOffset: CGFloat = 0
    @State private var showingScoreDetails = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    PageHeader(
                        title: greeting,
                        subtitle: "今天也把主动权留给自己"
                    )
                    hero
                    aiEntry
                    quickAction
                    recent
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 110)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
            }
            .scrollIndicators(.hidden)
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top
            } action: { _, newValue in
                scrollOffset = max(0, newValue)
            }
            .overlay(alignment: .top) {
                compactHeader
            }
            .background(.clear)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) { appeared = true }
            }
            .sheet(isPresented: $showingScoreDetails) {
                ScoreExplanationView()
                    .presentationDetents([.large])
                    .presentationBackground(.ultraThinMaterial)
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        return hour < 12 ? "早上好" : hour < 18 ? "下午好" : "晚上好"
    }

    private var hero: some View {
        GlassCard {
            VStack(spacing: 18) {
                HStack(spacing: 22) {
                    Button {
                        showingScoreDetails = true
                    } label: {
                        ScoreRing(score: store.score)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("查看自律指数计算方式")
                    VStack(alignment: .leading, spacing: 7) {
                        Text("此刻，保持清醒")
                            .font(.title3.weight(.semibold))
                        Text(store.encouragement)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Label(store.scoreBand.title, systemImage: store.scoreBand.symbol)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(store.scoreBand.tint)
                    }
                }

                HStack(spacing: 8) {
                    MetricPill(value: "\(store.stableDays) 天", label: "稳定节奏", symbol: "sparkles")
                    MetricPill(value: "\(store.redirectRate)%", label: "成功转移", symbol: "arrow.trianglehead.2.clockwise")
                }
            }
        }
    }

    private var compactHeaderProgress: CGFloat {
        min(max((scrollOffset - 48) / 70, 0), 1)
    }

    private var compactHeader: some View {
        Button {
            showingScoreDetails = true
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(greeting)
                        .font(.headline)
                    Text("今天也把主动权留给自己")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(store.score)")
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .contentTransition(.numericText())
                Text("自律指数")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .frame(height: 58)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 22))
            .padding(.horizontal, 16)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .opacity(compactHeaderProgress)
        .offset(y: -12 * (1 - compactHeaderProgress))
        .scaleEffect(0.97 + 0.03 * compactHeaderProgress)
        .allowsHitTesting(compactHeaderProgress > 0.9)
        .accessibilityLabel("查看自律指数详情")
        .accessibilityHint("打开具体评分和计算方式")
    }

    private var aiEntry: some View {
        Button(action: onOpenAI) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(.cyan.opacity(0.16))
                        .frame(width: 48, height: 48)
                    Image(systemName: "sparkles")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.cyan)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("AI 助手")
                        .font(.headline)
                    Text("总结趋势、给建议，也能帮你补记")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .glassEffect(.regular.tint(.cyan.opacity(0.08)).interactive(), in: .rect(cornerRadius: 24))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("打开 AI 助手")
    }

    private var quickAction: some View {
        Button {
            checkInMode = .now
        } label: {
            HStack {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.14))
                        .frame(width: 48, height: 48)
                    Image(systemName: "plus")
                        .font(.title3.weight(.semibold))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("记录此刻").font(.headline)
                    Text("诚实记录，不做评判").font(.caption).foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.65))
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .foregroundStyle(.white)
            .background(
                LinearGradient(colors: [.purple.opacity(0.72), .cyan.opacity(0.48)], startPoint: .leading, endPoint: .trailing),
                in: .rect(cornerRadius: 24)
            )
            .shadow(color: .purple.opacity(0.3), radius: 20, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var recent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最近记录").font(.title3.weight(.semibold))
                Spacer()
                Text("仅存于本机").font(.caption).foregroundStyle(.secondary)
            }

            if store.recentEntries.isEmpty {
                ContentUnavailableView("还没有记录", systemImage: "leaf", description: Text("从一次诚实的记录开始。"))
                    .frame(height: 220)
                    .glassEffect(.regular, in: .rect(cornerRadius: 28))
            } else {
                GlassCard {
                    VStack(spacing: 0) {
                        ForEach(store.recentEntries.prefix(6)) { entry in
                            EntryRow(entry: entry)
                            if entry.id != store.recentEntries.prefix(6).last?.id {
                                Divider().opacity(0.16).padding(.leading, 48)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct EntryRow: View {
    @Environment(CheckInStore.self) private var store
    @AppStorage("discreetMode") private var discreetMode = true
    let entry: CheckIn

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: displaySymbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(displayTint)
                .frame(width: 36, height: 36)
                .background(displayTint.opacity(0.14), in: .circle)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.kind.displayTitle(discreetMode: discreetMode))
                    .font(.subheadline.weight(.medium))
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2).foregroundStyle(.secondary)
                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
        }
        .padding(.vertical, 10)
        .contextMenu {
            Button("删除记录", systemImage: "trash", role: .destructive) {
                store.delete(entry)
            }
        }
    }

    private var displaySymbol: String {
        entry.kind.displaySymbol(discreetMode: discreetMode)
    }

    private var displayTint: Color {
        entry.kind.displayTint(discreetMode: discreetMode)
    }

}

struct ScoreExplanationView: View {
    @Environment(CheckInStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @AppStorage("discreetMode") private var discreetMode = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(alignment: .center, spacing: 18) {
                                ScoreRing(score: store.score)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("你的当前指数")
                                        .font(.title3.weight(.semibold))
                                    Text("\(store.score) / 100")
                                        .font(.headline.monospacedDigit())
                                        .foregroundStyle(.cyan)
                                }
                            }
                            Text("用于观察近 14 天的自律节奏，不是对你的评价，也不代表医学结论。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("当前分数如何得出").font(.title3.weight(.semibold))
                            formulaRow("基础分", formatted(store.baseScore), .cyan)
                            formulaRow("近 14 天动态影响", signed(store.recentAdjustment), store.recentAdjustment >= 0 ? .mint : .orange)
                            formulaRow("稳定节奏奖励", "+\(formatted(store.stableBonus))", .purple)
                            Divider().opacity(0.18)
                            formulaRow("最终结果", "\(store.score)", .white)
                            Text("越近的记录影响越大；同日重复负向记录会逐步增加影响；低谷期成功转移会获得额外恢复。结果限制在 0 至 100 分。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 13) {
                            Text("分数区间").font(.title3.weight(.semibold))
                            ForEach(ScoreBand.allCases) { band in
                                HStack(spacing: 10) {
                                    Image(systemName: band.symbol)
                                        .foregroundStyle(band.tint)
                                        .frame(width: 28)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(band.title)
                                            .font(.subheadline.weight(.semibold))
                                        Text(band.rangeLabel)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if band == store.scoreBand {
                                        Text("当前")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(band.tint)
                                    }
                                }
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 13) {
                            Text("每次记录的影响").font(.title3.weight(.semibold))
                            weightRow(.redirected)
                            weightRow(.urge)
                            weightRow(.masturbation)
                            weightRow(.explicitContent)
                            weightRow(.intimacy)
                            weightRow(.nocturnalEmission)
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("自律指数")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func formulaRow(_ title: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(color)
        }
    }

    private func weightRow(_ kind: CheckInKind) -> some View {
        HStack(spacing: 10) {
            Image(systemName: kind.displaySymbol(discreetMode: discreetMode))
                .foregroundStyle(kind.displayTint(discreetMode: discreetMode))
                .frame(width: 28)
            Text(kind.displayTitle(discreetMode: discreetMode, coded: true))
            Spacer()
            Text(kind.scoreWeight == 0 ? "不影响" : signed(kind.scoreWeight))
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(kind.scoreWeight > 0 ? .mint : kind.scoreWeight < 0 ? .orange : .secondary)
        }
    }

    private func signed(_ value: Double) -> String {
        value >= 0 ? "+\(formatted(value))" : formatted(value)
    }

    private func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(value.rounded() == value ? 0 : 1)))
    }
}

struct CheckInSheet: View {
    @Environment(CheckInStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var saved = false
    @State private var selectedDate = Date.now
    @AppStorage("discreetMode") private var discreetMode = true
    @AppStorage("haptics") private var haptics = true
    let mode: CheckInMode
    let onRecorded: (CheckInKind, ScoreAlert?) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("发生了什么？")
                            .font(.largeTitle.weight(.semibold))
                        Text(mode == .now ? "记录此刻，不做评判。" : "补记过去，完善你的记录。")
                            .foregroundStyle(.secondary)
                    }

                    if mode == .past {
                        DatePicker(
                            "记录时间",
                            selection: $selectedDate,
                            in: ...Date.now,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .font(.subheadline.weight(.medium))
                        .padding(14)
                        .glassEffect(.regular, in: .rect(cornerRadius: 20))
                    }

                    LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                        ForEach(CheckInKind.allCases) { kind in
                            kindButton(kind)
                        }
                    }

                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .sensoryFeedback(.success, trigger: saved) { _, _ in haptics }
        }
    }

    private func kindButton(_ kind: CheckInKind) -> some View {
        Button {
            let alert = store.add(kind, date: mode == .now ? .now : selectedDate)
            saved.toggle()
            onRecorded(kind, alert)
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: kind.displaySymbol(discreetMode: discreetMode))
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(kind.displayTint(discreetMode: discreetMode))
                    .frame(width: 44, height: 44)
                    .background(kind.displayTint(discreetMode: discreetMode).opacity(0.14), in: .circle)
                VStack(alignment: .leading, spacing: 3) {
                    Text(kind.displayTitle(discreetMode: discreetMode, coded: true)).font(.headline)
                    Text(kind.displaySubtitle(discreetMode: discreetMode)).font(.caption).foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 148, alignment: .leading)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
        }
        .buttonStyle(.plain)
    }
}

struct InsightsView: View {
    @Environment(CheckInStore.self) private var store
    @AppStorage("discreetMode") private var discreetMode = true
    @State private var range: TrendRange = .week
    @State private var selectedMetrics: Set<TrendMetric> = [.masturbation, .intimacy]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    PageHeader(
                        title: "趋势",
                        subtitle: "理解规律，比追逐完美更重要"
                    )

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("查看范围")
                                .font(.headline)
                            Picker("时间范围", selection: $range) {
                                ForEach(TrendRange.allCases) { item in
                                    Text(item.rawValue).tag(item)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 20) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("记录次数趋势")
                                    .font(.title3.weight(.semibold))
                                Text("选择需要比较的记录类型，纵轴直接显示\(range.bucketLabel)真实次数。")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 9) {
                                ForEach(TrendMetric.allCases) { metric in
                                    metricToggle(metric)
                                }
                            }

                            TrendChartView(points: trendPoints, range: range, discreetMode: discreetMode)
                                .id(range)
                                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                                .animation(.spring(duration: 0.65, bounce: 0.14), value: range)
                                .animation(.spring(duration: 0.55, bounce: 0.12), value: selectedMetrics)

                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(.cyan)
                                Text("曲线高度就是实际次数，指标标签显示当前范围内的累计次数。")
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("自律得分趋势")
                                    .font(.title3.weight(.semibold))
                                Text("独立使用百分制展示，不与记录次数混合。")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            ScoreTrendChartView(points: scoreTrendPoints, range: range)
                                .id(range)
                                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                                .animation(.spring(duration: 0.65, bounce: 0.14), value: range)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("本周洞察").font(.title3.weight(.semibold))
                            insightRow("稳定节奏", "\(store.stableDays) 天", "sparkles", .cyan)
                            insightRow("冲动转移率", "\(store.redirectRate)%", "wind", .mint)
                            insightRow("本周记录", "\(store.weekly.reduce(0) { $0 + $1.count }) 次", "square.and.pencil", .purple)
                        }
                    }

                    Text(discreetMode ? "分数用于观察趋势，不代表医学或心理诊断。私密中性记录不会降低分数。" : "分数用于观察趋势，不代表医学或心理诊断。亲密行为与遗精不会降低分数。")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 20)
                }
                .padding(16)
                .padding(.bottom, 110)
            }
            .scrollIndicators(.hidden)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var trendPoints: [TrendPoint] {
        store.trendPoints(range: range, metrics: selectedMetrics)
    }

    private var scoreTrendPoints: [ScoreTrendPoint] {
        store.scoreTrendPoints(range: range)
    }

    private func metricToggle(_ metric: TrendMetric) -> some View {
        let selected = selectedMetrics.contains(metric)
        return Button {
            withAnimation(.spring(duration: 0.5, bounce: 0.18)) {
                if selected {
                    guard selectedMetrics.count > 1 else { return }
                    selectedMetrics.remove(metric)
                } else {
                    selectedMetrics.insert(metric)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: selected ? "checkmark.circle.fill" : metric.displaySymbol(discreetMode: discreetMode))
                    .foregroundStyle(metric.displayTint(discreetMode: discreetMode))
                    .contentTransition(.symbolEffect(.replace))
                VStack(alignment: .leading, spacing: 1) {
                    Text(metric.displayTitle(discreetMode: discreetMode))
                        .font(.caption.weight(.semibold))
                    Text("累计 \(store.trendTotal(for: metric, range: range)) 次")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .frame(height: 48)
            .background(metric.displayTint(discreetMode: discreetMode).opacity(selected ? 0.14 : 0.035), in: .rect(cornerRadius: 15))
            .overlay {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(metric.displayTint(discreetMode: discreetMode).opacity(selected ? 0.45 : 0.08), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(selected ? "取消显示" : "显示")\(metric.displayTitle(discreetMode: discreetMode))趋势")
    }

    private func insightRow(_ title: String, _ value: String, _ symbol: String, _ color: Color) -> some View {
        HStack {
            Image(systemName: symbol)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.14), in: .circle)
            Text(title)
            Spacer()
            Text(value).font(.headline.monospacedDigit())
        }
        .padding(.vertical, 4)
    }
}

private struct TrendChartView: View {
    let points: [TrendPoint]
    let range: TrendRange
    let discreetMode: Bool

    var body: some View {
        Chart(points) { point in
            LineMark(
                x: .value("日期", point.date),
                y: .value("次数", point.value),
                series: .value("指标", point.metric.displayTitle(discreetMode: discreetMode))
            )
            .foregroundStyle(point.metric.displayTint(discreetMode: discreetMode))
            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            .interpolationMethod(.catmullRom)

            PointMark(
                x: .value("日期", point.date),
                y: .value("次数", point.value)
            )
            .foregroundStyle(point.metric.displayTint(discreetMode: discreetMode))
            .symbolSize(range == .year ? 12 : 24)
        }
        .chartYAxis {
            AxisMarks(position: .leading) {
                AxisGridLine().foregroundStyle(.white.opacity(0.08))
                AxisValueLabel()
            }
        }
        .chartLegend(.hidden)
        .frame(height: 250)
    }
}

private struct ScoreTrendChartView: View {
    let points: [ScoreTrendPoint]
    let range: TrendRange

    var body: some View {
        Chart(points) { point in
            AreaMark(
                x: .value("日期", point.date),
                y: .value("得分", point.score)
            )
            .foregroundStyle(
                LinearGradient(colors: [.cyan.opacity(0.28), .purple.opacity(0.02)], startPoint: .top, endPoint: .bottom)
            )

            LineMark(
                x: .value("日期", point.date),
                y: .value("得分", point.score)
            )
            .foregroundStyle(.cyan)
            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .interpolationMethod(.catmullRom)

            PointMark(
                x: .value("日期", point.date),
                y: .value("得分", point.score)
            )
            .foregroundStyle(.white)
            .symbolSize(range == .year ? 14 : 26)
        }
        .chartYScale(domain: 25...100)
        .chartYAxis {
            AxisMarks(values: [40, 60, 80, 100]) {
                AxisGridLine().foregroundStyle(.white.opacity(0.08))
                AxisValueLabel()
            }
        }
        .frame(height: 230)
    }
}

struct HistoryView: View {
    @Environment(CheckInStore.self) private var store
    @Binding var checkInMode: CheckInMode?
    @AppStorage("discreetMode") private var discreetMode = true
    @State private var selectedDate = Date.now
    @State private var selectedHeatmapKind = CheckInKind.masturbation
    @State private var showingRecordManager = false

    private let heatmapColumns = Array(repeating: GridItem(.flexible(), spacing: 7), count: 7)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    PageHeader(
                        title: "历史",
                        subtitle: "按日期回看过去的记录"
                    ) {
                        HStack(spacing: 8) {
                            Button {
                                showingRecordManager = true
                            } label: {
                                Image(systemName: "checklist")
                                    .font(.headline)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.glass)
                            .accessibilityLabel("管理所有历史记录")

                            Button {
                                checkInMode = .past
                            } label: {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.headline)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.glass)
                            .accessibilityLabel("补记过去记录")
                        }
                    }

                    summary
                    heatmap
                    dayBrowser
                    distribution
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 110)
            }
            .scrollIndicators(.hidden)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingRecordManager) {
                RecordManagerView()
                    .presentationDetents([.large])
                    .presentationBackground(.ultraThinMaterial)
            }
        }
    }

    private var summary: some View {
        HStack(spacing: 10) {
            historyMetric("\(store.entries.count)", "全部记录", "tray.full.fill", .purple)
            historyMetric("\(store.recordedDays)", "记录天数", "calendar", .cyan)
            historyMetric("\(store.redirectRate)%", "转移率", "wind", .mint)
        }
    }

    private func historyMetric(_ value: String, _ label: String, _ symbol: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.weight(.semibold).monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
    }

    private var heatmap: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("最近 35 天 · \(heatmapMetricTitle)").font(.title3.weight(.semibold))
                    Text("选择一个指标，查看它每天出现的次数。")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(CheckInKind.allCases) { kind in
                            Button {
                                withAnimation(.spring(duration: 0.4, bounce: 0.18)) {
                                    selectedHeatmapKind = kind
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: heatmapChipSymbol(for: kind))
                                    Text(heatmapChipTitle(for: kind))
                                }
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(selectedHeatmapKind == kind ? .white : .secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(
                                    kind.tint.opacity(selectedHeatmapKind == kind ? 0.3 : 0.06),
                                    in: .capsule
                                )
                                .overlay {
                                    Capsule()
                                        .stroke(kind.tint.opacity(selectedHeatmapKind == kind ? 0.7 : 0.12))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .scrollIndicators(.hidden)

                HStack {
                    Text(heatmapDateRange)
                    Spacer()
                    Label("从左到右，再到下一行", systemImage: "arrow.turn.down.right")
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)

                LazyVGrid(columns: heatmapColumns, spacing: 7) {
                    ForEach(Array(heatmapDays.prefix(7))) { day in
                        Text(day.date.formatted(.dateTime.weekday(.narrow).locale(Locale(identifier: "zh_CN"))))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                LazyVGrid(columns: heatmapColumns, spacing: 7) {
                    ForEach(heatmapDays) { day in
                        RoundedRectangle(cornerRadius: 7)
                            .fill(heatColor(day.count))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                if Calendar.current.isDateInToday(day.date) {
                                    RoundedRectangle(cornerRadius: 7)
                                        .stroke(.white.opacity(0.8), lineWidth: 1)
                                }
                            }
                            .overlay {
                                Text(day.date.formatted(.dateTime.day()))
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundStyle(day.count > 0 ? .white : .secondary.opacity(0.75))
                            }
                            .accessibilityLabel("\(day.date.formatted(date: .abbreviated, time: .omitted))，\(heatmapMetricTitle) \(day.count) 次")
                    }
                }

                HStack(spacing: 12) {
                    heatLegend(0, "无记录")
                    heatLegend(1, "1 次")
                    heatLegend(2, "2 次")
                    heatLegend(3, "3 次及以上")
                }
            }
        }
    }

    private func heatLegend(_ count: Int, _ label: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 4)
                .fill(heatColor(count))
                .frame(width: 13, height: 13)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
    }

    private func heatColor(_ count: Int) -> Color {
        switch count {
        case 0: .white.opacity(0.055)
        case 1: selectedHeatmapKind.displayTint(discreetMode: discreetMode).opacity(0.32)
        case 2: selectedHeatmapKind.displayTint(discreetMode: discreetMode).opacity(0.58)
        default: selectedHeatmapKind.displayTint(discreetMode: discreetMode).opacity(0.9)
        }
    }

    private var heatmapDays: [DaySummary] {
        store.last35Days(for: selectedHeatmapKind)
    }

    private var heatmapMetricTitle: String {
        selectedHeatmapKind.displayTitle(discreetMode: discreetMode)
    }

    private func heatmapChipTitle(for kind: CheckInKind) -> String {
        kind.displayTitle(discreetMode: discreetMode, coded: true)
    }

    private func heatmapChipSymbol(for kind: CheckInKind) -> String {
        kind.displaySymbol(discreetMode: discreetMode)
    }

    private var heatmapDateRange: String {
        guard let first = heatmapDays.first?.date, let last = heatmapDays.last?.date else { return "" }
        return "\(first.formatted(.dateTime.month().day())) → \(last.formatted(.dateTime.month().day()))"
    }

    private var distribution: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("记录类型分布").font(.title3.weight(.semibold))

                if store.kindCounts.isEmpty {
                    Text("开始记录后，这里会出现类型统计。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Chart(distributionItems) { item in
                        BarMark(
                            x: .value("次数", item.count),
                            y: .value("类型", item.title)
                        )
                        .foregroundStyle(item.color.gradient)
                        .cornerRadius(6)
                        .annotation(position: .trailing) {
                            Text("\(item.count)")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .chartXAxis(.hidden)
                    .frame(height: CGFloat(max(150, store.kindCounts.count * 38)))
                }
            }
        }
    }

    private var dayBrowser: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("按日期查看").font(.title3.weight(.semibold))
                Spacer()
                Button("今天") {
                    withAnimation(.spring(duration: 0.4)) {
                        selectedDate = .now
                    }
                }
                .font(.caption.weight(.semibold))
                .buttonStyle(.glass)
            }

            DatePicker(
                "选择日期",
                selection: $selectedDate,
                in: ...Date.now,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(.cyan)
            .padding(12)
            .glassEffect(.regular, in: .rect(cornerRadius: 28))

            GlassCard {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedDate.formatted(.dateTime.month(.wide).day().weekday(.wide)))
                        .font(.headline)
                        .padding(.bottom, 8)

                    if selectedDayEntries.isEmpty {
                        HStack(spacing: 12) {
                            Image(systemName: "moon.zzz")
                                .foregroundStyle(.cyan)
                            Text("这一天没有记录")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 18)
                    } else {
                        ForEach(selectedDayEntries) { entry in
                            EntryRow(entry: entry)
                            if entry.id != selectedDayEntries.last?.id {
                                Divider().opacity(0.16).padding(.leading, 48)
                            }
                        }
                    }
                }
            }
        }
    }

    private var selectedDayEntries: [CheckIn] {
        store.entries.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    private var distributionItems: [HistoryDistributionItem] {
        if discreetMode {
            let visible = store.kindCounts
                .filter { !$0.kind.isSensitive }
                .map { HistoryDistributionItem(title: $0.kind.displayTitle(discreetMode: discreetMode, coded: true), count: $0.count, color: $0.kind.displayTint(discreetMode: discreetMode)) }
            let privateCount = store.kindCounts
                .filter { $0.kind.isSensitive }
                .reduce(0) { $0 + $1.count }
            return privateCount > 0
                ? visible + [HistoryDistributionItem(title: "私密记录", count: privateCount, color: .purple)]
                : visible
        }
        return store.kindCounts.map {
            HistoryDistributionItem(title: $0.kind.displayTitle(discreetMode: discreetMode, coded: true), count: $0.count, color: $0.kind.displayTint(discreetMode: discreetMode))
        }
    }
}

private struct HistoryDistributionItem: Identifiable {
    let id = UUID()
    let title: String
    let count: Int
    let color: Color
}

private struct RecordManagerView: View {
    @Environment(CheckInStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @AppStorage("discreetMode") private var discreetMode = true
    @State private var selectedIDs: Set<UUID> = []
    @State private var confirmingDeletion = false

    var body: some View {
        NavigationStack {
            Group {
                if store.entries.isEmpty {
                    ContentUnavailableView(
                        "暂无历史记录",
                        systemImage: "tray",
                        description: Text("完成记录后，可以在这里集中管理。")
                    )
                } else {
                    List {
                        Section {
                            ForEach(store.entries) { entry in
                                Button {
                                    toggle(entry.id)
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: selectedIDs.contains(entry.id) ? "checkmark.circle.fill" : "circle")
                                            .font(.title3)
                                            .foregroundStyle(selectedIDs.contains(entry.id) ? entry.kind.tint : .secondary)

                                        Image(systemName: displaySymbol(for: entry))
                                            .foregroundStyle(displayTint(for: entry))
                                            .frame(width: 30)

                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(displayTitle(for: entry))
                                                .font(.subheadline.weight(.medium))
                                            Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()
                                    }
                                    .contentShape(.rect)
                                }
                                .buttonStyle(.plain)
                            }
                        } header: {
                            Text("共 \(store.entries.count) 条记录")
                        } footer: {
                            Text("选择记录后，可一次删除多条。删除无法撤销。")
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("管理历史记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("完成") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(allSelected ? "取消全选" : "全选") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedIDs = allSelected ? [] : Set(store.entries.map(\.id))
                        }
                    }
                    .disabled(store.entries.isEmpty)
                }
                ToolbarItem(placement: .bottomBar) {
                    Button(role: .destructive) {
                        confirmingDeletion = true
                    } label: {
                        Label(
                            selectedIDs.isEmpty ? "选择要删除的记录" : "删除已选 \(selectedIDs.count) 条记录",
                            systemImage: "trash.fill"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.red)
                    .disabled(selectedIDs.isEmpty)
                }
            }
            .alert("删除已选记录？", isPresented: $confirmingDeletion) {
                Button("取消", role: .cancel) {}
                Button("删除 \(selectedIDs.count) 条", role: .destructive) {
                    store.delete(ids: selectedIDs)
                    selectedIDs.removeAll()
                }
            } message: {
                Text("这些记录将被永久删除，此操作无法撤销。")
            }
        }
    }

    private var allSelected: Bool {
        !store.entries.isEmpty && selectedIDs.count == store.entries.count
    }

    private func toggle(_ id: UUID) {
        withAnimation(.easeInOut(duration: 0.18)) {
            if selectedIDs.contains(id) {
                selectedIDs.remove(id)
            } else {
                selectedIDs.insert(id)
            }
        }
    }

    private func displayTitle(for entry: CheckIn) -> String {
        entry.kind.displayTitle(discreetMode: discreetMode)
    }

    private func displaySymbol(for entry: CheckIn) -> String {
        entry.kind.displaySymbol(discreetMode: discreetMode)
    }

    private func displayTint(for entry: CheckIn) -> Color {
        entry.kind.displayTint(discreetMode: discreetMode)
    }
}

struct SettingsView: View {
    @Environment(CheckInStore.self) private var store
    @AppStorage("discreetMode") private var discreetMode = true
    @AppStorage("haptics") private var haptics = true
    @AppStorage("soundEffects") private var soundEffects = true
    @State private var exportingBackup = false
    @State private var importingBackup = false
    @State private var backupMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    PageHeader(
                        title: "设置",
                        subtitle: "你的记录，只属于你"
                    )

                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Label("隐私优先", systemImage: "lock.shield.fill")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.mint)
                            Text("记录默认仅保存在这台设备上。你可以手动备份到私人 iCloud Drive，应用不会建立账号或上传其他数据。")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("iCloud Drive 备份", systemImage: "icloud.fill")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.cyan)
                            Text("备份文件由你选择保存位置。选择 iCloud Drive 后，可以在重新安装或其他设备上恢复。")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 10) {
                                Button {
                                    exportingBackup = true
                                } label: {
                                    Label("备份记录", systemImage: "arrow.up.doc.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.glassProminent)
                                .tint(.cyan)

                                Button {
                                    importingBackup = true
                                } label: {
                                    Label("恢复备份", systemImage: "arrow.down.doc.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.glass)
                            }

                            if let backupMessage {
                                Text(backupMessage)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    GlassCard {
                        VStack(spacing: 0) {
                            Toggle(isOn: $discreetMode) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Label("低调显示", systemImage: "eye.slash")
                            Text("隐藏首页、记录、历史、统计、AI 上下文和成功反馈中的敏感名称")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .tint(.purple)
                            .padding(.vertical, 12)
                            Divider().opacity(0.16)
                            Toggle(isOn: $haptics) {
                                Label("触感反馈", systemImage: "hand.tap")
                            }
                            .tint(.cyan)
                            .padding(.vertical, 12)
                            Divider().opacity(0.16)
                            Toggle(isOn: $soundEffects) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Label("成功音效", systemImage: "speaker.wave.2")
                                    Text("记录成功时随全屏动效播放轻柔提示音")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .tint(.mint)
                            .padding(.vertical, 12)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("关于评分").font(.headline)
                            Text(discreetMode ? "综合指数关注近 14 天规律，并根据时间远近、同日重复情况和成功转移动态调整。私密中性记录不会降低评分。" : "综合指数关注近 14 天规律，并根据时间远近、同日重复情况和成功转移动态调整。房事与遗精被视为中性记录，不会降低评分。")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(16)
            }
            .scrollIndicators(.hidden)
            .toolbar(.hidden, for: .navigationBar)
            .fileExporter(
                isPresented: $exportingBackup,
                document: store.backupDocument(),
                contentType: .json,
                defaultFilename: "清醒记录备份"
            ) { result in
                backupMessage = result.isSuccess ? "备份已保存" : "未能保存备份"
            }
            .fileImporter(isPresented: $importingBackup, allowedContentTypes: [.json]) { result in
                do {
                    let url = try result.get()
                    guard url.startAccessingSecurityScopedResource() else {
                        backupMessage = "无法读取所选备份"
                        return
                    }
                    defer { url.stopAccessingSecurityScopedResource() }
                    try store.restoreBackup(from: Data(contentsOf: url))
                    backupMessage = "备份已恢复并与本机记录合并"
                } catch {
                    backupMessage = "备份文件无法读取"
                }
            }
        }
    }
}

private extension Result {
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}
