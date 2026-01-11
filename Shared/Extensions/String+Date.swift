// Made by Lumaa

import Foundation

extension String {
    var seerrDate: Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        return dateFormatter.date(from: self)
    }
}
