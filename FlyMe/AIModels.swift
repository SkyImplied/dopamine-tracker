import Foundation
import Observation
import Security

enum AIProvider: String, CaseIterable, Identifiable {
    case siliconFlow
    case deepSeek
    case custom

    var id: Self { self }

    var title: String {
        switch self {
        case .siliconFlow: "硅基流动"
        case .deepSeek: "DeepSeek"
        case .custom: "自定义兼容接口"
        }
    }

    var defaultBaseURL: String {
        switch self {
        case .siliconFlow: "https://api.siliconflow.cn/v1"
        case .deepSeek: "https://api.deepseek.com/v1"
        case .custom: ""
        }
    }

    var defaultModel: String {
        switch self {
        case .siliconFlow: "deepseek-ai/DeepSeek-V3.2"
        case .deepSeek: "deepseek-v4-flash"
        case .custom: ""
        }
    }
}

@Observable
final class AISettings {
    var provider: AIProvider {
        didSet {
            defaults.set(provider.rawValue, forKey: Keys.provider)
            baseURL = provider.defaultBaseURL
            model = provider.defaultModel
        }
    }
    var baseURL: String {
        didSet { defaults.set(baseURL, forKey: Keys.baseURL) }
    }
    var model: String {
        didSet { defaults.set(model, forKey: Keys.model) }
    }
    var shareDetailedCategories: Bool {
        didSet { defaults.set(shareDetailedCategories, forKey: Keys.shareDetailedCategories) }
    }

    private let defaults = UserDefaults.standard

    init() {
        let provider = AIProvider(rawValue: defaults.string(forKey: Keys.provider) ?? "") ?? .siliconFlow
        self.provider = provider
        baseURL = defaults.string(forKey: Keys.baseURL) ?? provider.defaultBaseURL
        model = defaults.string(forKey: Keys.model) ?? provider.defaultModel
        shareDetailedCategories = defaults.bool(forKey: Keys.shareDetailedCategories)
    }

    var hasAPIKey: Bool {
        KeychainStore.read() != nil
    }

    func saveAPIKey(_ value: String) throws {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            try KeychainStore.delete()
        } else {
            try KeychainStore.save(trimmed)
        }
    }

    func apiKey() -> String? {
        KeychainStore.read()
    }

    func snapshot() throws -> AIConfigurationSnapshot {
        guard let key = apiKey(), !key.isEmpty else { throw AIClientError.missingAPIKey }
        guard let url = Self.chatCompletionsURL(from: baseURL) else { throw AIClientError.invalidBaseURL }
        let trimmedModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedModel.isEmpty else { throw AIClientError.missingModel }
        return AIConfigurationSnapshot(url: url, model: trimmedModel, apiKey: key)
    }

    private static func chatCompletionsURL(from value: String) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasSuffix("/chat/completions") {
            return URL(string: trimmed)
        }
        return URL(string: trimmed + "/chat/completions")
    }

    private enum Keys {
        static let provider = "ai.provider"
        static let baseURL = "ai.baseURL"
        static let model = "ai.model"
        static let shareDetailedCategories = "ai.shareDetailedCategories"
    }
}

struct AIConfigurationSnapshot: Sendable {
    let url: URL
    let model: String
    let apiKey: String
}

struct AIMessage: Identifiable, Codable, Sendable {
    enum Role: String, Codable, Sendable {
        case user
        case assistant
    }

    let id: UUID
    let role: Role
    let content: String
    let createdAt: Date

    init(role: Role, content: String) {
        id = UUID()
        self.role = role
        self.content = content
        createdAt = .now
    }
}

struct AIConversation: Identifiable, Codable, Sendable {
    let id: UUID
    var title: String
    var messages: [AIMessage]
    var createdAt: Date
    var updatedAt: Date

    init(title: String = "新对话", messages: [AIMessage] = []) {
        id = UUID()
        self.title = title
        self.messages = messages
        createdAt = .now
        updatedAt = .now
    }
}

@Observable
final class AIConversationStore {
    var conversations: [AIConversation] = []
    var activeConversationID: UUID?

    private let conversationsKey = "ai.conversations.v1"
    private let activeIDKey = "ai.activeConversationID.v1"
    private let defaults = UserDefaults.standard

    init() {
        load()
        if conversations.isEmpty {
            newConversation()
        } else if activeConversation == nil {
            activeConversationID = conversations.first?.id
            save()
        }
    }

    var activeConversation: AIConversation? {
        guard let activeConversationID else { return nil }
        return conversations.first { $0.id == activeConversationID }
    }

    var activeMessages: [AIMessage] {
        activeConversation?.messages ?? []
    }

    @discardableResult
    func newConversation() -> UUID {
        if let activeConversation, activeConversation.messages.isEmpty {
            activeConversationID = activeConversation.id
            save()
            return activeConversation.id
        }
        let conversation = AIConversation()
        conversations.insert(conversation, at: 0)
        activeConversationID = conversation.id
        save()
        return conversation.id
    }

    func select(_ conversation: AIConversation) {
        activeConversationID = conversation.id
        defaults.set(conversation.id.uuidString, forKey: activeIDKey)
    }

    func append(_ message: AIMessage) {
        guard let index = activeIndex else { return }
        conversations[index].messages.append(message)
        conversations[index].updatedAt = .now
        if conversations[index].title == "新对话", message.role == .user {
            conversations[index].title = Self.title(from: message.content)
        }
        conversations.sort { $0.updatedAt > $1.updatedAt }
        save()
    }

    func replaceActiveMessages(_ messages: [AIMessage]) {
        guard let index = activeIndex else { return }
        conversations[index].messages = messages
        conversations[index].updatedAt = .now
        save()
    }

    func delete(_ conversation: AIConversation) {
        conversations.removeAll { $0.id == conversation.id }
        if conversations.isEmpty {
            newConversation()
        } else if activeConversationID == conversation.id {
            activeConversationID = conversations.first?.id
            save()
        } else {
            save()
        }
    }

    private var activeIndex: Int? {
        guard let activeConversationID else { return nil }
        return conversations.firstIndex { $0.id == activeConversationID }
    }

    private func save() {
        if let activeConversationID {
            defaults.set(activeConversationID.uuidString, forKey: activeIDKey)
        }
        guard let data = try? JSONEncoder().encode(conversations) else { return }
        defaults.set(data, forKey: conversationsKey)
    }

    private func load() {
        if let data = defaults.data(forKey: conversationsKey),
           let decoded = try? JSONDecoder().decode([AIConversation].self, from: data) {
            conversations = decoded.sorted { $0.updatedAt > $1.updatedAt }
        }
        if let id = defaults.string(forKey: activeIDKey).flatMap(UUID.init(uuidString:)) {
            activeConversationID = id
        }
    }

    private static func title(from content: String) -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "新对话" }
        return String(trimmed.prefix(18))
    }
}

struct ProposedCheckIn: Identifiable, Sendable {
    let id = UUID()
    let kind: CheckInKind
    let date: Date
    let note: String
}

struct AIAssistantResult: Sendable {
    let reply: String
    let proposedCheckIns: [ProposedCheckIn]
}

enum AIClientError: LocalizedError {
    case missingAPIKey
    case invalidBaseURL
    case missingModel
    case invalidResponse
    case server(String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: "请先在 AI 设置中填写 API Key。"
        case .invalidBaseURL: "API 地址无效，请检查 Base URL。"
        case .missingModel: "请填写模型名称。"
        case .invalidResponse: "AI 服务返回了无法识别的数据。"
        case .server(let message): message
        case .emptyResponse: "AI 没有返回内容，请稍后重试。"
        }
    }
}

struct AIClient {
    private struct RequestBody: Encodable {
        struct Message: Encodable {
            let role: String
            let content: String
        }

        let model: String
        let messages: [Message]
        let temperature: Double
    }

    private struct ResponseBody: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let content: String?
            }
            let message: Message
        }
        let choices: [Choice]
    }

    private struct ErrorBody: Decodable {
        struct Detail: Decodable {
            let message: String?
        }
        let error: Detail?
        let message: String?
    }

    private struct AssistantEnvelope: Decodable {
        struct Action: Decodable {
            let type: String
            let kind: String?
            let date: String?
            let note: String?
        }

        let reply: String
        let actions: [Action]?
    }

    static func send(
        configuration: AIConfigurationSnapshot,
        messages: [AIMessage],
        trendContext: String
    ) async throws -> AIAssistantResult {
        let now = ISO8601DateFormatter().string(from: .now)
        let system = """
        你是“清醒”App 中温和、务实的自我觉察助手。你会基于用户主动提供的聚合记录趋势回答。
        不羞辱、不诊断、不夸大因果，不把分数当成人的价值。给出简短、可执行、低压力的建议。
        当用户问“给建议”“我该怎么办”“下一步”时，请结合趋势给 2-4 条具体建议：触发场景、替代动作、复盘问题、今天最小目标。
        建议要像教练一样清楚，但语气温和；优先给用户可立即完成的小动作，而不是空泛鼓励。
        回复排版要清晰、适合手机阅读：不同主题使用短段落；分点回答时，每一点必须单独换行，使用“1. ”、“2. ”这样的编号；每点可用 **简短标题** 开头；不要把多个编号挤在同一段。
        如果用户出现自伤、自杀或紧急危险表达，优先建议立即联系当地紧急服务和可信任的人。

        你还可以帮助用户操作 App 的核心功能：解析自然语言并提出“补记记录”的建议。
        只有当用户明确要求记录、补记、添加发生过的事情时，才在 actions 里生成记录建议；用户一次说了多件事时，可以返回多条 add_checkin。
        用户只是想了解如何补记时，不要生成动作，先用 reply 给出 2-3 个自然语言示例。
        支持的记录类型 kind 只能是：
        - urge：欲望来袭
        - redirected：成功转移
        - masturbation：自慰
        - intimacy：房事
        - explicitContent：看黄
        - nocturnalEmission：遗精
        date 必须使用 ISO 8601 格式。当前时间是 \(now)，日期不明确时用当前日期并在 reply 里提醒用户确认。
        note 可以简短保留用户原话里的上下文，但不要编造细节。

        你的回复必须始终是纯 JSON，不要使用 Markdown 代码块，格式如下：
        {
          "reply": "给用户看的中文回复",
          "actions": [
            {"type": "add_checkin", "kind": "urge", "date": "2026-06-07T22:30:00+08:00", "note": "可选备注"}
          ]
        }
        没有动作时 actions 返回空数组。

        当前本地趋势摘要：
        \(trendContext)
        """
        let requestMessages = [RequestBody.Message(role: "system", content: system)]
            + messages.suffix(10).map { RequestBody.Message(role: $0.role.rawValue, content: $0.content) }
        let body = RequestBody(model: configuration.model, messages: requestMessages, temperature: 0.6)

        var request = URLRequest(url: configuration.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)
        request.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AIClientError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let decoded = try? JSONDecoder().decode(ErrorBody.self, from: data)
            let message = decoded?.error?.message ?? decoded?.message ?? "AI 服务请求失败（\(http.statusCode)）。"
            throw AIClientError.server(message)
        }

        guard let decoded = try? JSONDecoder().decode(ResponseBody.self, from: data),
              let content = decoded.choices.first?.message.content?.trimmingCharacters(in: .whitespacesAndNewlines),
              !content.isEmpty
        else { throw AIClientError.emptyResponse }
        return parseAssistantContent(content)
    }

    private static func parseAssistantContent(_ content: String) -> AIAssistantResult {
        let cleaned = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8),
              let envelope = try? JSONDecoder().decode(AssistantEnvelope.self, from: data)
        else {
            return AIAssistantResult(reply: content, proposedCheckIns: [])
        }

        let proposals = (envelope.actions ?? []).compactMap { action -> ProposedCheckIn? in
            guard action.type == "add_checkin",
                  let kindValue = action.kind,
                  let kind = CheckInKind(rawValue: kindValue),
                  let dateValue = action.date,
                  let date = parseDate(dateValue)
            else { return nil }
            return ProposedCheckIn(kind: kind, date: date, note: action.note ?? "")
        }
        return AIAssistantResult(reply: envelope.reply, proposedCheckIns: proposals)
    }

    private static func parseDate(_ value: String) -> Date? {
        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: value) {
            return date
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.timeZone = .current
        for format in ["yyyy-MM-dd HH:mm", "yyyy-MM-dd"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: value) {
                return date
            }
        }
        return nil
    }
}

private enum KeychainStore {
    private static let service = "com.skyimplied.FlyMe.ai"
    private static let account = "api-key"

    static func save(_ value: String) throws {
        try delete()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecValueData as String: Data(value.utf8)
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw AIClientError.server("无法安全保存 API Key。") }
    }

    static func read() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AIClientError.server("无法更新 API Key。")
        }
    }
}
