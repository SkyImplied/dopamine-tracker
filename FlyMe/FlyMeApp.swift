import SwiftUI

@main
struct FlyMeApp: App {
    @State private var store = CheckInStore()
    @State private var aiSettings = AISettings()
    @State private var aiConversations = AIConversationStore()
    @State private var watchConnectivity: PhoneWatchConnectivity

    init() {
        let store = CheckInStore()
        _store = State(initialValue: store)
        _watchConnectivity = State(initialValue: PhoneWatchConnectivity(store: store))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(aiSettings)
                .environment(aiConversations)
                .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
                .preferredColorScheme(.dark)
                .onAppear {
                    watchConnectivity.syncSummary()
                }
        }
    }
}
