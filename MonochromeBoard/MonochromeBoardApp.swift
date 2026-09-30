import SwiftUI

@main
struct MonochromeBoardApp: App {
  @StateObject private var store = BoardStore()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(store)
        .preferredColorScheme(.dark)
    }
  }
}
