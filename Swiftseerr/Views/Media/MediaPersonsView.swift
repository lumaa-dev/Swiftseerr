// Made by Lumaa

import SwiftUI

struct MediaPersonsView: View {
    let title: LocalizedStringKey
    let persons: [MediaPerson]

    private var columns: [GridItem] {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return [GridItem(.adaptive(minimum: 200), spacing: 16)]
        } else {
            return Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
        }
    }

    init(with persons: [MediaPerson], title: LocalizedStringKey) {
        self.title = title
        self.persons = persons
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(persons) { c in
                    PersonPlate(c)
                }
            }
            .padding()
        }
        .navigationTitle(self.title)
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background {
            Color.bgPurple.ignoresSafeArea()
        }
    }
}
