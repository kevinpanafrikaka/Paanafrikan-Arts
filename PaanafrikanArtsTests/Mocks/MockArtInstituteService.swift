//
//  MockArtInstituteService.swift
//  PaanafrikanArtsTests
//

import Foundation
@testable import PaanafrikanArts

final class MockArtInstituteService: ArtInstituteServiceProtocol {
    var resultToReturn: Result<ArtworksResponse, Error> = .success(
        ArtworksResponse(
            pagination: Pagination(total: 0, limit: 20, offset: 0, totalPages: 0, currentPage: 1),
            data: [],
            config: APIConfig(iiifUrl: "")
        )
    )
    /// Réponse spécifique à une page, utile pour tester loadMore(). Retombe
    /// sur `resultToReturn` si la page n'a pas d'entrée dédiée.
    var resultsByPage: [Int: Result<ArtworksResponse, Error>] = [:]

    func fetchArtworks(page: Int, limit: Int) async throws -> ArtworksResponse {
        try (resultsByPage[page] ?? resultToReturn).get()
    }

    func searchArtworks(query: String, page: Int, limit: Int) async throws -> ArtworksResponse {
        try (resultsByPage[page] ?? resultToReturn).get()
    }
}
