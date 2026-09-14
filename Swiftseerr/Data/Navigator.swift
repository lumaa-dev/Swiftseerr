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
		case releases(_ releases: [String: Date])
		case person(_ personId: Int)
		case persons(_ persons: [MediaPerson], title: LocalizedStringKey)
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
				case .releases(let dates):
					MediaItemView.ReleasesView(releaseDates: dates)
				case .person(let id):
					SeerrPersonView(personId: id)
				case .persons(let persons, let title):
					MediaPersonsView(with: persons, title: "cast")
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
				case .releases(let dates):
					return "media.releases-\(dates.count)"
				case .person(let id):
					return "person-\(id)"
				case .persons(let persons, let title):
					return "persons.\(title)-\(persons.count)"
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

	enum Sheets: ViewRepresentable, Identifiable {
		case seasons(_ item: MediaItem, season: ShowSeason.About)
		case seasonsPicker(_ seasons: [ShowSeason.About], disabledSeasons: [Int], confirmAction: ([ShowSeason.About]) async -> Void)
		case web(url: URL?)

		@ContentBuilder
		var label: some View {
			switch self {
				case .seasons(let item, let season):
					ShowSeasonView(item: item, season: season)
				case .seasonsPicker(let seasons, let disabled, let confirm):
					SeasonsPicker(seasons: seasons, disabledSeasons: disabled, confirmAction: confirm)
						.presentationDetents([.medium, .large])
						.presentationDragIndicator(.hidden)
						.presentationBackground(Color.bgPurple)
				case .web(let url):
					CleanWebView(url)
			}
		}

		var id: String {
			switch self {
				case .seasons(let item, let season):
					return "item-\(item.id).season-\(season.id)"
				case .seasonsPicker(let seasons, let disabledSeasons, let confirmAction):
					return "season-picker.\(seasons.count)-\(disabledSeasons.map { "\($0)" }.joined())"
				case .web(let url):
					return "web-\(url?.absoluteString ?? "web")"
			}
		}
	}
}

extension Navigator.Paths {
	static var trending: Navigator.Paths {
		return Navigator.Paths.items("trending", endpoint: Discover.trending)
	}

	static var upcomingMovie: Navigator.Paths {
		return Navigator.Paths.items("upcoming.movies", endpoint: Discover.movie, additionalQueries: [Discover.upcoming(type: .movie)])
	}

	static var upcomingShow: Navigator.Paths {
		return Navigator.Paths.items("upcoming.shows", endpoint: Discover.show, additionalQueries: [Discover.upcoming(type: .show)])
	}
}

extension View {
	@ContentBuilder
	func navigator() -> some View {
		self.navigationDestination(for: Navigator.Paths.self) { i in
			i.label
		}
	}

	@ContentBuilder
	func sheet() -> some View {
		self.sheet(item: Binding(get: { Navigator.shared.presentedSheet }, set: { Navigator.shared.presentedSheet = $0 })) { s in
			s.label
		}
	}
}
