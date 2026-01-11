// Made by Lumaa

import SwiftUI
import WebKit

struct CleanWebView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction

    let url: URL?

    init(_ url: URL?) {
        self.url = url
    }

    var body: some View {
        NavigationStack {
            WebView(url: self.url)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .close) {
                            self.dismiss()
                        }
                    }

                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            if let url {
                                #if canImport(UIKit)
                                UIApplication.shared.open(url)
                                #else
                                NSWorkspace.shared.open(url)
                                #endif
                            }
                        } label: {
                            Label("open.safari", systemImage: "safari")
                        }
                    }
                }
        }
    }
}

#Preview {
    CleanWebView(URL(string: "https://lumaa.fr/"))
}
