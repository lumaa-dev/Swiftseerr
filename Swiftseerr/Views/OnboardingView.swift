// Made by Lumaa

import SwiftUI

struct OnboardingView: View {
    @Binding var onboarding: SeerSession.OnboardingSteps

    @State private var seerrUrl: String = ""
    @State private var isSeerr: Bool = false

    @State private var selection: Bool = false

    @State private var username: String = ""
    @State private var password: String = ""

    @State private var onboardingBusy: Bool = false

    private var isStepCompleted: Bool {
        switch self.onboarding {
            case .welcome:
                return true
            case .url:
                return !seerrUrl.isEmpty
            case .provider:
                return self.selection
            case .login:
                return !self.username.isEmpty && !self.password.isEmpty
            default:
                return false
        }
    }

    var body: some View {
        VStack {
            Text(onboarding.title)
                .font(.title.bold())
                .lineLimit(1)
                .contentTransition(.numericText(countsDown: true))

            Text(onboarding.description)
                .font(.callout)
                .lineLimit(3, reservesSpace: true)
                .padding(.vertical)

            Spacer()

            self.stepView

            Spacer()

            Button {
                let allCases: [SeerSession.OnboardingSteps] = SeerSession.OnboardingSteps.allCases
                let curI: Int = allCases.firstIndex(of: self.onboarding) ?? -1

                Task {
                    do {
                        try await self.stepAction() {
                            withAnimation {
                                self.onboarding = allCases[min(curI + 1, allCases.count - 1)]
                            }
                        }
                    } catch {
                        print("[Step Error] - \(error)")
                    }
                }
            } label: {
                HStack(alignment: .center, spacing: 10) {
                    Text("Next Step")
                    Image(systemName: "arrow.forward")
                }
                .frame(maxWidth: .infinity, minHeight: 40)
            }
            .disabled(self.onboardingBusy || !self.isStepCompleted)
            .buttonStyle(.glassProminent)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    var stepView: some View {
        switch self.onboarding {
            case .url:
                TextField("Jellyseerr URL", text: $seerrUrl)
                    .padding()
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .textInputFormattingControlVisibility(.hidden, for: .all)
                    .glassEffect(.regular.interactive())
            case .provider:
                VStack {
                    Button {
                        self.selection = true
                    } label: {
                        Text("Jellyseerr selection")
                    }
                }
            case .login:
                VStack(spacing: 30) {
                    TextField("Username", text: $username)
                        .padding()
                        .textContentType(.username)
                        .keyboardType(.asciiCapable)
                        .textInputFormattingControlVisibility(.hidden, for: .all)
                        .glassEffect(.regular.interactive())

                    SecureField("Password", text: $password)
                        .padding()
                        .textContentType(.password)
                        .keyboardType(.asciiCapable)
                        .textInputFormattingControlVisibility(.hidden, for: .all)
                        .glassEffect(.regular.interactive())
                }
            default:
                EmptyView()
        }
    }

    func stepAction(onSuccess: () -> Void) async throws {
        defer { withAnimation { self.onboardingBusy = false } }
        withAnimation { self.onboardingBusy = true }

        if self.onboarding == .url {
            self.seerrUrl.replace(/\/*$/, with: "")
            let (data, res, _) = try await SeerSession.shared.raw(Identify.status(url: self.seerrUrl))
            let code = res?.statusCode ?? -1

            if let json = try JSONSerialization.jsonObject(with: data) as? [String : Any], json["version"] != nil && code == 200 {
                withAnimation {
                    self.isSeerr = code == 200 && json["version"] != nil
                    SeerSession.shared.auth.address = self.seerrUrl
                }

                onSuccess()
            } else {
                throw SeerrError()
            }
        } else if self.onboarding == .login {
            let (data, res, cookies) = try await SeerSession.shared.raw(Login.jellyfin(username: self.username, password: self.password))
            let code = res?.statusCode ?? -1

            if let json = try JSONSerialization.jsonObject(with: data) as? [String : Any], json["id"] != nil && code == 200 {
                if let sid = cookies.first(where: { $0.name == "connect.sid" }) {
                    print("Got session ID:", sid.value)
                    SeerSession.shared.auth = .init(username: self.username, password: self.password, address: self.seerrUrl)
                    SeerSession.shared.authorization = sid.value
                    try SeerSession.shared.saveAuth()

                    UserDefaults.standard.set(true, forKey: "onboarded")
                    onSuccess()
                }
            } else {
                throw SeerrError()
            }
        } else { onSuccess() }
    }
}
