// Made by Lumaa
import SwiftUI

struct NotifSettingsView: View {
    @State private var grantedNotifs: Bool = false
    @State private var validated: Bool = false

    @State private var prevServerUrl: String? = nil
    @State private var prevAuth: String? = nil
    @State private var serverUrl: String = ""
    @State private var auth: String = ""

    // filters
    @AppStorage("notif-filter.medPend") private var medPendNotify: Bool = true // 1
    @AppStorage("notif-filter.medAvalble") private var medAvalbleNotify: Bool = true // 2
    @AppStorage("notif-filter.medDen") private var medDenNotify: Bool = true // 4
    @AppStorage("notif-filter.medAutoApr") private var medAutoAprNotify: Bool = true // 8

    @State private var viewUrl: String? = nil
    @State private var delAlert: Bool = false

    var body: some View {
        Form {
            Section {
                HStack {
                    TextField("settings.notifications.server-url", text: $serverUrl)
                        .textContentType(.URL)
						.textFieldStyle(.roundedBorder)
                        #if !os(macOS)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        #endif
                        .textInputFormattingControlVisibility(.hidden, for: .all)
                        .onChange(of: serverUrl) { oldValue, newValue in
                            guard !newValue.isEmpty, newValue != self.prevServerUrl else { return }

                            if self.validated && oldValue != newValue {
                                self.delAlert = true
                                self.serverUrl = newValue
                            }
                        }
                        .disabled(!self.grantedNotifs)

                    Button {
                        if !self.serverUrl.starts(with: "https://") {
                            self.serverUrl = "https://\(self.serverUrl)"
                        }

                        if self.serverUrl.last! == "/" {
                            _ = self.serverUrl.popLast()
                        }

                        Task {
                            let validUrl = await self.isValid(url: serverUrl, auth: auth)
                            print(validUrl ? "[NotifSettingsView] Valid url" : "[NotifSettingsView] Unvalidated url boohoo")

                            if validUrl {
                                // validate fully whenever the token is on the other side (server)
                                self.validated = await self.sendToken(url: serverUrl, auth: auth)
                                print(self.validated ? "[NotifSettingsView] VALID URL & TOKEN SENT" : "[NotifSettingsView] Unsent token boohoo")

                                if self.validated {
                                    UserDefaults.standard.set(serverUrl, forKey: "notifUrl")
                                    UserDefaults.standard.set(auth, forKey: "notifAuth")
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "paperplane")
                            .imageScale(.small)
                    }
                    .buttonStyle(.plain)
                    .padding(7.5)
                    .background(self.serverUrl.isEmpty || self.validated ? Color.gray : Color.accentPurple)
                    .clipShape(Capsule())
                    .disabled(self.serverUrl.isEmpty || self.validated)
                }

                TextField("settings.notifications.auth", text: $auth)
                    #if !os(macOS)
                    .keyboardType(.asciiCapable)
                    .textInputAutocapitalization(.never)
                    #endif
                    .textInputFormattingControlVisibility(.hidden, for: .all)
                    .disabled(self.serverUrl.isEmpty)
            }
            .listRowBackground(Color.gray.opacity(0.2))

            Section(header: Text("notification.filter")) {
                Toggle(isOn: $medPendNotify) {
                    Text("notification.filter.pending")
                }
                .disabled(!self.validated)
                .onChange(of: medPendNotify) { _, _ in
                    print("[NotifSettingsView] Updating pending")
                    self.updateFilter()
                }

                Toggle(isOn: $medAvalbleNotify) {
                    Text("notification.filter.available")
                }
                .disabled(!self.validated)
                .onChange(of: medAvalbleNotify) { _, _ in
                    print("[NotifSettingsView] Updating available")
                    self.updateFilter()
                }

                Toggle(isOn: $medDenNotify) {
                    Text("notification.filter.denied")
                }
                .disabled(!self.validated)
                .onChange(of: medDenNotify) { _, _ in
                    print("[NotifSettingsView] Updating denied")
                    self.updateFilter()
                }

                Toggle(isOn: $medAutoAprNotify) {
                    Text("notification.filter.auto-approved")
                }
                .disabled(!self.validated)
                .onChange(of: medAutoAprNotify) { _, _ in
                    print("[NotifSettingsView] Updating auto-approved")
                    self.updateFilter()
                }
            }
            .listRowBackground(Color.gray.opacity(0.2))

            Section(footer: Text("settings.notifications.seerrapn")) {
                if let url = URL(string: "https://github.com/lumaa-dev/SeerrAPN") {
                    Link("seerrapn.github.repo", destination: url)
                        .environment(\.openURL, OpenURLAction { _ in
                            return self.openLink(url)
                        })
                }
            }
            .listRowBackground(Color.gray.opacity(0.2))
        }
        .navigationTitle(Text("settings.notifications"))
		#if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
		#endif
        .scrollContentBackground(.hidden)
		.formStyle(.grouped)
        .background {
            Color.bgPurple.ignoresSafeArea()
        }
        .alert("settings.notifications.delete", isPresented: $delAlert) {
            Button(role: .cancel) {
                self.serverUrl = UserDefaults.standard.string(forKey: "notifUrl") ?? ""
                self.auth = UserDefaults.standard.string(forKey: "notifAuth") ?? ""
            }

            Button(role: .destructive) {
                Task {
                    let del = await self.deleteToken()

                    if del {
						print("[NotifSettingsView] Deleted token off APN server")

                        UserDefaults.standard.removeObject(forKey: "notifUrl")
                        UserDefaults.standard.removeObject(forKey: "notifAuth")

                        self.validated = false
                        self.serverUrl = ""
                        self.auth = ""
                        self.delAlert = false
                    }
                }
            } label: {
                Text("delete")
            }
        }  message: {
            Text("settings.notifications.delete.message")
        }
        .sheet(item: $viewUrl) { url in
            CleanWebView(URL(string: url))
        }
        .onAppear {
            AppDelegate.requestNotifications { granted in
                self.grantedNotifs = granted
            }

            guard self.grantedNotifs else { return }

            self.serverUrl = UserDefaults.standard.string(forKey: "notifUrl") ?? ""
            self.auth = UserDefaults.standard.string(forKey: "notifAuth") ?? ""

            if !self.serverUrl.isEmpty {
                self.validated = true

                self.prevServerUrl = self.serverUrl
                self.prevAuth = self.auth
            }
        }
    }

    private func openLink(_ url: URL?) -> OpenURLAction.Result {
        self.viewUrl = url?.absoluteString
        return .handled
    }

    private func updateFilter() {
        var newNotif: Int = 0

        newNotif += self.medPendNotify ? 1 : 0
        newNotif += self.medAvalbleNotify ? 2 : 0
        newNotif += self.medDenNotify ? 4 : 0
        newNotif += self.medAutoAprNotify ? 8 : 0

        Task {
            let updated: Bool = await self.updatedNotify(newNotif)
            if updated {
                print("[NotifSettingsView] Woohoo! Updated filters!")
            } else {
                print("[NotifSettingsView] NOT updated filters")
            }
        }
    }

    private func boolDiff(_ bool: Bool, defaultKey: String) -> Bool {
        return bool != UserDefaults.standard.bool(forKey: defaultKey)
    }
}

extension NotifSettingsView {
    func isValid(url: String, auth: String = "") async -> Bool {
        guard let urll: URL = URL(string: url) else { return false }

        var req: URLRequest = .init(url: urll, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 300)
        req.setValue(auth, forHTTPHeaderField: "Authorization")
        req.httpMethod = "GET"

        do {
            let res: URLResponse = try await URLSession.shared.data(for: req).1
            if let http = res as? HTTPURLResponse {
                return http.statusCode == 200
            } else {
                return false
            }
        } catch {
            print(error)
        }

        return false
    }

    func sendToken(url: String, auth: String = "") async -> Bool {
        guard let urll: URL = URL(string: "\(url)/token") else {
            return false
        }

        var req: URLRequest = .init(url: urll, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 300)
        req.setValue(auth, forHTTPHeaderField: "Authorization")
        req.httpBody = "deviceToken=\(AppDelegate.deviceToken)".data(using: .utf8)
        req.httpMethod = "POST"

        do {
            let res: URLResponse = try await URLSession.shared.data(for: req).1
            if let http = res as? HTTPURLResponse {
                return http.statusCode == 200
            } else {
                return false
            }
        } catch {
            print(error)
        }

        return false
    }

    func updatedNotify(_ newNotify: Int = 0) async -> Bool {
        guard let url: String = UserDefaults.standard.string(forKey: "notifUrl"), let auth: String = UserDefaults.standard.string(forKey: "notifAuth"), let urll: URL = URL(string: "\(url)/notify") else {
            return false
        }

        var req: URLRequest = .init(url: urll, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 300)
        req.setValue(auth, forHTTPHeaderField: "Authorization")
        req.httpBody = "deviceToken=\(AppDelegate.deviceToken)&notify=\(newNotify)".data(using: .utf8)
        req.httpMethod = "POST"

        do {
            let res: URLResponse = try await URLSession.shared.data(for: req).1
            if let http = res as? HTTPURLResponse {
                return http.statusCode == 200
            } else {
                return false
            }
        } catch {
            print(error)
        }

        return false
    }

    func deleteToken() async -> Bool {
        guard let notifUrl: String = UserDefaults.standard.string(forKey: "notifUrl"), let auth: String = UserDefaults.standard.string(forKey: "notifAuth"), let urll: URL = URL(string: "\(notifUrl)/token") else {
            return false
        }

        var req: URLRequest = .init(url: urll, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 300)
        req.setValue(auth, forHTTPHeaderField: "Authorization")
        req.httpBody = "deviceToken=\(AppDelegate.deviceToken)".data(using: .utf8)
        req.httpMethod = "DELETE"

        do {
            let res: URLResponse = try await URLSession.shared.data(for: req).1
            if let http = res as? HTTPURLResponse {
                return http.statusCode == 200
            } else {
                return false
            }
        } catch {
            print(error)
        }

        return false
    }
}

#Preview {
    NotifSettingsView()
}
