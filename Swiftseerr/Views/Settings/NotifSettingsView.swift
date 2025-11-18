// Made by Lumaa

import SwiftUI

struct NotifSettingsView: View {

    @State private var grantedNotifs: Bool = false
    @State private var validated: Bool = false

    @State private var serverUrl: String = ""
    @State private var auth: String = ""

    @State private var delAlert: Bool = false

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("settings.notifications.server-url", text: $serverUrl)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .textInputFormattingControlVisibility(.hidden, for: .all)
                        .onChange(of: serverUrl) { oldValue, newValue in
                            guard !newValue.isEmpty else { return }

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
                    .keyboardType(.asciiCapableNumberPad)
                    .textInputAutocapitalization(.never)
                    .textInputFormattingControlVisibility(.hidden, for: .all)
                    .disabled(self.serverUrl.isEmpty)
            }
            .listRowBackground(Color.gray.opacity(0.2))

            if self.validated {
                Section {
                    Text(String("Filtres notifs bientôt"))
                }
                .listRowBackground(Color.gray.opacity(0.2))
            }
        }
        .alert("settings.notifications.delete", isPresented: $delAlert) {
            Button(role: .cancel) {
                self.serverUrl = UserDefaults.standard.string(forKey: "notifUrl") ?? ""
                self.auth = UserDefaults.standard.string(forKey: "notifAuth") ?? ""
            }

            Button(role: .destructive) {
                Task {
                    _ = await self.deleteToken()

                    UserDefaults.standard.removeObject(forKey: "notifUrl")
                    UserDefaults.standard.removeObject(forKey: "notifAuth")

                    self.validated = false
                    self.serverUrl = ""
                    self.auth = ""
                    self.delAlert = false
                }
            } label: {
                Text("delete")
            }
        }  message: {
            Text("settings.notifications.delete.message")
        }
        .onAppear {
            AppDelegate.requestNotifications { granted in
                self.grantedNotifs = granted
                print(self.grantedNotifs ? "Granted connard" : "NOT GRANDED??? fils de pute")
            }

            guard self.grantedNotifs else { return }

            self.serverUrl = UserDefaults.standard.string(forKey: "notifUrl") ?? ""
            self.auth = UserDefaults.standard.string(forKey: "notifAuth") ?? ""

            if !self.serverUrl.isEmpty {
                self.validated = true
            }
        }
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
