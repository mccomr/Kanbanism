import SwiftUI

@main
struct KanbanettiApp: App {
  @StateObject private var store = BoardStore()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(store)
        .preferredColorScheme(.dark)
    }
  }
}
