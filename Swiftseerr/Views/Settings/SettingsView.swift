// Made by Lumaa

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext

    #if os(iOS)
    @AppStorage("appIcon") private var appIcon: AppIcons = .jelly
    #endif

    @Query private var auths: [AuthInfo]

    @State private var unviewAuth: Bool = false
    @State private var viewAuth: AuthInfo? = nil
    @State private var viewOnboard: Bool = false
    @State private var newOnboard: SeerSession.OnboardingSteps = .welcome

    @State private var viewUrl: String? = nil

    var body: some View {
        Form {
            self.instances

            #if !os(macOS)
            NavigationLink {
                NotifSettingsView()
            } label: {
                Text("settings.notifications")
            }
            .listRowBackground(Color.gray.opacity(0.2))
            #endif

            self.appearence

            self.defAge

            self.info
        }
        .navigationTitle(Text("settings"))
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .scrollContentBackground(.hidden)
		.formStyle(.grouped)
        .background {
            Color.bgPurple.ignoresSafeArea()
        }
        .sheet(item: $viewAuth) { a in
            self.instance(a)
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled(self.unviewAuth)
        }
        .sheet(isPresented: $viewOnboard) {
            self.newOnboarding()
        }
        .sheet(item: $viewUrl) { url in
            CleanWebView(URL(string: url))
        }
    }

    // MARK: - Settings Sections
    @ViewBuilder
    private var instances: some View {
        Section("instances") {
            ForEach(auths) { auth in
                Button {
                    self.viewAuth = auth
                } label: {
                    HStack {
                        if SeerSession.shared.auth.id == auth.id {
                            Label(auth.username, systemImage: "checkmark")
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
				#if os(macOS)
				.buttonStyle(.plain)
				#endif
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

                self.newOnboard = .welcome
                self.viewOnboard.toggle()
            } label: {
                Text("add.instance")
            }
        }
    }

    @ViewBuilder
    private var appearence: some View {
#if os(iOS)
        Section("appearence") {
            NavigationLink(destination: Self.AppIconPicker(appIcon: $appIcon)) {
                Text("settings.app-icons")
            }
        }
        .listRowBackground(Color.gray.opacity(0.2))
#endif
    }

    @ViewBuilder
    private var defAge: some View {
		let undefinedAge: Bool = UserDefaults.standard.value(forKey: "ageCheck") == nil

        Section(header: Text("def-age"), footer: Text("def-age.footer")) {
            let definedAge: Int = UserDefaults.standard.integer(forKey: "ageCheck")
            LabeledContent("def-age", value: definedAge > 0 ? "\(definedAge)" : "Unknown")
        }
        .sectionActions {
            Button(role: .destructive) {
                UserDefaults.standard.removeObject(forKey: "ageCheck")
            } label: {
                Label("def-age.reset", systemImage: "figure.child.and.lock.fill")
                    .foregroundStyle(Color.red)
				#if os(macOS)
					.labelStyle(.titleOnly)
					.frame(minWidth: 100.0)
					.opacity(undefinedAge ? 0.35 : 1.0)
				#endif
            }
			.tint(Color.red)
            .disabled(undefinedAge)
        }
        .listRowBackground(Color.gray.opacity(0.2))
    }

    @ViewBuilder
    private var info: some View {
        Section("info") {
            if let url = URL(string: "https://github.com/lumaa-dev/Swiftseerr") {
                Link("swiftseerr.github.repo", destination: url)
                    .environment(\.openURL, OpenURLAction { _ in
                        return self.openLink(url)
                    })
            }

            if let url = URL(string: "https://github.com/seerr-team/seerr") {
                Link("seerr.github.repo", destination: url)
                    .environment(\.openURL, OpenURLAction { _ in
                        return self.openLink(url)
                    })
            }
        }
        .listRowBackground(Color.gray.opacity(0.2))
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
                            #if canImport(UIKit)
                            UIPasteboard.general.string = auth.password
                            #else
                            NSPasteboard.general.setString(auth.password, forType: .string)
                            #endif
                        } label: {
                            Label("copy.password", systemImage: "document.on.clipboard")
                        }
                    }
                LabeledContent("provider", value: auth.provider?.string ?? String(localized: "unknown"))
            }
			#if os(macOS)
			.padding(.vertical)
			#endif

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

    #if os(iOS)
    private struct AppIconPicker: View {
        @Binding var appIcon: AppIcons

        var body: some View {
            List {
                Section {
                    ForEach(AppIcons.allCases, id: \.self) { icon in
                        Button {
                            appIcon = icon
                        } label: {
                            HStack(spacing: 20.0) {
                                icon.representation
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)

                                Text(icon.rawValue) // maybe later change it?
                                    .font(.title2)
                                    .foregroundColor(Color.primary)

                                if appIcon == icon {
                                    Spacer()

                                    Image(systemName: "checkmark")
                                        .font(.callout)
                                        .foregroundStyle(Color.accentPurple)
                                }
                            }
                        }
                    }
                }
                .listRowBackground(Color.gray.opacity(0.2))
            }
            .navigationTitle(Text("settings.app-icons"))
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background {
                Color.bgPurple.ignoresSafeArea()
            }
            .onChange(of: appIcon) { oldValue, newValue in
                guard oldValue != newValue else { return }
                AppIcons.set(newValue)
            }
        }
    }
    #endif

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

				if auth.provider! == .local {
					try await self.getMe() // local auth doesn't give all expect data: https://github.com/seerr-team/seerr/pull/2456
				}

                print("[logIn] Cookie bound \(sid.value)")
				print("[logIn] Switched username: \(SeerSession.shared.user!.username) with \(SeerSession.shared.user!.permission)")
                UserDefaults.standard.set(true, forKey: "onboarded")
            }
        } else {
            throw SeerrError()
        }
    }

	private func getMe() async throws {
		guard let user = SeerSession.shared.user, user.permission <= 0 else { return }

		let (data, res, _) = try await SeerSession.shared.raw(Identify.me)
		let code = res?.statusCode ?? -1

		if let json = try JSONSerialization.jsonObject(with: data) as? [String : Any], code == 200 {
			SeerSession.shared.user = .init(data: json)
			print("[getMe] Updated user")
		} else {
			throw SeerrError()
		}
	}

    private func openLink(_ url: URL?) -> OpenURLAction.Result {
        self.viewUrl = url?.absoluteString
        return .handled
    }
}

extension String: @retroactive Identifiable {
    public var id: String { return self }
}

#Preview {
    SettingsView()
}
