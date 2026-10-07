//
//  ArtworkListViewModelTests.swift
//  PaanafrikanArtsTests
//

import Testing
@testable import PaanafrikanArts

struct ArtworkListViewModelTests {

    @Test func loadPopulatesArtworksAndBaseURLOnSuccess() async throws {
        let mock = MockArtInstituteService()
        mock.resultToReturn = .success(.fixture)
        let viewModel = ArtworkListViewModel(service: mock)

        await viewModel.load()

        #expect(viewModel.artworks == ArtworksResponse.fixture.data)
        #expect(viewModel.iiifBaseURL == "https://www.artic.edu/iiif/2")
        #expect(viewModel.state == .loaded)
    }

    @Test func loadSetsErrorStateOnFailure() async throws {
        let mock = MockArtInstituteService()
        mock.resultToReturn = .failure(ArtInstituteError.httpError(statusCode: 500))
        let viewModel = ArtworkListViewModel(service: mock)

        await viewModel.load()

        #expect(viewModel.artworks.isEmpty)
        guard case .error = viewModel.state else {
            Issue.record("Expected .error state, got \(viewModel.state)")
            return
        }
    }

    @Test func loadMoreAppendsNextPageAndUpdatesHasMorePages() async throws {
        let mock = MockArtInstituteService()
        mock.resultToReturn = .success(.fixture) // page 1, totalPages: 2
        mock.resultsByPage[2] = .success(.fixturePage2)
        let viewModel = ArtworkListViewModel(service: mock)

        await viewModel.load()
        #expect(viewModel.hasMorePages)
        #expect(viewModel.artworks.count == 1)

        await viewModel.loadMore()

        #expect(viewModel.artworks.count == 2)
        #expect(viewModel.artworks.last == ArtworksResponse.fixturePage2.data[0])
        #expect(!viewModel.hasMorePages)
    }

    @Test func imageURLBuildsIIIFURLFromBaseAndImageId() async throws {
        let mock = MockArtInstituteService()
        mock.resultToReturn = .success(.fixture)
        let viewModel = ArtworkListViewModel(service: mock)
        await viewModel.load()

        let url = viewModel.imageURL(for: ArtworksResponse.fixture.data[0])

        #expect(url?.absoluteString == "https://www.artic.edu/iiif/2/2d484387-2509-5e8e-2c43-22f9981972eb/full/843,/0/default.jpg")
    }
}

extension ArtworksResponse {
    static let fixture = ArtworksResponse(
        pagination: Pagination(total: 2, limit: 1, offset: 0, totalPages: 2, currentPage: 1),
        data: [
            Artwork(
                id: 27992,
                title: "A Sunday on La Grande Jatte",
                artistDisplay: "Georges Seurat",
                imageId: "2d484387-2509-5e8e-2c43-22f9981972eb",
                dateDisplay: "1884-86",
                mediumDisplay: "Oil on canvas",
                dimensions: "207.5 × 308.1 cm",
                placeOfOrigin: "France",
                shortDescription: "Georges Seurat depicted Parisians enjoying leisure activities.",
                artworkTypeTitle: "Painting"
            )
        ],
        config: APIConfig(iiifUrl: "https://www.artic.edu/iiif/2")
    )

    static let fixturePage2 = ArtworksResponse(
        pagination: Pagination(total: 2, limit: 1, offset: 1, totalPages: 2, currentPage: 2),
        data: [
            Artwork(
                id: 111628,
                title: "Nighthawks",
                artistDisplay: "Edward Hopper",
                imageId: "4d7ab6bf-1c6c-4dc9-c3bc-cc5a852aa4e3",
                dateDisplay: "1942",
                mediumDisplay: "Oil on canvas",
                dimensions: "84.1 × 152.4 cm",
                placeOfOrigin: "United States",
                shortDescription: "A view of a downtown diner at night, seen through a large glass window.",
                artworkTypeTitle: "Painting"
            )
        ],
        config: APIConfig(iiifUrl: "https://www.artic.edu/iiif/2")
    )
}
