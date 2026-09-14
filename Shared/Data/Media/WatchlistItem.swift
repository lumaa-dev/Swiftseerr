// Made by Lumaa

import Foundation
import SwiftData

@Model
final class WatchlistItem: Codable, Identifiable {
	var id: Int = 0
	var posterPath: String? = nil
	var name: String = ""
	var type: ItemType = ItemType.unknown

	init(id: Int, posterPath: String? = nil, name: String, type: ItemType) {
		self.id = id
		self.posterPath = posterPath
		self.name = name
		self.type = type
	}

	init(from item: MediaItem) {
		self.id = item.id
		self.posterPath = item.posterPath
		self.name = item.title
		self.type = item.type
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: Self.CodingKeys.self)
		self.id = try container.decode(Int.self, forKey: .id)
		self.posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
		self.name = try container.decode(String.self, forKey: .name)
		self.type = try container.decode(ItemType.self, forKey: .type)
	}

	func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: Self.CodingKeys.self)
		try container.encode(self.id, forKey: .id)
		try container.encodeIfPresent(self.posterPath, forKey: .posterPath)
		try container.encode(self.name, forKey: .name)
		try container.encode(self.type, forKey: .type)
	}

	enum CodingKeys: CodingKey {
		case id
		case posterPath
		case name
		case type
	}
}
