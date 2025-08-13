// Made by Lumaa

import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Button {
                UserDefaults.standard.set(false, forKey: "onboarded")
                UserDefaults.standard.set(nil, forKey: "auth")

                Task {
                    defer {
                        SeerSession.shared.auth = .init()
                        SeerSession.shared.authorization = nil
                    }

                    _ = try? await SeerSession.shared.raw(Login.logout)
                }
            } label: {
                Text(String("[TEMP] reset onboarding"))
                    .foregroundStyle(Color.red)
            }
        }
        .navigationTitle(Text("settings"))
        .scrollContentBackground(.hidden)
        .background {
            Color.bgPurple.ignoresSafeArea()
        }
    }
}

#Preview {
    SettingsView()
}
