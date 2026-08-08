// Made by Lumaa

import Foundation
import SwiftData

final class AppData {
	static var appGroupID: String = "group.fr.lumaa.Swiftseerr"

	static let modelContainer: ModelContainer = {
		let configuration = ModelConfiguration(url: AppData.storeURL)
		let container = try! ModelContainer(for: AuthInfo.self, configurations: configuration)
		AppData.migrateLegacyStoreIfNeeded(into: container)
		return container
	}()

	private static let storeURL: URL = {
		guard let containerURL = FileManager.default.containerURL(
			forSecurityApplicationGroupIdentifier: AppData.appGroupID
		) else {
			fatalError("Missing shared container for \(AppData.appGroupID)")
		}

		let directoryURL = containerURL.appendingPathComponent("SwiftData", isDirectory: true)

		do {
			try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
		} catch {
			fatalError("Failed to create shared SwiftData directory: \(error.localizedDescription)")
		}

		return directoryURL.appendingPathComponent("Swiftseerr.store")
	}()

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
	}
}
