// Made by Lumaa

import SwiftUI

struct NetworkCard: View {
	let network: Network
	private let isStudio: Bool

	init(_ network: Network, isStudio: Bool) {
		self.network = network
		self.isStudio = isStudio
	}

	init(_ networks: Networks) {
		self.network = networks.network
		self.isStudio = false
	}

	init(_ studios: Studios) {
		self.network = studios.studio
		self.isStudio = true
	}

	var body: some View {
		NavigationLink(value: Navigator.Paths.items(LocalizedStringKey(self.network.name), endpoint: self.isStudio ? Discover.studio(self.network.id) : Discover.network(self.network.id))) {
			self.label
		}
	}

    private var label: some View {
		#if !os(macOS)
		RoundedRectangle(cornerRadius: 15.0)
			.fill(Color.gray.opacity(0.2))
			.frame(width: 200, height: 100)
			.overlay {
				self.image
			}
		#else
		self.image
			.padding(20.0)
		#endif
    }

	private var image: some View {
		AsyncImage(url: network.image) { image in
			image
				.resizable()
				.scaledToFit()
				.frame(width: 140, height: 60, alignment: .center)
		} placeholder: {
			EmptyView()
		}
	}
}

#Preview {
	NetworkCard(Networks.appleTv)
}
