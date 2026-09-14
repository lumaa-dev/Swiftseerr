// Made by Lumaa

import WidgetKit
import SwiftUI

struct RequestsWidget: Widget {
    let kind: String = "fr.lumaa.Swiftseerr.SwiftseerrRequests"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetView(entry: entry)
				.containerBackground(Color.bgPurple, for: .widget)
				.widgetURL(URL(string: "swiftseerr://requests"))
        }
		.configurationDisplayName(Text("widget.requests"))
		.description(Text("widget.requests.description"))
		.supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
		#if !os(macOS)
		// macOS has no CarPlay or StandBy placements.
		.disfavoredLocations([.carPlay, .standBy], for: [.systemSmall, .systemMedium, .systemLarge])
		#endif
    }

	// MARK: - View

	struct WidgetView: View {
		@Environment(\.widgetFamily) private var widgetFamily: WidgetFamily

		var entry: Provider.Entry

		private var height: CGFloat { self.widgetFamily == .systemSmall ? 116.0 : 64.0 }
		private var width: CGFloat { self.height * (1.0 / 1.5) }

		var body: some View {
			if entry.items.isEmpty {
				self.empty
			} else if widgetFamily == .systemSmall, let first = entry.items.first {
				self.req(first, compact: true)
			} else {
				VStack(alignment: .leading, spacing: 10.0) {
					ForEach(entry.items) { item in
						self.req(item, compact: false)
					}
				}
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
			}
		}

		@ViewBuilder
		private var empty: some View {
			VStack(spacing: 6.0) {
				Image(systemName: entry.state == .noAccount ? "person.crop.circle.badge.questionmark" : "tray")
					.font(.title2)
					.foregroundStyle(Color.secondary)

				Text(entry.state.message)
					.font(.caption)
					.multilineTextAlignment(.center)
					.foregroundStyle(Color.secondary)
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
		}

		@ViewBuilder
		private func req(_ item: Provider.Entry.Item, compact: Bool) -> some View {
			if compact {
				VStack(alignment: .leading, spacing: 8.0) {
					self.poster(item)

					Text(item.title)
						.font(.callout.bold())
						.lineLimit(2)
						.multilineTextAlignment(.leading)

					self.status(item)
				}
				.frame(maxWidth: .infinity, alignment: .leading)
			} else {
				HStack(spacing: 8.0) {
					self.poster(item)

					VStack(alignment: .leading, spacing: 4.0) {
						Text(item.title)
							.font(.callout.bold())
							.lineLimit(1)
							.multilineTextAlignment(.leading)

						self.status(item)
					}

					Spacer(minLength: 0.0)
				}
			}
		}

		@ViewBuilder
		private func status(_ item: Provider.Entry.Item) -> some View {
			Text(item.status.localized)
				.foregroundStyle(Color.white)
				.font(.caption2)
				.lineLimit(1)
				.pill(item.status.color, multiply: 0.6)
		}

		/// Posters are decoded from data captured by the provider: `AsyncImage` never resolves inside a
		/// widget, since WidgetKit renders an archived snapshot rather than running a live view tree.
		@ViewBuilder
		private func poster(_ item: Provider.Entry.Item) -> some View {
			Group {
				if let image = item.image {
					image
						.resizable()
						.scaledToFill()
				} else {
					Rectangle()
						.fill(Color.gray.opacity(0.3))
						.overlay {
							Image(systemName: item.type == .show ? "tv" : "film")
								.foregroundStyle(Color.secondary)
						}
				}
			}
			.frame(width: self.width, height: self.height)
			.clipShape(RoundedRectangle(cornerRadius: 8.0))
		}
	}

	// MARK: - Provider

	struct Provider: TimelineProvider {
		/// WidgetKit only budgets a handful of refreshes per hour; anything shorter is coalesced away.
		private static let refreshInterval: TimeInterval = 60 * 30

		func placeholder(in context: Context) -> Entry {
			let items = (0..<Provider.count(for: context.family)).map { index in
				Entry.Item(
					id: index,
					title: MediaItem.redacted.title,
					status: .pending,
					type: .movie,
					image: nil
				)
			}

			return Entry(items: items, state: .ok)
		}

		func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
			guard !context.isPreview else { return completion(self.placeholder(in: context)) }

			Task {
				completion(await self.entry(family: context.family))
			}
		}

		func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
			Task {
				let entry = await self.entry(family: context.family)
				completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(Provider.refreshInterval))))
			}
		}

		// MARK: Loading

		private func entry(family: WidgetFamily) async -> Entry {
			guard let auth = AppData.widgetAuth() else {
				return Entry(items: [], state: .noAccount)
			}

			guard await WidgetSession.prepare(for: auth) else {
				return Entry(items: [], state: .failed)
			}

			let limit = Provider.count(for: family)
			var (requests, status) = await self.fetchRequests(limit: limit)

			// A cached cookie can outlive its server-side session; log in again once before giving up.
			if status == 401 || status == 403 {
				guard await WidgetSession.prepare(for: auth, forceLogIn: true) else {
					return Entry(items: [], state: .failed)
				}
				(requests, status) = await self.fetchRequests(limit: limit)
			}

			guard let status, (200...299).contains(status) else {
				return Entry(items: [], state: .failed)
			}

			var items: [Entry.Item] = []

			for request in requests {
				guard let media = try? await request.getMedia() else { continue }

				items.append(
					Entry.Item(
						id: request.id,
						title: media.title,
						status: media.requestStatus == .unknown ? request.status : media.requestStatus,
						type: request.type,
						image: await self.poster(media.image)
					)
				)
			}

			return Entry(items: items, state: items.isEmpty ? .empty : .ok)
		}

		/// Returns the parsed requests alongside the HTTP status, so an expired cookie can be told apart
		/// from a genuinely empty request list.
		private func fetchRequests(limit: Int) async -> ([MediaRequest], Int?) {
			let queries: [URLQueryItem] = [
				.init(name: "sort", value: "added"),
				.init(name: "sortDirection", value: "desc"),
				.init(name: "mediaType", value: "all")
			]

			do {
				let (data, response, _) = try await SeerSession.shared.raw(Requests.all(1, limit: limit), queries: queries)
				let status = response?.statusCode

				guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
					  let results = json["results"] as? [[String: Any]] else {
					return ([], status)
				}

				return (results.compactMap { MediaRequest(safely: $0) }, status)
			} catch {
				print("[fetchRequests] Error: \(error.localizedDescription)")
				return ([], nil)
			}
		}

		/// Poster bytes have to be resolved here rather than in the view; see `WidgetView.poster(_:)`.
		private func poster(_ url: URL?) async -> Image? {
			guard let url else { return nil }

			guard let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }

			#if canImport(UIKit)
			guard let image = UIImage(data: data) else { return nil }
			return Image(uiImage: image)
			#elseif canImport(AppKit)
			guard let image = NSImage(data: data) else { return nil }
			return Image(nsImage: image)
			#else
			return nil
			#endif
		}

		private static func count(for family: WidgetFamily) -> Int {
			switch family {
				case .systemSmall:
					return 1
				case .systemLarge:
					return 5
				default:
					return 3
			}
		}

		// MARK: Entry

		struct Entry: TimelineEntry {
			let date: Date
			let items: [Item]
			let state: State

			init(items: [Item] = [], state: State = .ok, date: Date = .now) {
				self.date = date
				self.items = items
				self.state = state
			}

			struct Item: Identifiable {
				let id: Int
				let title: String
				let status: MediaStatus
				let type: ItemType
				let image: Image?
			}

			enum State {
				case ok
				case empty
				case noAccount
				case failed

				var message: String {
					switch self {
						case .noAccount:
							String(localized: "widget.requests.no-account")
						case .failed:
							String(localized: "widget.requests.failed")
						default:
							String(localized: "widget.requests.empty")
					}
				}
			}
		}
	}
}
