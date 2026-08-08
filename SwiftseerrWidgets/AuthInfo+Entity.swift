// Made by Lumaa

import AppIntents
import SwiftData

extension AuthInfo: AppEntity {
	static var persistentIdentifier: String = "fr.lumaa.Swiftseerr.AuthInfo"
	static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(name: "auth-data")

	var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(title: LocalizedStringResource(stringLiteral: self.username), subtitle: LocalizedStringResource(stringLiteral: self.address))
	}

	var localizedStringResource: LocalizedStringResource { LocalizedStringResource("auth-data.description") }

	static var defaultQuery: AuthInfoQuery = AuthInfoQuery()

	static var redacted: AuthInfo = .init(
		username: "Lumaa",
		password: "MyMagicPassword!",
		address: "https://lumaa.fr/",
		provider: .local
	)
}

struct AuthInfoQuery: EntityQuery {
	typealias Entity = AuthInfo

	private func getAuths() -> [AuthInfo] {
		let context: ModelContext = ModelContext(AppData.modelContainer)

		let auths = try? context.fetch(FetchDescriptor<AuthInfo>())
		return auths ?? []
	}

	func defaultResult() async -> DefaultValue? {
		return self.getAuths().first
	}

	func suggestedEntities() async throws -> some ResultsCollection {
		return self.getAuths()
	}

	func entities(for identifiers: [AuthInfo.ID]) async throws -> [AuthInfo] {
		return self.getAuths().filter({ identifiers.contains($0.id) })
	}
}
