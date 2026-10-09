// Made by Lumaa

import SwiftUI
import SwiftData

@Model
final class AuthInfo: Codable, Identifiable {
    var username: String = ""
    var password: String = ""
    var address: String = ""
    var provider: AuthInfo.Providers? = nil
    var isDefault: Bool = false

    var id: String {
        "\(username)_\(password):\(address)"
    }

    init(username: String? = nil, password: String? = nil, address: String? = nil, provider: AuthInfo.Providers? = nil, isDefault: Bool = false) {
        self.username = username ?? ""
        self.password = password ?? ""
        self.address = address ?? ""
        self.provider = provider
        self.isDefault = isDefault
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.username = try container.decode(String.self, forKey: .username)
        self.password = try container.decode(String.self, forKey: .password)
        self.address = try container.decode(String.self, forKey: .address)
        self.provider = try container.decodeIfPresent(Self.Providers.self, forKey: .provider)
        self.isDefault = try container.decodeIfPresent(Bool.self, forKey: .isDefault) ?? false
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.username, forKey: .username)
        try container.encode(self.password, forKey: .password)
        try container.encode(self.address, forKey: .address)
        try container.encodeIfPresent(self.provider, forKey: .provider)
        try container.encode(self.isDefault, forKey: .isDefault)
    }

    enum CodingKeys: CodingKey {
        case username
        case password
        case address
        case provider
        case isDefault
    }

    enum Providers: CaseIterable, Codable {
        case jellyfin
        case local

        var string: String {
            switch self {
                case .jellyfin:
                    "Jellyfin"
                case .local:
                    String(localized: "provider.local")
            }
        }

        var symbol: Image {
            switch self {
                case .jellyfin:
                    Image(.jellyfin)
                case .local:
                    Image(systemName: "person.crop.circle.dashed")
            }
        }
    }
}
