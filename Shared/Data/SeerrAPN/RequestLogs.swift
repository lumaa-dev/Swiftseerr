// Made by Lumaa

import Foundation

struct RequestLogs: Decodable {
	let success: [Self.Log]
	let errors: [Self.Log]

	init(success: [Self.Log] = [], errors: [Self.Log] = []) {
		self.success = success
		self.errors = errors
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.success = try container.decode([RequestLogs.Log].self, forKey: .success)
		self.errors = try container.decode([RequestLogs.Log].self, forKey: .errors)
	}

	enum CodingKeys: CodingKey {
		case success
		case errors
	}

	struct Log: Decodable {
		let date: Date
		let result: String
		let status: RequestLogs.Status

		init(from decoder: any Decoder) throws {
			let container: KeyedDecodingContainer<RequestLogs.Log.CodingKeys> = try decoder.container(keyedBy: RequestLogs.Log.CodingKeys.self)
			let dateStr = try container.decode(String.self, forKey: Self.CodingKeys.date)
			let formatter = ISO8601DateFormatter()
			formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

			self.date = formatter.date(from: dateStr) ?? .distantPast
			self.result = try container.decode(String.self, forKey: Self.CodingKeys.result)
			self.status = try container.decode(RequestLogs.Status.self, forKey: Self.CodingKeys.status)
		}

		enum CodingKeys: CodingKey {
			case date
			case result
			case status
		}
	}

	enum Status: String, Decodable {
		case SUCCESS = "success"
		case FAIL = "fail"
	}
}

extension [RequestLogs.Log] {
	func defaultSort() -> [RequestLogs.Log] {
		self.sorted(by: { $0.date > $1.date })
	}
}
