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
                    let allSelected: Bool = self.selectedSeasons.count == self.seasons.filter { !self.disabledSeasons.contains($0.seasonNumber) }.count

                    Button {
                        if allSelected {
                            self.selectedSeasons = []
                        } else {
                            self.selectedSeasons = self.seasons.filter { !self.disabledSeasons.contains($0.seasonNumber) }
                        }
                    } label: {
                        self.seasonLabel(.init(name: String(localized: "all.seasons")), isSelected: allSelected)
                    }
                    .padding(.bottom, 20.0)

                    ForEach(self.seasons) { season in
                        self.seasonToggle(season)
                    }
                }
                #if !os(tvOS)
                .frame(width: 395, alignment: .center)
                #endif
            }
            .navigationTitle(Text("seasons-picker.title"))
            #if !os(tvOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
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
            self.seasonLabel(season, isSelected: selected, isDisabled: disabled)
        }
        .disabled(disabled)
        #if os(tvOS)
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        #endif
    }

    @ViewBuilder
    private func seasonLabel(_ season: ShowSeason.About, isSelected: Bool = false, isDisabled: Bool = false) -> some View {
        HStack {
            Text(season.name)
                .foregroundStyle(Color.primary)
                .font(.title2.bold())
                .multilineTextAlignment(.leading)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.accentPurple)
                    .font(.callout)
            }
        }
        .padding(10.0)
        #if !os(tvOS)
        .background(Material.ultraThin)
        .clipShape(Capsule())
        .padding(.horizontal)
        #endif
        .opacity(isDisabled ? 0.25 : 1.0)
    }
}
