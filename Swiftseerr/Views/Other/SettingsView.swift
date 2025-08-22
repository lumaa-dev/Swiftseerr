// Made by Lumaa

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext

    @Query private var auths: [AuthInfo]

    @State private var viewAuth: AuthInfo? = nil
    @State private var viewOnboard: Bool = false
    @State private var newOnboard: SeerSession.OnboardingSteps = .welcome

    @State private var unviewAuth: Bool = false

    var body: some View {
        List {
            Section("instances") {
                ForEach(auths) { auth in
                    let lessUrl: String = auth.address.replacingOccurrences(of: "https://", with: "")

                    Button {
                        self.viewAuth = auth
                    } label: {
                        HStack {
                            if SeerSession.shared.auth.id == auth.id {
                                Label("\(lessUrl) (\(auth.username))", systemImage: "checkmark")
                                    .foregroundStyle(Color.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Text(auth.username)
                                    .foregroundStyle(Color.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            Image(systemName: "chevron.forward")
                                .foregroundStyle(Color.secondary.opacity(0.4))
                        }
                    }
                    .deleteDisabled(auths.count <= 1)
                }
                .onDelete { indices in
                    for index in indices {
                        let auth = auths[index]
                        modelContext.delete(auth)
                    }
                }
            }
            .listRowBackground(Color.gray.opacity(0.2))
            .sectionActions {
                Button {
                    SeerSession.shared.clear()
                    self.viewOnboard.toggle()
                } label: {
                    Text("add.instance")
                }
            }
        }
        .navigationTitle(Text("settings"))
        .scrollContentBackground(.hidden)
        .background {
            Color.bgPurple.ignoresSafeArea()
        }
        .sheet(item: $viewAuth) { a in
            self.instance(a)
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled(self.unviewAuth)
        }
        .fullScreenCover(isPresented: $viewOnboard) {
            self.newOnboarding()
        }
    }

    // MARK: - View method

    @ViewBuilder
    private func instance(_ auth: AuthInfo) -> some View {
        List {
            Section {
                LabeledContent("address", value: auth.address)
                LabeledContent("username", value: auth.username)
                LabeledContent("password", value: String(repeating: "*", count: auth.password.count))
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = auth.password
                        } label: {
                            Label("copy.password", systemImage: "document.on.clipboard")
                        }
                    }
                LabeledContent("provider", value: auth.provider?.string ?? String(localized: "unknown"))
            }

            Button {
                self.unviewAuth = true

                let prevAuth: AuthInfo = SeerSession.shared.auth
                SeerSession.shared.auth = auth

                Task {
                    defer {
                        self.unviewAuth = false
                        self.viewAuth = nil
                    }

                    do {
                        try await self.logIn(auth: auth)
                    } catch {
                        print(error)

                        withAnimation {
                            SeerSession.shared.auth = prevAuth
                        }
                    }
                }
            } label: {
                Text("login")
            }
            .disabled(self.unviewAuth || SeerSession.shared.auth.id == auth.id)
        }
        .scrollDisabled(true)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private func newOnboarding() -> some View {
        OnboardingView(onboarding: $newOnboard)
            .onChange(of: newOnboard) { _, newValue in
                if newValue == .complete {
                    viewOnboard = false
                }
            }
    }

    // MARK: - Methods

    private func logIn(auth: AuthInfo) async throws {
        guard !auth.address.isEmpty && !auth.password.isEmpty && auth.provider != nil else { throw SeerrError() }

        let endpoint: Login = auth.provider! == .jellyfin ? Login.jellyfin(username: auth.username, password: auth.password) : Login.local(email: auth.username, password: auth.password)
        let (data, res, cookies) = try await SeerSession.shared.raw(endpoint)
        let code = res?.statusCode ?? -1

        if let json = try JSONSerialization.jsonObject(with: data) as? [String : Any], code == 200 {
            if let sid = cookies.first(where: { $0.name == "connect.sid" }) {
                withAnimation {
                    SeerSession.shared.auth = auth
                    SeerSession.shared.authorization = sid.value
                    SeerSession.shared.user = .init(data: json)
                }

                print("[logIn] Cookie bound \(sid.value)")
                UserDefaults.standard.set(true, forKey: "onboarded")
            }
        } else {
            throw SeerrError()
        }
    }
}

#Preview {
    SettingsView()
}
