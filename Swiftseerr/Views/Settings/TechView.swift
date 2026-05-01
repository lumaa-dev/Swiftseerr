// Made by Lumaa

import SwiftUI

struct TechView: View {
	@State private var apnOK: Bool = false
	@State private var apnAdmin: String = ""
	@State private var apnLogs: RequestLogs? = nil

    var body: some View {
		List {
			Section(header: Text("settings.technical.push-notifications")) {
				LabeledContent {
					Text(AppDelegate.deviceToken.isEmpty ? "unknown" : AppDelegate.deviceToken)
						.lineLimit(1)
				} label: {
					Text("settings.technical.device-token")
				}
				.contextMenu {
					Button {
						#if canImport(UIKit)
						UIPasteboard.general.string = AppDelegate.deviceToken
						#else
						NSPasteboard.general.setString(AppDelegate.deviceToken, forType: .string)
						#endif
					} label: {
						Label("copy", systemImage: "document.on.clipboard")
					}
				}
			}
			.listRowBackground(Color.gray.opacity(0.2))

			Section(header: Text("settings.technical.apn")) {
				self.adminAPN
			}
			.listRowBackground(Color.gray.opacity(0.2))
		}
		.navigationTitle(Text("settings.technical"))
		.navigationBarTitleDisplayMode(.inline)
		.scrollContentBackground(.hidden)
		.background {
			Color.bgPurple.ignoresSafeArea()
		}
		.sheet(item: $apnLogs) {
			self.apnLogs = nil
		} content: { item in
			self.apnLogView(item)
				.presentationDetents([.medium, .large])
				.presentationDragIndicator(.visible)
		}
    }

	// MARK: - Sections

	@ViewBuilder
	private var adminAPN: some View {
		if UserDefaults.standard.value(forKey: "notifUrl") != nil {
			TextField("settings.technical.apn-admin", text: $apnAdmin)
				#if !os(macOS)
				.keyboardType(.asciiCapable)
				.textInputAutocapitalization(.never)
				#endif
				.textInputFormattingControlVisibility(.hidden, for: .all)

			Button {
				Task {
					self.apnLogs = await self.getLogs()
				}
			} label: {
				Text("settings.technical.apn-logs")
			}
			.task {
				self.apnOK = await self.verifyServerStatus()
				print("[TechView] APN server is \(!self.apnOK ? "NOT" : "") okay")
			}
		} else {
			Text("error.apn.unset")
		}
	}

	@ViewBuilder
	private func apnLogView(_ log: RequestLogs) -> some View {
		List {
			if !log.success.isEmpty {
				Section(header: Text(String("success"))) {
					ForEach(log.success.defaultSort(), id: \.date) { l in
						Text(l.result)
							.foregroundStyle(Color.primary)
					}
				}
			}

			if !log.errors.isEmpty {
				Section(header: Text(String("errors"))) {
					ForEach(log.errors.defaultSort(), id: \.date) { err in
						Text(err.result)
							.foregroundStyle(Color.red)
					}
				}
			}
		}
	}

	// MARK: - Functions

	private func verifyServerStatus() async -> Bool {
		guard let url: String = UserDefaults.standard.string(forKey: "notifUrl"), let auth: String = UserDefaults.standard.string(forKey: "notifAuth"), let urll: URL = URL(string: url) else { return false }

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

	private func getLogs() async -> RequestLogs? {
		guard let url: String = UserDefaults.standard.string(forKey: "notifUrl"), let urll: URL = URL(string: url + "/logs") else { return nil }
		print("[TechView+getLogs] Sending /logs with \(self.apnAdmin)")

		var req: URLRequest = .init(url: urll, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 300)
		req.setValue(self.apnAdmin, forHTTPHeaderField: "Authorization")
		req.httpMethod = "GET"

		do {
			let (data, res): (Data, URLResponse) = try await URLSession.shared.data(for: req)
			if let http = res as? HTTPURLResponse, (200...299).contains(http.statusCode) {
				return try JSONDecoder().decode(RequestLogs.self, from: data)
			} else {
				return nil
			}
		} catch {
			print(error)
		}

		return nil
	}
}

extension RequestLogs: Identifiable {
	var id: UUID { UUID() }
}
