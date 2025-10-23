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

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            if let url {
                                UIApplication.shared.open(url)
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
