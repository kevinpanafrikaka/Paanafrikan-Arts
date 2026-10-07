//
//  ArtInstituteServiceProtocol.swift
//  PaanafrikanArts
//
//  Abstraction du service réseau, pour pouvoir injecter un mock dans les
//  tests des ViewModels sans appel réseau réel.
//

import Foundation

protocol ArtInstituteServiceProtocol {
    func fetchArtworks(page: Int, limit: Int) async throws -> ArtworksResponse

    /// Utilise /artworks/search, pas "&q=" sur /artworks : vérifié en direct,
    /// ce dernier ne filtre pas réellement les résultats côté API.
    func searchArtworks(query: String, page: Int, limit: Int) async throws -> ArtworksResponse
}
