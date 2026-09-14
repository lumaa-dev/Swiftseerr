// Made by Lumaa

import Foundation
import SwiftData

final class AppData {
	static var appGroupID: String = "group.fr.lumaa.Swiftseerr"
	static var developmentTeam: String = "HB5P3BML86"

	/// macOS expects App Group identifiers to carry the Team ID prefix, iOS expects the bare one.
	/// Both are tried so a single store is shared no matter the platform.
	private static var appGroupCandidates: [String] {
		#if os(macOS)
		return ["\(AppData.developmentTeam).\(AppData.appGroupID)", AppData.appGroupID]
		#else
		return [AppData.appGroupID, "\(AppData.developmentTeam).\(AppData.appGroupID)"]
		#endif
	}

	/// The App Group actually granted to this process, resolved by *using* it rather than by asking
	/// whether it exists.
	///
	/// `containerURL(forSecurityApplicationGroupIdentifier:)` happily returns a non-`nil` URL on macOS
	/// for a group the process holds no entitlement for — the path simply is not writable. Probing for
	/// `nil` therefore picks the wrong group and every write afterwards fails, so the directory is
	/// actually created here and the first candidate that accepts it wins.
	private static let resolved: (groupID: String, storeURL: URL)? = {
		for groupID in AppData.appGroupCandidates {
			guard let containerURL = FileManager.default.containerURL(
				forSecurityApplicationGroupIdentifier: groupID
			) else {
				continue
			}

			let directoryURL = containerURL.appendingPathComponent("SwiftData", isDirectory: true)

			do {
				try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
			} catch {
				print("[AppData] App Group \(groupID) is not writable: \(error.localizedDescription)")
				continue
			}

			return (groupID, directoryURL.appendingPathComponent("Swiftseerr.store"))
		}

		print("[AppData] No writable App Group container for \(AppData.appGroupID)")
		return nil
	}()

	static var resolvedAppGroupID: String? { AppData.resolved?.groupID }

	/// Defaults shared between the app and its extensions.
	static let sharedDefaults: UserDefaults = {
		guard let groupID = AppData.resolved?.groupID, let defaults = UserDefaults(suiteName: groupID) else {
			return .standard
		}
		return defaults
	}()

	static let modelContainer: ModelContainer = {
		if let storeURL = AppData.resolved?.storeURL {
			let configuration = ModelConfiguration(url: storeURL)

			if let container = try? ModelContainer(for: AuthInfo.self, configurations: configuration) {
				AppData.migrateLegacyStoreIfNeeded(into: container)
				return container
			}

			print("[AppData] Failed to open shared store at \(storeURL.path)")
		}

		// The App Group is unavailable: fall back to the process-local store rather than crashing,
		// so the widget can render an "add an account" state instead of dying on launch.
		return try! ModelContainer(for: AuthInfo.self)
	}()

	// MARK: - Widget account

	private static let widgetAccountKey: String = "widget.account"

	/// Identifier of the account the widgets display, shared with the extension.
	///
	/// The widget is a `StaticConfiguration`, so the account is chosen once in the app instead of per
	/// widget: WidgetKit rejects an unconfigured `AppIntentConfiguration` timeline outright, which is
	/// what made the widget unpreviewable.
	static var widgetAccountID: String? {
		get { AppData.sharedDefaults.string(forKey: AppData.widgetAccountKey) }
		set {
			if let newValue {
				AppData.sharedDefaults.set(newValue, forKey: AppData.widgetAccountKey)
			} else {
				AppData.sharedDefaults.removeObject(forKey: AppData.widgetAccountKey)
			}
		}
	}

	/// Every account in the shared store.
	static func storedAuths() -> [AuthInfo] {
		let context = ModelContext(AppData.modelContainer)
		return (try? context.fetch(FetchDescriptor<AuthInfo>())) ?? []
	}

	/// The account the widgets should display, falling back to the first one available.
	static func widgetAuth() -> AuthInfo? {
		let auths = AppData.storedAuths()

		if let widgetAccountID, let selected = auths.first(where: { $0.accountID == widgetAccountID }) {
			return selected
		}

		return auths.first
	}

	private static func migrateLegacyStoreIfNeeded(into sharedContainer: ModelContainer) {
		let sharedContext = ModelContext(sharedContainer)
		let descriptor = FetchDescriptor<AuthInfo>()

		guard (try? sharedContext.fetchCount(descriptor)) == 0 else {
			return
		}

		guard let legacyContainer = try? ModelContainer(for: AuthInfo.self) else {
			return
		}

		let legacyContext = ModelContext(legacyContainer)

		guard let legacyAuths = try? legacyContext.fetch(descriptor), !legacyAuths.isEmpty else {
			return
		}

		for legacyAuth in legacyAuths {
			let migratedAuth = AuthInfo(
				username: legacyAuth.username,
				password: legacyAuth.password,
				address: legacyAuth.address,
				provider: legacyAuth.provider
			)
			sharedContext.insert(migratedAuth)
		}

		try? sharedContext.save()
		print("[AppData] Migrated \(legacyAuths.count) account(s) into the shared store")
	}
}
