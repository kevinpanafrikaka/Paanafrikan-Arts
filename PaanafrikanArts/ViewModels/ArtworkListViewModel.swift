//
//  ArtworkListViewModel.swift
//  PaanafrikanArts
//

import Foundation

enum ArtworkListState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
}

@Observable
final class ArtworkListViewModel {
    private(set) var state: ArtworkListState = .idle
    private(set) var artworks: [Artwork] = []
    private(set) var iiifBaseURL: String?
    private(set) var isLoadingMore = false
    private(set) var hasMorePages = false
    var searchText: String = ""

    private let service: ArtInstituteServiceProtocol
    private let pageSize = 30
    private var currentPage = 1
    private var currentQuery: String?

    init(service: ArtInstituteServiceProtocol = ArtInstituteService.shared) {
        self.service = service
    }

    func load() async {
        currentQuery = nil
        state = .loading
        await fetchFirstPage(query: nil)
    }

    func search() async {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            await load()
            return
        }
        currentQuery = trimmed
        state = .loading
        await fetchFirstPage(query: trimmed)
    }

    func loadMore() async {
        guard hasMorePages, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        let nextPage = currentPage + 1
        do {
            let response = try await fetch(page: nextPage, query: currentQuery)
            // Mélangé seulement à l'intérieur du nouveau lot : les œuvres déjà
            // affichées ne changent pas de position pendant le scroll infini.
            artworks += response.data.shuffled()
            iiifBaseURL = response.config.iiifUrl
            currentPage = nextPage
            hasMorePages = nextPage < response.pagination.totalPages
        } catch {
            // Échec silencieux : la liste déjà chargée reste affichée, le
            // scroll infini retentera au prochain passage en bas de la liste.
        }
    }

    private func fetchFirstPage(query: String?) async {
        do {
            let response = try await fetch(page: 1, query: query)
            artworks = response.data.shuffled()
            iiifBaseURL = response.config.iiifUrl
            currentPage = 1
            hasMorePages = response.pagination.totalPages > 1
            state = .loaded
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    private func fetch(page: Int, query: String?) async throws -> ArtworksResponse {
        if let query {
            return try await service.searchArtworks(query: query, page: page, limit: pageSize)
        }
        return try await service.fetchArtworks(page: page, limit: pageSize)
    }

    func imageURL(for artwork: Artwork) -> URL? {
        guard let iiifBaseURL, let imageId = artwork.imageId else { return nil }
        return IIIFImageURLBuilder.imageURL(iiifBaseURL: iiifBaseURL, imageId: imageId)
    }
}
