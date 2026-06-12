import SwiftUI
import UIKit

private struct ScreenWidthReader: UIViewRepresentable {
    let onChange: (CGFloat) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            reportWidth(from: view)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            reportWidth(from: uiView)
        }
    }

    private func reportWidth(from view: UIView) {
        let width = view.window?.windowScene?.screen.bounds.width ?? view.bounds.width
        guard width > 0 else { return }
        onChange(width)
    }
}

private struct AIChatBackground: View {
    var body: some View {
        ZStack {
            Color(hex: "070810")

            LinearGradient(
                colors: [
                    Color(hex: "070810"),
                    Color(hex: "08131A"),
                    Color(hex: "0B0816")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [.cyan.opacity(0.14), .cyan.opacity(0)],
                center: .center,
                startRadius: 0,
                endRadius: 210
            )
            .frame(width: 420, height: 420)
            .offset(x: -135, y: -260)

            RadialGradient(
                colors: [.purple.opacity(0.14), .purple.opacity(0)],
                center: .center,
                startRadius: 0,
                endRadius: 230
            )
            .frame(width: 460, height: 460)
            .offset(x: 155, y: 280)
        }
        .ignoresSafeArea()
    }
}

struct AIView: View {
    @Environment(CheckInStore.self) private var store
    @Environment(AISettings.self) private var settings
    @Environment(AIConversationStore.self) private var conversations
    let onReturnHome: () -> Void

    @State private var input = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingSettings = false
    @State private var showingHistory = false
    @State private var proposedCheckIns: [ProposedCheckIn] = []
    @State private var visibleScreenWidth: CGFloat?
    @State private var successKind: CheckInKind?
    @State private var pendingScoreAlert: ScoreAlert?
    @State private var scoreAlert: ScoreAlert?
    @AppStorage("discreetMode") private var discreetMode = true
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            AIChatBackground()

            GeometryReader { proxy in
                let contentWidth = min(proxy.size.width, visibleScreenWidth ?? proxy.size.width)

                VStack(spacing: 0) {
                    header
                    conversation
                    composer
                }
                .frame(width: contentWidth, height: proxy.size.height)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
                .clipped()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            successOverlay
        }
        .overlay {
            scoreCareOverlay
        }
        .background {
            ScreenWidthReader { width in
                guard visibleScreenWidth != width else { return }
                visibleScreenWidth = width
            }
        }
        .background(Color(hex: "070810").ignoresSafeArea())
        .sheet(isPresented: $showingSettings) {
            AISettingsView()
                .presentationDetents([.large])
                .presentationBackground(.ultraThinMaterial)
        }
        .sheet(isPresented: $showingHistory) {
            AIConversationHistoryView()
                .presentationDetents([.medium, .large])
                .presentationBackground(.ultraThinMaterial)
        }
        .alert("暂时无法连接 AI", isPresented: .constant(errorMessage != nil)) {
            Button("知道了") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .simultaneousGesture(edgeBackGesture)
    }

    private var edgeBackGesture: some Gesture {
        DragGesture(minimumDistance: 18, coordinateSpace: .global)
            .onEnded { value in
                let beganAtLeftEdge = value.startLocation.x <= 24
                let movedRight = value.translation.width >= 80
                let mostlyHorizontal = abs(value.translation.width) > abs(value.translation.height) * 1.4
                guard beganAtLeftEdge, movedRight, mostlyHorizontal else { return }
                isInputFocused = false
                onReturnHome()
            }
    }

    @ViewBuilder
    private var successOverlay: some View {
        if let successKind {
            CheckInSuccessView(kind: successKind) {
                finishSuccess()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)
            .zIndex(20)
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
            .transition(.opacity)
            .zIndex(21)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .center, spacing: 10) {
                Text("AI 助手")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .tracking(-0.7)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 5) {
                    headerIconButton(symbol: "house.fill", label: "回到今天") {
                        isInputFocused = false
                        onReturnHome()
                    }

                    headerIconButton(symbol: "plus", label: "新对话") {
                        newConversation()
                    }

                    headerIconButton(symbol: "clock.arrow.circlepath", label: "历史对话") {
                        showingHistory = true
                    }

                    headerIconButton(symbol: "gearshape.fill", label: "AI 设置") {
                        showingSettings = true
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
            }

            HStack(spacing: 9) {
                Capsule()
                    .fill(LinearGradient(colors: [.cyan, .purple], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 28, height: 3)
                Text("把趋势变成下一步行动")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.86)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 10)
    }

    private func headerIconButton(symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .contentShape(.circle)
                .glassEffect(.regular.interactive(), in: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if messages.isEmpty {
                        welcome
                    }
                    ForEach(messages) { message in
                        messageBubble(message)
                            .id(message.id)
                    }
                    if !proposedCheckIns.isEmpty {
                        proposedRecordsCard
                    }
                    if isLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("正在思考并整理回复…")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 18)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .simultaneousGesture(
                TapGesture().onEnded {
                    isInputFocused = false
                }
            )
            .onChange(of: messages.count) {
                guard let id = messages.last?.id else { return }
                withAnimation { proxy.scrollTo(id, anchor: .bottom) }
            }
        }
    }

    private var welcome: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 11) {
                Label("先从一句话开始", systemImage: "sparkles")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.cyan)
                Text("AI 可以总结趋势、给下一步建议，也可以根据你的自然语言生成待确认记录。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("默认只发送分数、天数和次数等聚合趋势；补记前会先让你确认。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func promptButton(_ title: String, prompt: String? = nil) -> some View {
        Button {
            send(prompt ?? title)
        } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glass)
        .disabled(isLoading)
    }

    @ViewBuilder
    private func messageBubble(_ message: AIMessage) -> some View {
        if message.role == .user {
            HStack {
                Spacer(minLength: 52)
                ViewThatFits(in: .horizontal) {
                    bubbleText(message, color: .cyan.opacity(0.2))
                        .fixedSize(horizontal: true, vertical: false)
                    bubbleText(message, color: .cyan.opacity(0.2))
                        .frame(maxWidth: 260, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity)
        } else {
            HStack {
                bubbleText(message, color: .white.opacity(0.07))
                    .frame(maxWidth: 310, alignment: .leading)
                Spacer(minLength: 52)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func bubbleText(_ message: AIMessage, color: Color) -> some View {
        Text(renderedContent(for: message))
            .font(.body)
            .lineSpacing(4)
            .textSelection(.enabled)
            .padding(14)
            .background(color, in: .rect(cornerRadius: 20))
    }

    private func renderedContent(for message: AIMessage) -> AttributedString {
        guard message.role == .assistant else {
            return AttributedString(message.content)
        }

        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace,
            failurePolicy: .returnPartiallyParsedIfPossible
        )
        let formattedContent = formattedAssistantContent(message.content)
        return (try? AttributedString(markdown: formattedContent, options: options))
            ?? AttributedString(formattedContent)
    }

    private func formattedAssistantContent(_ content: String) -> String {
        var formatted = content.replacingOccurrences(of: "\r\n", with: "\n")

        // Models occasionally return list items in one paragraph. Give each item
        // its own visually distinct paragraph while leaving normal prose intact.
        let inlineListBoundary = #"(?<!\n)[ \t]+(?=(?:[1-9]|1[0-9])[.、][ \t]*)"#
        formatted = formatted.replacingOccurrences(
            of: inlineListBoundary,
            with: "\n\n",
            options: .regularExpression
        )

        let inlineBulletBoundary = #"(?<!\n)[ \t]+(?=[\-•][ \t]+)"#
        formatted = formatted.replacingOccurrences(
            of: inlineBulletBoundary,
            with: "\n\n",
            options: .regularExpression
        )

        return formatted
    }

    private var composer: some View {
        VStack(spacing: 8) {
            HStack(spacing: 7) {
                promptButton("总结趋势", prompt: "请总结我的近 14 天趋势，并给一个简短判断。")
                promptButton("给建议", prompt: "请根据我的趋势给 3 条具体、低压力、今天就能做的建议。")
                promptButton("补记记录", prompt: "我想让你帮我补记记录。请告诉我可以直接怎么说，并提醒我你会先生成待确认记录。")
            }

            HStack(alignment: .bottom, spacing: 10) {
                TextField("问问趋势、触发场景或下一步…", text: $input, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 9)
                    .frame(height: 42)
                    .focused($isInputFocused)
                    .glassEffect(.regular, in: .rect(cornerRadius: 18))

                Button {
                    send()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .contentShape(.circle)
                        .glassEffect(
                            .regular.tint(.cyan.opacity(canSend ? 0.9 : 0.12)).interactive(),
                            in: .circle
                        )
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    private var canSend: Bool {
        !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    private var proposedRecordsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 13) {
                Label("AI 建议补记", systemImage: "square.and.pencil")
                    .font(.headline)
                    .foregroundStyle(.cyan)

                ForEach(proposedCheckIns) { item in
                    HStack(spacing: 10) {
                        Image(systemName: item.kind.displaySymbol(discreetMode: discreetMode))
                            .foregroundStyle(item.kind.displayTint(discreetMode: discreetMode))
                            .frame(width: 30, height: 30)
                            .background(item.kind.displayTint(discreetMode: discreetMode).opacity(0.14), in: .circle)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.kind.displayTitle(discreetMode: discreetMode, coded: true))
                                .font(.subheadline.weight(.semibold))
                            Text(item.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            if !item.note.isEmpty {
                                Text(item.note)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(2)
                            }
                        }
                        Spacer()
                    }
                }

                Text("确认后才会写入本机记录。")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Button {
                        proposedCheckIns.removeAll()
                    } label: {
                        Text("取消")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)

                    Button {
                        confirmProposedRecords()
                    } label: {
                        Text("确认记录")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.cyan)
                }
            }
        }
    }

    private func send(_ explicitPrompt: String? = nil) {
        let prompt = (explicitPrompt ?? input).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, !isLoading else { return }
        isInputFocused = false

        do {
            let configuration = try settings.snapshot()
            let context = store.aiTrendContext(
                includeDetailedCategories: settings.shareDetailedCategories,
                discreetMode: discreetMode
            )
            conversations.append(AIMessage(role: .user, content: prompt))
            input = ""
            isLoading = true

            Task {
                do {
                    let result = try await AIClient.send(
                        configuration: configuration,
                        messages: messages,
                        trendContext: context
                    )
                    conversations.append(AIMessage(role: .assistant, content: result.reply))
                    proposedCheckIns = result.proposedCheckIns
                } catch {
                    errorMessage = error.localizedDescription
                }
                isLoading = false
            }
        } catch {
            if case AIClientError.missingAPIKey = error {
                errorMessage = nil
            } else {
                errorMessage = error.localizedDescription
            }
            showingSettings = true
        }
    }

    private func confirmProposedRecords() {
        let count = proposedCheckIns.count
        var successKind: CheckInKind?
        var scoreAlert: ScoreAlert?

        for item in proposedCheckIns {
            let alert = store.add(item.kind, date: item.date, note: item.note)
            if successKind == nil {
                successKind = item.kind
            }
            if scoreAlert == nil {
                scoreAlert = alert
            }
        }
        proposedCheckIns.removeAll()
        conversations.append(AIMessage(role: .assistant, content: "已帮你写入 \(count) 条记录。你也可以在历史页长按删除或之后再调整。"))
        if let successKind {
            presentCheckInSuccess(kind: successKind, alert: scoreAlert)
        }
    }

    private func presentCheckInSuccess(kind: CheckInKind, alert: ScoreAlert?) {
        pendingScoreAlert = alert
        withAnimation(.easeIn(duration: 0.22)) {
            successKind = kind
        }
    }

    private func finishSuccess() {
        withAnimation(.easeOut(duration: 0.22)) {
            successKind = nil
        }
        guard let pendingScoreAlert else { return }
        self.pendingScoreAlert = nil
        withAnimation(.easeIn(duration: 0.25).delay(0.12)) {
            scoreAlert = pendingScoreAlert
        }
    }

    private var messages: [AIMessage] {
        conversations.activeMessages
    }

    private func newConversation() {
        guard !isLoading else { return }
        proposedCheckIns.removeAll()
        input = ""
        isInputFocused = false
        conversations.newConversation()
    }
}

struct AIConversationHistoryView: View {
    @Environment(AIConversationStore.self) private var conversations
    @Environment(\.dismiss) private var dismiss
    @State private var pendingDeletion: AIConversation?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(conversations.conversations) { conversation in
                        HStack(spacing: 10) {
                            Button {
                                conversations.select(conversation)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: conversation.id == conversations.activeConversationID ? "checkmark.circle.fill" : "message.fill")
                                        .foregroundStyle(conversation.id == conversations.activeConversationID ? .cyan : .secondary)
                                        .frame(width: 30)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(conversation.title)
                                            .font(.headline)
                                            .lineLimit(1)
                                        Text("\(conversation.messages.count) 条消息 · \(conversation.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .contentShape(.rect)
                            }
                            .buttonStyle(.plain)

                            Button(role: .destructive) {
                                pendingDeletion = conversation
                            } label: {
                                Image(systemName: "trash.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.red)
                                    .frame(width: 36, height: 36)
                                    .contentShape(.circle)
                            }
                            .buttonStyle(.glass)
                            .accessibilityLabel("删除对话")
                        }
                        .padding(14)
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
                        .contextMenu {
                            Button("删除对话", systemImage: "trash", role: .destructive) {
                                pendingDeletion = conversation
                            }
                        }
                    }
                }
                .padding(16)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("历史对话")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("新对话") {
                        conversations.newConversation()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .alert("删除这段对话？", isPresented: deletionBinding) {
                Button("取消", role: .cancel) {
                    pendingDeletion = nil
                }
                Button("删除", role: .destructive) {
                    if let pendingDeletion {
                        conversations.delete(pendingDeletion)
                    }
                    pendingDeletion = nil
                }
            } message: {
                Text("对话消息会从本机历史中移除，此操作无法撤销。")
            }
        }
    }

    private var deletionBinding: Binding<Bool> {
        Binding(
            get: { pendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    pendingDeletion = nil
                }
            }
        )
    }
}

struct AISettingsView: View {
    @Environment(AISettings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey = ""
    @State private var statusMessage: String?

    var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("连接 AI 服务", systemImage: "network")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.cyan)
                            Picker("服务商", selection: $settings.provider) {
                                ForEach(AIProvider.allCases) { provider in
                                    Text(provider.title).tag(provider)
                                }
                            }
                            .pickerStyle(.segmented)

                            field("Base URL", text: $settings.baseURL)
                            field("模型名称", text: $settings.model)

                            SecureField(settings.hasAPIKey ? "已保存，留空则保持不变" : "API Key", text: $apiKey)
                                .textContentType(.password)
                                .padding(13)
                                .background(.white.opacity(0.06), in: .rect(cornerRadius: 14))

                            Button {
                                saveKey()
                            } label: {
                                Label("安全保存 API Key", systemImage: "key.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.glassProminent)
                            .tint(.cyan)
                            .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                            if let statusMessage {
                                Text(statusMessage)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: $settings.shareDetailedCategories) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("发送详细分类统计")
                                    Text("开启后会发送各记录类型的次数；仍不会发送备注和精确时间。")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .tint(.purple)

                            Label("API Key 保存在本机 Keychain，不进入备份文件。每次提问会把当前聚合趋势发送给所选服务商。", systemImage: "lock.shield.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(16)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("AI 设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField(title, text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(13)
                .background(.white.opacity(0.06), in: .rect(cornerRadius: 14))
        }
    }

    private func saveKey() {
        do {
            try settings.saveAPIKey(apiKey)
            apiKey = ""
            statusMessage = "API Key 已安全保存到本机。"
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
