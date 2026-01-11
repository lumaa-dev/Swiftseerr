// Made by Lumaa

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var auths: [AuthInfo]

    @State private var onboarding: SeerSession.OnboardingSteps = .complete

    @State private var loading: Bool = false
    
    var body: some View {
        ZStack {
            if loading {
                Color.bgPurple
                    .ignoresSafeArea()

                ProgressView()
                    .progressViewStyle(.circular)
            } else {
                if self.onboarding != SeerSession.OnboardingSteps.complete {
                    OnboardingView(onboarding: $onboarding)
                } else if SeerSession.shared.authorization != nil {
                    Text("Tabs")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
