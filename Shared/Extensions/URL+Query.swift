// Made by Lumaa

import Foundation

extension [URLQueryItem] {
    func encodeQueryItemValues() -> [URLQueryItem] {
        return self.map { queryItem in
            let encodedValue = queryItem.value?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            return URLQueryItem(name: queryItem.name, value: encodedValue)
        }
    }

	var asString: String {
		let mapped: [String] = self.map {
			return "\($0.name)=\($0.value ?? "")"
		}
		return mapped.joined(separator: "&")
	}
}
