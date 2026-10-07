//
//  FavoritesView.swift
//  PaanafrikanArts
//
//  Fonctionne hors-ligne : les favoris sont lus depuis SwiftData, aucun
//  appel réseau.
//

import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(FavoritesViewModel.self) private var favoritesViewModel
    @Environment(\.modelContext) private var modelContext

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 12)]

    var body: some View {
        NavigationStack {
            Group {
                if favoritesViewModel.favorites.isEmpty {
                    ContentUnavailableView(
                        "Aucun favori",
                        systemImage: "heart",
                        description: Text("Ajoute des œuvres depuis leur écran de détail.")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(favoritesViewModel.favorites, id: \.id) { favorite in
                                NavigationLink {
                                    ArtworkDetailView(
                                        artwork: favorite.asArtwork,
                                        imageURL: favorite.imageURL.flatMap(URL.init(string:))
                                    )
                                } label: {
                                    ArtworkGridCell(
                                        title: favorite.title,
                                        subtitle: favorite.artistDisplay,
                                        imageURL: favorite.imageURL.flatMap(URL.init(string:))
                                    )
                                }
                                .buttonStyle(.plain)
                                .overlay(alignment: .topTrailing) {
                                    Button {
                                        favoritesViewModel.remove(favorite, context: modelContext)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .symbolRenderingMode(.palette)
                                            .foregroundStyle(.white, .black.opacity(0.6))
                                            .font(.title3)
                                    }
                                    .padding(6)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Favoris")
            .task {
                favoritesViewModel.refresh(context: modelContext)
            }
        }
    }
}
