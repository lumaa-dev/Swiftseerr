// Made by Lumaa

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext

    @Binding var onboarding: SeerSession.OnboardingSteps

    @State private var seerrUrl: String = ""
    @State private var isSeerr: Bool = false

    @State private var selection: AuthInfo.Providers? = nil

    @State private var username: String = ""
    @State private var password: String = ""

    @State private var onboardingBusy: Bool = false
    @State private var onboardingError: Bool = false

    private var localizedError: String {
        switch self.onboarding {
            case .url:
                String(localized: "error.invalid-instance")
            case .login:
                String(localized: "error.invalid-credentials")
            default:
                String(localized: "error.unknown")
        }
    }

    private var isStepCompleted: Bool {
        switch self.onboarding {
            case .welcome:
                return true
            case .url:
                return !seerrUrl.isEmpty
            case .provider:
                return self.selection != nil
            case .login:
                return !self.username.isEmpty && !self.password.isEmpty
            default:
                return false
        }
    }

    init(onboarding: Binding<SeerSession.OnboardingSteps>) {
        self._onboarding = onboarding
    }

    var body: some View {
        ZStack {
            Color.bgPurple
                .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(alignment: .leading, spacing: 24.0) {
                    VStack(alignment: .leading, spacing: 6.0) {
                        onboarding.badge

                        Text(onboarding.title)
                            .font(.title.bold())
                            .lineLimit(1)
                            .contentTransition(.numericText(countsDown: true))
                            .multilineTextAlignment(.leading)

                        Text(onboarding.description)
                            .font(.callout)
                            .multilineTextAlignment(.leading)
                    }

                    self.stepView

                    if self.onboardingError {
                        Label(self.localizedError, systemImage: "xmark.seal")
                            .foregroundStyle(Color.primary)
                            .padding(8.0)
                            .background(Color.red, in: .capsule)
                    }
                }
                .padding(18.0)
                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 30.0, style: .continuous))

                Spacer()

                Button {
                    self.nextStep()
                } label: {
                    HStack(alignment: .center, spacing: 10) {
                        Text("onboarding.next")
                        Image(systemName: "arrow.forward")
                    }
                    .frame(maxWidth: .infinity, minHeight: 40)
                }
                .disabled(self.onboardingBusy || !self.isStepCompleted)
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
                #if os(macOS)
                .padding(.bottom)
                #endif
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var stepView: some View {
        switch self.onboarding {
            case .url:
                TextField("seerr.url", text: $seerrUrl)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.URL)
                    #if !os(macOS)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    #endif
                    .textInputFormattingControlVisibility(.hidden, for: .all)
                    .clipShape(.capsule)
                    .submitLabel(.next)
                    .onSubmit {
                        guard self.isStepCompleted && !self.onboardingBusy else { return }
                        self.nextStep()
                    }
            case .provider:
                VStack(alignment: .leading, spacing: 6.0) {
                    ForEach(AuthInfo.Providers.allCases, id: \.self) { provider in
                        let selCol: Color = self.selection == provider ? Color.accentPurple : Color.gray.opacity(0.6)

                        Button {
                            withAnimation(.spring) {
                                self.selection = provider
                            }
                        } label: {
                            Label {
                                Text(provider.string)
                                    .font(.body)
                                    .frame(maxWidth: .infinity, minHeight: 50.0)
                            } icon: {
                                provider.symbol
                                    .font(.body)
                            }
                            .padding(.horizontal)
                            .background(selCol, in: .capsule)
                        }
                        .buttonStyle(.plain)
                    }
                }
            case .login(let p):
                VStack(alignment: .leading, spacing: 6.0) {
                    let isJelly: Bool = p == .jellyfin

                    TextField(isJelly ? "username" : "email", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(isJelly ? .username : .emailAddress)
                        #if !os(macOS)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        #endif
                        .textInputFormattingControlVisibility(.hidden, for: .all)
                        .clipShape(.capsule)

                    SecureField("password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                        #if !os(macOS)
                        .keyboardType(.asciiCapable)
                        #endif
                        .textInputFormattingControlVisibility(.hidden, for: .all)
                        .clipShape(.capsule)
                        .submitLabel(.go)
                        .onSubmit {
                            guard self.isStepCompleted && !self.onboardingBusy else { return }
                            self.nextStep()
                        }
                }
            default:
                EmptyView()
        }
    }

    private func nextStep() {
        let allCases: [SeerSession.OnboardingSteps] = SeerSession.OnboardingSteps.allCases
        let isLogin: Bool = SeerSession.OnboardingSteps.isLogin(self.onboarding)
        let curI: Int = allCases.firstIndex(of: isLogin ? .login(nil) : self.onboarding) ?? -1

        Task {
            do {
                try await self.stepAction() {
                    withAnimation {
                        self.onboardingError = false

                        let nextOnboard: SeerSession.OnboardingSteps = allCases[min(curI + 1, allCases.count - 1)]

                        if nextOnboard == .login(nil) {
                            self.onboarding = .login(self.selection)
                        } else {
                            self.onboarding = nextOnboard
                        }
                    }
                }
            } catch {
                print("[Step Error] - \(error)")
                withAnimation {
                    self.onboardingError = true
                }
            }
        }
    }

    private func stepAction(onSuccess: () -> Void) async throws {
        defer { withAnimation { self.onboardingBusy = false } }
        withAnimation { self.onboardingBusy = true }

        if self.onboarding == .url {
            if !self.seerrUrl.starts(with: "https://") {
                self.seerrUrl = "https://\(self.seerrUrl)"
            }

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
        } else if self.onboarding == .login(self.selection) {
            let endpoint: Login = self.selection == .jellyfin ? Login.jellyfin(username: self.username, password: self.password) : Login.local(email: self.username, password: self.password)

            let (data, res, cookies) = try await SeerSession.shared.raw(endpoint, useCookies: false)
            let code = res?.statusCode ?? -1

            if let json = try JSONSerialization.jsonObject(with: data) as? [String : Any], code == 200 {
                if let sid = cookies.first(where: { $0.name == "connect.sid" }) {
                    SeerSession.shared.auth = .init(
                        username: self.username,
                        password: self.password,
                        address: self.seerrUrl,
                        provider: self.selection
                    )
                    SeerSession.shared.authorization = sid.value
                    SeerSession.shared.user = .init(data: json)

                    modelContext.insert(SeerSession.shared.auth)

                    UserDefaults.standard.set(true, forKey: "onboarded")
                    onSuccess()
                }
            } else {
                throw SeerrError()
            }
        } else { onSuccess() }
    }
}
