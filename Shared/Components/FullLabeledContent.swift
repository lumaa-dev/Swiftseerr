// Made by Lumaa

import SwiftUI

struct FullLabeledContent: LabeledContentStyle {
	func makeBody(configuration: Configuration) -> some View {
		HStack {
			configuration.label
				.frame(maxWidth: .infinity, alignment: .leading)

			configuration.content
				.foregroundStyle(Color.secondary)
				.frame(alignment: .trailing)
		}
		.frame(maxWidth: .infinity)
	}
}

extension LabeledContentStyle where Self == FullLabeledContent {
	static var fullWidth: Self {
		return .init()
	}
}
