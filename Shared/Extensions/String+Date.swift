// Made by Lumaa

import Foundation

extension String {
    var seerrDate: Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        return dateFormatter.date(from: self)
    }

	var isoDate: Date? {
		let iso = ISO8601DateFormatter()
		iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

		return iso.date(from: self)
	}
}
