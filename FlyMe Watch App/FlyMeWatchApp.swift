import SwiftUI

@main
struct FlyMeWatchApp: App {
    @State private var store = WatchCheckInStore()

    var body: some Scene {
        WindowGroup {
            WatchHomeView(store: store)
                .preferredColorScheme(.dark)
        }
    }
}
