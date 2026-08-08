// Made by Lumaa

import AppIntents
import WidgetKit
import SwiftUI

struct RequestsWidget: Widget {
    let kind: String = "fr.lumaa.Swiftseerr.SwiftseerrRequests"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: Configuration.self, provider: Provider()) { entry in
            WidgetView(entry: entry)
				.containerBackground(Color.bgPurple, for: .widget)
				.widgetURL(URL(string: "swiftseerr://requests"))
        }
		.configurationDisplayName(Text("widget.requests"))
		.description(Text("widget.requests.description"))
		.supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
		.disfavoredLocations([.carPlay, .standBy], for: [.systemLarge, .systemMedium, .systemLarge])
		.promptsForUserConfiguration()
    }

	struct Configuration: WidgetConfigurationIntent {
		static var title: LocalizedStringResource { "widget.config.title" }
		static var description: IntentDescription { "widget.config.description" }

		@Parameter(title: "seerr.account", description: "seerr.account.description")
		var auth: AuthInfo?

		var session: SeerSession {
			guard let auth else { fatalError("[ConfigurationAppIntent] Cannot create session without auth") }
			return .init(auth: auth)
		}
	}


	struct WidgetView: View {
		@Environment(\.widgetFamily) private var widgetFamily: WidgetFamily

		var entry: Provider.Entry

		private var width: CGFloat { self.height * (1.0 / 1.5) }
		private let height: CGFloat = 100

		var body: some View {
			if widgetFamily == .systemSmall, let fr = entry.requests.first, let fi = entry.items.first {
				self.req(fr, item: fi).padding()
			} else {
				VStack {
					ForEach(entry.requests) { request in
						let index: Int = entry.requests.firstIndex(of: request) ?? -1
						let item: MediaItem = entry.items[index]

						self.req(request, item: item)
							.padding(.vertical)
					}
				}
				.padding(.horizontal)
			}
		}

		@ContentBuilder
		private func req(_ request: MediaRequest, item: MediaItem) -> some View {
			VStack(spacing: 16.0) {
				HStack(spacing: 8) {
					self.poster(request: request, item: item)
						.frame(width: width, height: height)
						.clipShape(RoundedRectangle(cornerRadius: 8))

					VStack(alignment: .leading) {
						Text(item.title)
							.font(.callout.bold())
							.lineLimit(1)
							.multilineTextAlignment(.leading)

						Text(item.requestStatus.localized)
							.foregroundStyle(Color.white)
							.font(.callout)
							.glassPill(item.requestStatus.color)
					}
				}
			}
		}

		@ContentBuilder
		private func poster(request: MediaRequest, item: MediaItem) -> some View {
			AsyncImage(url: item.image ?? URL(string: "\(entry.auth.address)/images/jellyseerr_poster_not_found.png")) { image in
				image
					.resizable()
					.scaledToFill()
					.frame(width: self.width, height: self.height)
					.clipped()
			} placeholder: {
				Rectangle()
					.fill(Color.clear)
					.frame(width: self.width, height: self.height)
					.overlay {
						ProgressView()
							.progressViewStyle(.circular)
					}
			}
		}
	}

	struct Provider: AppIntentTimelineProvider {
		func placeholder(in context: Context) -> WidgetEntry {
			let placeholders: [MediaRequest] = Array(repeating: MediaRequest.redacted, count: 5)
			let items: [MediaItem] = Array(repeating: .redacted, count: 5)

			return .init(placeholders, items: items, auth: .redacted)
		}

		func snapshot(for configuration: RequestsWidget.Configuration, in context: Context) async -> WidgetEntry {
			guard let auth = configuration.auth else { return self.placeholder(in: context) }

			let requests: [MediaRequest] = await self.fetchRequests(configuration.session, page: 1, limit: 5)
			var items: [MediaItem] = []

			if !requests.isEmpty {
				for request in requests {
					guard let i = try? await request.getMedia() else { continue }
					items.append(i)
				}
			}

			return .init(requests, items: items, auth: auth)
		}

		func timeline(for configuration: RequestsWidget.Configuration, in context: Context) async -> Timeline<WidgetEntry> {
			guard let auth = configuration.auth else { return Timeline(entries: [self.placeholder(in: context)], policy: .atEnd) }

			let requests: [MediaRequest] = await self.fetchRequests(configuration.session, page: 1, limit: 5)
			var items: [MediaItem] = []

			if !requests.isEmpty {
				for request in requests {
					guard let i = try? await request.getMedia() else { continue }
					items.append(i)
				}
			}

			return Timeline(entries: [.init(requests, items: items,auth: auth)], policy: .atEnd)
		}

		struct WidgetEntry: TimelineEntry {
			let date: Date
			let auth: AuthInfo
			let requests: [MediaRequest]
			let items: [MediaItem]

			init(_ requests: [MediaRequest] = [], items: [MediaItem] = [], auth: AuthInfo, date: Date = .now) {
				self.date = date
				self.auth = auth
				self.requests = requests
				self.items = items
			}
		}

		func fetchRequests(_ session: SeerSession, page: Int = 1, limit: Int = 10) async -> [MediaRequest] {
			let queries: [URLQueryItem] = [
				.init(name: "sort", value: "added"),
				.init(name: "sortDirection", value: "desc"),
				.init(name: "mediaType", value: "all")
			]

			let endpoint = Requests.all(page, limit: limit)

			do {
				let (data, _, _) = try await Task.detached {
					try await session.raw(endpoint, queries: queries)
				}.value

				guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
					  let results = json["results"] as? [[String: Any]],
					  !results.isEmpty else {
					return []
				}

				return results.map { .init(data: $0) }
			} catch {
				if let urlError = error as? URLError, urlError.code == .cancelled {
					print("[fetchRequests] Cancelled (normal during refresh)")
					return []
				}

				print("[fetchRequests] Error: \(error.localizedDescription)")
				return []
			}
		}
	}
}
