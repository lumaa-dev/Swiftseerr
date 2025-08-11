// Made by Lumaa

import Foundation

struct AuthInfo: Codable {
    var username: String = ""
    var password: String = ""
    var address: String = ""
    var provider: Self.Providers? = nil

    init(username: String? = nil, password: String? = nil, address: String? = nil, provider: Self.Providers? = nil) {
        self.username = username ?? ""
        self.password = password ?? ""
        self.address = address ?? ""
        self.provider = provider
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.username = try container.decode(String.self, forKey: .username)
        self.password = try container.decode(String.self, forKey: .password)
        self.address = try container.decode(String.self, forKey: .address)
        self.provider = try container.decodeIfPresent(Self.Providers.self, forKey: .provider)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.username, forKey: .username)
        try container.encode(self.password, forKey: .password)
        try container.encode(self.address, forKey: .address)
        try container.encodeIfPresent(self.provider, forKey: .provider)
    }

    enum CodingKeys: CodingKey {
        case username
        case password
        case address
        case provider
    }

    enum Providers: CaseIterable, Codable {
        case jellyfin
        case local
    }
}
