import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Invarn fixture: ios-spm")
                .font(.headline)
            Text("If you see this, the build is wired.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

/// Trivial computation under test — exists so the unit test target has
/// something to exercise without needing access to private SwiftUI APIs.
enum Greeter {
    static func greet(_ name: String) -> String {
        "Hello, \(name)!"
    }
}
