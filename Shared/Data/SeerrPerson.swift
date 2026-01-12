// Made by Lumaa

import SwiftUI

struct SeerrPerson: Identifiable {
    let id: Int
    let name: String
    let gender: Gender
    let bio: String?
    let birthday: Date?
    let deathday: Date?

    private let profileImg: String?

    var image: URL? {
        guard let profileImg else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w600_and_h900_bestv2\(profileImg)")
    }

    var age: Int? {
        guard let birthday else { return nil }
        let age: Double = (Date.now.timeIntervalSince1970 - birthday.timeIntervalSince1970) / 3600 / 24 / 365
        return Int(age.rounded(.down))
    }

    init(data: [String: Any]) {
        let personDate = DateFormatter()
        personDate.dateFormat = "yyyy-MM-DD"

        self.id = data["id"] as! Int
        self.name = data["name"] as! String
        self.gender = data["gender"] as! Int == 2 ? Gender.male : Gender.female
        self.bio = (data["biography"] as? String ?? "").isEmpty ? nil : data["biography"] as? String
        self.profileImg = data["profilePath"] as? String

        if let b = data["birthday"] as? String {
            self.birthday = personDate.date(from: b)
        } else {
            self.birthday = nil
        }

        if let d = data["deathday"] as? String {
            self.deathday = personDate.date(from: d)
        } else {
            self.deathday = nil
        }
    }

    enum Gender {
        case male
        case female

        var symbol: String {
            switch self {
                case .male:
                    return "figure.stand"
                case .female:
                    return "figure.stand.dress"
            }
        }

        var color: Color {
            switch self {
                case .male:
                    Color.blue
                case .female:
                    Color.pink
            }
        }
    }
}
