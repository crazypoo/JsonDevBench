import SwiftUI

@main
struct DevBenchApp: App {
    var body: some Scene {
        WindowGroup {
            AppShellView()
                .frame(minWidth: 980, minHeight: 600)
        }
        .defaultSize(width: 1200, height: 790)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
