// Made by Lumaa

import Foundation

struct Network: Identifiable, Hashable, Equatable {
	let name: String
	let image: URL
	let endpoint: Discover

	let id: Int

	init(name: String, image: String, id: Int) {
		self.name = name
		self.image = URL(string: "https://image.tmdb.org/t/p/w780_filter(duotone,ffffff,bababa)" + image)!
		self.endpoint = Discover.studio(id)
		self.id = id
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(self.id)
	}

	static func ==(lhs: Self, rhs: Self) -> Bool {
		return lhs.id == rhs.id
	}
}

enum Networks: CaseIterable {
	case netflix
	case primeVideo
	case disneyPlus
	case appleTv
	case paramountPlus
	case hulu
	case hbo

	var network: Network {
		switch self {
			case .netflix:
				return .init(name: "Netflix", image: "/wwemzKWzjKYJFfCeiB57q3r4Bcm.png", id: 213)
			case .primeVideo:
				return .init(name: "Prime Video", image: "/ifhbNuuVnlwYy5oXA5VIb2YR8AZ.png", id: 1024)
			case .disneyPlus:
				return .init(name: "Disney+", image: "/gJ8VX6JSu3ciXHuC2dDGAo2lvwM.png", id: 2739)
			case .appleTv:
				return .init(name: "Apple TV", image: "/bngHRFi794mnMq34gfVcm9nDxN1.png", id: 2552)
			case .paramountPlus:
				return .init(name: "Paramount+", image: "/fi83B1oztoS47xxcemFdPMhIzK.png", id: 4330)
			case .hulu:
				return .init(name: "Hulu", image: "/pqUTCleNUiTLAVlelGxUgWn1ELh.png", id: 453)
			case .hbo:
				return .init(name: "HBO", image: "/tuomPhY2UtuPTqqFnKMVHvSb724.png", id: 49)
		}
	}
}

enum Studios: CaseIterable {
	case disney
	case marvel
	case sony
	case a24
	case _20thCentury
	case warnerBros
	case universal
	case paramount
	case pixar
	case dreamworks
	case dc

	var studio: Network {
		switch self {
			case .disney:
				return .init(name: "Disney", image: "/wdrCwmRnLFJhEoH8GSfymY85KHT.png", id: 2)
			case .marvel:
				return .init(name: "Marvel Studios", image: "/hUzeosd33nzE5MCNsZxCGEKTXaQ.png", id: 420)
			case .sony:
				return .init(name: "Sony Pictures", image: "/GagSvqWlyPdkFHMfQ3pNq6ix9P.png", id: 34)
			case .a24:
				return .init(name: "A24", image: "/1ZXsGaFPgrgS6ZZGS37AqD5uU12.png", id: 41077)
			case ._20thCentury:
				return .init(name: "20th Century Studios", image: "/h0rjX5vjW5r8yEnUBStFarjcLT4.png", id: 127928)
			case .warnerBros:
				return .init(name: "Warner Bros. Pictures", image: "/ky0xOc5OrhzkZ1N6KyUxacfQsCk.png", id: 174)
			case .universal:
				return .init(name: "Universal", image: "/8lvHyhjr8oUKOOy2dKXoALWKdp0.png", id: 33)
			case .paramount:
				return .init(name: "Paramount", image: "/fycMZt242LVjagMByZOLUGbCvv3.png", id: 4)
			case .pixar:
				return .init(name: "Pixar", image: "/1TjvGVDMYsj6JBxOAkUHpPEwLf7.png'", id: 3)
			case .dreamworks:
				return .init(name: "Dreamworks", image: "/kP7t6RwGz2AvvTkvnI1uteEwHet.png", id: 521)
			case .dc:
				return .init(name: "DC", image: "/2Tc1P3Ac8M479naPp1kYT3izLS5.png", id: 9993)
		}
	}
}
