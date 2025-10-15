// Made by Lumaa

import Foundation

struct MediaPerson: Identifiable {
    var id: String
    var name: String
    /// Crew department or Character's name
    var description: String
    var personId: String
    private var profilePath: String?

    var isCast: Bool

    var personPath: URL? {
        guard let profilePath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w600_and_h900_bestv2\(profilePath)")
    }

    init(data: [String: Any], isCast: Bool = true) {
        self.isCast = isCast

        self.id = "\(UUID().uuidString)_\(data["id"] as! Int)"
        self.personId = data["creditId"] as! String
        self.name = data["name"] as! String
        self.description = data[isCast ? "character" : "department"] as! String
        self.profilePath = data["profilePath"] as? String
    }
}
