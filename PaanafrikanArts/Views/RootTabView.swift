//
//  RootTabView.swift
//  PaanafrikanArts
//

import SwiftUI
import SwiftData

struct RootTabView: View {
    @State private var favoritesViewModel = FavoritesViewModel()

    var body: some View {
        TabView {
            ArtworkListView()
                .tabItem { Label("Œuvres d'Art", systemImage: "square.grid.2x2") }

            FavoritesView()
                .tabItem { Label("Favoris", systemImage: "heart.fill") }
        }
        .environment(favoritesViewModel)
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: FavoriteArtwork.self, inMemory: true)
}
