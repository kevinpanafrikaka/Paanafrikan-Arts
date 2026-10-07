//
//  FavoritesViewModel.swift
//  PaanafrikanArts
//
//  Le ModelContext est passé par méthode plutôt que stocké à l'init : il
//  vient de @Environment(\.modelContext) côté vue, non disponible de façon
//  fiable dans l'init d'un objet créé via @State.
//

import Foundation
import SwiftData

@Observable
final class FavoritesViewModel {
    private(set) var favorites: [FavoriteArtwork] = []

    func refresh(context: ModelContext) {
        let descriptor = FetchDescriptor<FavoriteArtwork>(sortBy: [SortDescriptor(\.savedAt, order: .reverse)])
        favorites = (try? context.fetch(descriptor)) ?? []
    }

    func isFavorite(id: Int) -> Bool {
        favorites.contains { $0.id == id }
    }

    func remove(_ favorite: FavoriteArtwork, context: ModelContext) {
        context.delete(favorite)
        refresh(context: context)
    }

    func toggle(artwork: Artwork, imageURL: URL?, context: ModelContext) {
        if let existing = favorites.first(where: { $0.id == artwork.id }) {
            context.delete(existing)
        } else {
            let favorite = FavoriteArtwork(
                id: artwork.id,
                title: artwork.title,
                artistDisplay: artwork.artistDisplay,
                dateDisplay: artwork.dateDisplay,
                imageURL: imageURL?.absoluteString
            )
            context.insert(favorite)
        }
        refresh(context: context)
    }
}
