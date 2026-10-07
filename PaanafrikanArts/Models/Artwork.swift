//
//  Artwork.swift
//  PaanafrikanArts
//
//  Modèle correspondant aux réponses de l'API Art Institute of Chicago
//  (https://api.artic.edu/api/v1/artworks). L'URL de l'image n'est jamais
//  fournie directement : elle se construit à partir de "config.iiif_url"
//  et de "image_id" (voir IIIFImageURLBuilder). "image_id" est optionnel,
//  certaines œuvres n'ont pas d'image numérisée.
//

import Foundation

struct Artwork: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let artistDisplay: String?
    let imageId: String?
    let dateDisplay: String?
    let mediumDisplay: String?
    let dimensions: String?
    let placeOfOrigin: String?
    /// Texte simple (pas de HTML), contrairement à "description" qui contient
    /// des balises <p>/<em> — plus pratique à afficher et à traduire tel quel.
    let shortDescription: String?
    /// Catégorie simple (ex: "Painting", "Sculpture"). L'API expose aussi
    /// des listes plus fines (category_titles, classification_titles,
    /// subject_titles) mais celle-ci est la seule valeur unique, courte,
    /// adaptée à un affichage direct.
    let artworkTypeTitle: String?

    enum CodingKeys: String, CodingKey {
        case id, title, dimensions
        case artistDisplay = "artist_display"
        case imageId = "image_id"
        case dateDisplay = "date_display"
        case mediumDisplay = "medium_display"
        case placeOfOrigin = "place_of_origin"
        case shortDescription = "short_description"
        case artworkTypeTitle = "artwork_type_title"
    }
}

struct Pagination: Codable {
    let total: Int
    let limit: Int
    let offset: Int
    let totalPages: Int
    let currentPage: Int

    enum CodingKeys: String, CodingKey {
        case total, limit, offset
        case totalPages = "total_pages"
        case currentPage = "current_page"
    }
}

/// Fournit la base des URLs d'image IIIF. Toujours présente dans la réponse,
/// jamais codée en dur côté client.
struct APIConfig: Codable {
    let iiifUrl: String

    enum CodingKeys: String, CodingKey {
        case iiifUrl = "iiif_url"
    }
}

/// Réponse de GET /api/v1/artworks et GET /api/v1/artworks/search
struct ArtworksResponse: Codable {
    let pagination: Pagination
    let data: [Artwork]
    let config: APIConfig
}
