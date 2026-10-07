//
//  FavoritesViewModelTests.swift
//  PaanafrikanArtsTests
//

import Testing
import SwiftData
@testable import PaanafrikanArts

struct FavoritesViewModelTests {

    @Test func toggleAddsThenRemovesFavorite() async throws {
        let container = try ModelContainer(
            for: FavoriteArtwork.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let viewModel = FavoritesViewModel()
        let artwork = Artwork(
            id: 1,
            title: "Test",
            artistDisplay: "Artist",
            imageId: "abc",
            dateDisplay: "2024",
            mediumDisplay: nil,
            dimensions: nil,
            placeOfOrigin: nil,
            shortDescription: nil,
            artworkTypeTitle: nil
        )
        let imageURL = URL(string: "https://www.artic.edu/iiif/2/abc/full/843,/0/default.jpg")

        viewModel.toggle(artwork: artwork, imageURL: imageURL, context: context)
        #expect(viewModel.isFavorite(id: 1))
        #expect(viewModel.favorites.first?.imageURL == imageURL?.absoluteString)

        viewModel.toggle(artwork: artwork, imageURL: imageURL, context: context)
        #expect(!viewModel.isFavorite(id: 1))
    }
}
