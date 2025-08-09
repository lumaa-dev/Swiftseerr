// Made by Lumaa

import Foundation

struct AuthInfo: Codable {
    var username: String = ""
    var password: String = ""
    var address: String = ""
    var token: String = ""

    init(username: String? = nil, password: String? = nil, address: String? = nil, token: String? = nil) {
        self.username = username ?? ""
        self.password = password ?? ""
        self.address = address ?? ""
        self.token = token ?? ""
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.username = try container.decode(String.self, forKey: .username)
        self.password = try container.decode(String.self, forKey: .password)
        self.address = try container.decode(String.self, forKey: .address)
        self.token = try container.decode(String.self, forKey: .token)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.username, forKey: .username)
        try container.encode(self.password, forKey: .password)
        try container.encode(self.address, forKey: .address)
        try container.encode(self.token, forKey: .token)
    }

    enum CodingKeys: CodingKey {
        case username
        case password
        case address
        case token
    }
}
