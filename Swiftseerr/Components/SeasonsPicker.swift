// Made by Lumaa

import SwiftUI

struct SeasonsPicker: View {
    @Environment(\.dismiss) private var dismiss: DismissAction

    var seasons: [ShowSeason.About]
    var disabledSeasons: [Int] = []

    @State private var selectedSeasons: [ShowSeason.About] = []

    var confirmAction: ([ShowSeason.About]) async -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    ForEach(self.seasons) { season in
                        self.seasonToggle(season)
                    }
                }
                .frame(width: 395, alignment: .center)
            }
            .navigationTitle(Text("seasons-picker.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) {
                        self.dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        Task {
                            defer { self.dismiss() }
                            await self.confirmAction(self.selectedSeasons)
                        }
                    }
                    .disabled(self.selectedSeasons.isEmpty)
                }
            }
        }
    }

    @ViewBuilder
    private func seasonToggle(_ season: ShowSeason.About) -> some View {
        let selected: Bool = self.selectedSeasons.contains(where: { $0.id == season.id })
        let disabled: Bool = self.disabledSeasons.contains(where: { $0 == season.seasonNumber })

        Button {
            if selected {
                self.selectedSeasons.removeAll { $0.id == season.id }
            } else {
                self.selectedSeasons.append(season)
            }
        } label: {
            HStack {
                Text(season.name)
                    .foregroundStyle(Color.primary)
                    .font(.title2.bold())
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if selected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentPurple)
                        .font(.callout)
                }
            }
            .padding(10.0)
            .background(Material.ultraThin)
            .clipShape(Capsule())
            .padding(.horizontal)
            .opacity(disabled ? 0.25 : 1.0)
        }
        .disabled(disabled)
    }
}
