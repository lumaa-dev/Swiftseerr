// Made by Lumaa

import Foundation
import SwiftUI

final class DeeplinkManager {

	static let scheme: String = "swiftseerr" // then ://
	static let defaultResult: OpenURLAction.Result = .systemAction

	private init() {}

	/// Handle deep link interactions
	///
	/// - `amber://discogs?oauth_token=xxx&oauth_verifier=xxx` for example is a valid deep link (to link Discogs and Amber together here)
	/// - `swiftseerr://movie?id=xxx` is also a valid deep link (to view a movie using its TMDB identifier)
	static func handle(_ url: URL) -> OpenURLAction.Result {
		if let component: URLComponents = .init(string: url.absoluteString), component.scheme == self.scheme {
			guard let host: DeeplinkManager.Path = DeeplinkManager.Path.from(component.host ?? "") else { return self.defaultResult }

			switch host {
				case .movie, .tv:
					print("[DeeplinkManager] Deep link is media")
					return self.media(host, component: component)
				case .navigation:
					return self.defaultResult
			}
		}
		return self.defaultResult
	}

	/// Turns a string-query into an actual array of `URLQueryItem`
	///
	/// - Returns: An array of `URLQueryItem` corresponding to the `string` parameter
	static func querify(from string: String) -> [URLQueryItem] {
		let queriesStr = string.split(separator: "&")

		let queries: [URLQueryItem] = queriesStr.map {
			let q = $0.split(separator: "=")
			return URLQueryItem(name: String(q[0]), value: q.count > 0 ? String(q[1]) : nil)
		}

		return queries
	}

	private static func media(_ host: DeeplinkManager.Path, component: URLComponents) -> OpenURLAction.Result {
		if let queries: [URLQueryItem] = component.queryItems {
			if let id: String = queries.filter({ $0.name == "id" }).first?.value, let idInt = Int(id) {
				let path: Navigator.Paths = .itemId(id: idInt, type: host.type)
				self.followPath(path)
				return .handled
			}
		}

		Navigator.shared.selectedTab = host.tab
		print("[DeeplinkManager] Probably just a tab \(host.tab.rawValue)")
		return .handled
	}

	private static func followPath(_ path: Navigator.Paths) {
		let pathIndex: Int? = Navigator.shared.currentPath.lastIndex(of: path)
		if let pathIndex {
			let count: Int = Navigator.shared.currentPath.count
			Navigator.shared.currentPath.remove(atOffsets: .init(integersIn: pathIndex + 1...count))
			print("[DeeplinkManager] Found existing path to \(path.id)")
		} else {
			Navigator.shared.currentPath.append(path)
			print("[DeeplinkManager] Appended path \(path.id)")
		}
	}

	enum Path: String {
		case movie = "movie"
		case tv = "tv"
		case navigation = "nav"

		static func from(_ string: String) -> Self? {
			switch string {
				case Self.movie.rawValue:
					return Self.movie
				case Self.tv.rawValue:
					return Self.tv
				case Self.navigation.rawValue:
					return Self.navigation
				default:
					return nil
			}
		}

		var type: ItemType {
			switch self {
				case .movie:
					return .movie
				case .tv:
					return .show
				case .navigation:
					return .unknown
			}
		}

		var tab: Navigator.Tabs {
			switch self {
				case .movie:
					return .movies
				case .tv:
					return .shows
				case .navigation:
					return .discover
			}
		}
	}
}
