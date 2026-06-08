import SwiftUI

@main
struct FlyMeApp: App {
    @State private var store = CheckInStore()
    @State private var aiSettings = AISettings()
    @State private var aiConversations = AIConversationStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(aiSettings)
                .environment(aiConversations)
                .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
                .preferredColorScheme(.dark)
        }
    }
}
