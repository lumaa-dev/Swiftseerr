// Made by Lumaa

import SwiftUI

protocol ViewRepresentable {
	associatedtype Content = View

	@ContentBuilder
	var label: Content { get }
}
