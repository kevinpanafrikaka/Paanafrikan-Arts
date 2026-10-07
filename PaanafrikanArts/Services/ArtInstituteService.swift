//
//  ArtInstituteService.swift
//  PaanafrikanArts
//
//  Client réseau pour l'API publique Art Institute of Chicago. Aucune clé
//  requise, appel direct (pas de proxy).
//

import Foundation

enum ArtInstituteError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide."
        case .invalidResponse:
            return "Réponse du serveur invalide."
        case .httpError(let statusCode):
            return "Erreur serveur (code \(statusCode))."
        case .decodingFailed:
            return "Impossible de lire les données reçues."
        }
    }
}

struct ArtInstituteService: ArtInstituteServiceProtocol {
    static let shared = ArtInstituteService()

    private let baseURL = URL(string: "https://api.artic.edu/api/v1")!
    private let fields = "id,title,artist_display,image_id,date_display,medium_display,dimensions,place_of_origin,short_description,artwork_type_title"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchArtworks(page: Int = 1, limit: Int = 20) async throws -> ArtworksResponse {
        try await request(path: "artworks", queryItems: [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "fields", value: fields)
        ])
    }

    func searchArtworks(query: String, page: Int = 1, limit: Int = 20) async throws -> ArtworksResponse {
        try await request(path: "artworks/search", queryItems: [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "fields", value: fields)
        ])
    }

    private func request(path: String, queryItems: [URLQueryItem]) async throws -> ArtworksResponse {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw ArtInstituteError.invalidURL
        }
        components.queryItems = queryItems

        guard let url = components.url else {
            throw ArtInstituteError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        // Recommandé par la doc officielle (api.artic.edu/docs) pour permettre
        // à l'équipe de l'API de contacter les projets en cas de surcharge.
        urlRequest.setValue("PaanafrikanArts (kevinkandet05@gmail.com)", forHTTPHeaderField: "AIC-User-Agent")

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ArtInstituteError.invalidResponse
        }
        guard 200...299 ~= httpResponse.statusCode else {
            throw ArtInstituteError.httpError(statusCode: httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(ArtworksResponse.self, from: data)
        } catch {
            throw ArtInstituteError.decodingFailed(error)
        }
    }
}
