import SwiftUI

@main
struct FlyMeApp: App {
    @State private var store = CheckInStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
                .preferredColorScheme(.dark)
        }
    }
}
