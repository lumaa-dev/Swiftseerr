// Made by Lumaa

import Foundation
import SwiftUI

@Observable
final class Navigator {
	public static let shared: Navigator = .init(selectedTab: .discover)

	public var selectedTab: Navigator.Tabs
	public var navigationPath: [Navigator.Tabs: [Navigator.Paths]] = [:]
	public var presentedSheet: Navigator.Sheets?

	public var currentPath: [Navigator.Paths] {
		get {
			self.navigationPath[self.selectedTab] ?? []
		}
		set {
			self.navigationPath[self.selectedTab] = newValue
		}
	}

	public init(selectedTab: Navigator.Tabs = .discover, presentedSheet: Navigator.Sheets? = nil) {
		self.selectedTab = selectedTab
		self.presentedSheet = presentedSheet
	}

	enum Tabs: String, Hashable, ViewRepresentable {
		case search
		case discover
		case movies
		case trending
		case upcomingMovies
		case shows
		case upcomingShows
		case requests

		@ContentBuilder
		var label: some View {
			switch self {
				case .discover:
					Label("discover", systemImage: "sparkles")
				case .movies:
					Label("movies", systemImage: "film.stack")
				case .trending:
					Label("trending", systemImage: "chart.line.uptrend.xyaxis")
				case .upcomingMovies:
					Label("upcoming.movies", systemImage: "calendar.badge.clock")
				case .shows:
					Label("shows", systemImage: "play.tv")
				case .upcomingShows:
					Label("upcoming.shows", systemImage: "globe.badge.clock")
				case .requests:
					Label("requests", systemImage: "clock")
				case .search:
					Label("search", systemImage: "magnifyingglass")
			}
		}

		@ContentBuilder
		var content: some View {
			switch self {
				case .discover:
					DiscoverView()
				case .movies:
					DiscoverItemsView("movies", endpoint: Discover.movie, rootTab: self)
				case .trending:
					DiscoverItemsView("trending", endpoint: Discover.trending, rootTab: self)
				case .upcomingMovies:
					DiscoverItemsView(
						"upcoming.movies",
						endpoint: Discover.movie,
						additionalQueries: [Discover.upcoming(type: .movie)],
						rootTab: self
					)
				case .shows:
					DiscoverItemsView("shows", endpoint: Discover.show, rootTab: self)
				case .upcomingShows:
					DiscoverItemsView(
						"upcoming.shows",
						endpoint: Discover.show,
						additionalQueries: [Discover.upcoming(type: .show)],
						rootTab: self
					)
				case .requests:
					RequestView()
				case .search:
					SearchView()
			}
		}

		@ContentBuilder
		var view: some TabContent {
			switch self {
				case .search:
					Tab(value: self, role: .search) {
						self.content
					}
				default:
					Tab(value: self) {
						self.content
					} label: {
						self.label
					}
			}
		}

		/// Used for iOS and iPadOS
		static var smallTabs: [Self] { [
			Tabs.discover,
			Tabs.movies,
			Tabs.shows,
			Tabs.requests,
			Tabs.search
		] }

		/// Used for macOS, uncategorized tabs
		static var uncategorized: [Self] { [
			Tabs.search,
			Tabs.discover,
			Tabs.trending,
			Tabs.requests
		] }

		/// Used for macOS, tabs in the "All movies"
		static var allMovies: [Self] { [
			Tabs.movies,
			Tabs.upcomingMovies
		] }

		/// Used for macOS, tabs in the "All shows"
		static var allShows: [Self] { [
			Tabs.shows,
			Tabs.upcomingShows
		] }
	}

	enum Paths: Identifiable, Hashable, Equatable, ViewRepresentable {
		case item(_ item: MediaItem)
		case itemId(id: Int, type: ItemType)
		case items(_ name: LocalizedStringKey, endpoint: any Endpoint, additionalQueries: [URLQueryItem] = [], rootTab: Navigator.Tabs? = nil)
		case person(_ personId: Int)
		case settings

		@ContentBuilder
		var label: some View {
			switch self {
				case .item(let i):
					MediaItemView(i)
				case .itemId(let id, let type):
					MediaItemView(mediaId: id, type: type)
				case .items(let name, let endpoint, let queries, let root):
					DiscoverItemsView(name, endpoint: endpoint, additionalQueries: queries, rootTab: root)
				case .person(let id):
					SeerrPersonView(personId: id)
				case .settings:
					SettingsView()
			}
		}

		var id: String {
			switch self {
				case .item(let i):
					return "item.\(i.type.rawValue)-\(i.id)"
				case .itemId(let id, let type):
					return "item.\(type.rawValue)-\(id)"
				case .items(let name, let endpoint, let additionalQueries, _):
					return "items.\(name)-\(endpoint.id)-\(additionalQueries.asString)"
				case .person(let id):
					return "person-\(id)"
				case .settings:
					return "settings"
			}
		}

		func hash(into hasher: inout Hasher) {
			hasher.combine(self.id)
		}

		static func ==(lhs: Self, rhs: Self) -> Bool {
			return lhs.id == rhs.id
		}
	}

	enum Sheets: ViewRepresentable {
		case seasons(_ item: MediaItem, season: ShowSeason.About)
		case web(url: URL?)

		@ContentBuilder
		var label: some View {
			switch self {
				case .seasons(let item, let season):
					ShowSeasonView(item: item, season: season)
				case .web(let url):
					CleanWebView(url)
			}
		}
	}
}

extension View {
	@ContentBuilder
	func navigator() -> some View {
		self.navigationDestination(for: Navigator.Paths.self) { i in
			i.label
		}
	}
}
