//
//  FavoriteArtwork.swift
//  PaanafrikanArts
//
//  Persistance locale des favoris (SwiftData). "imageURL" est l'URL IIIF
//  déjà résolue et copiée au moment de l'ajout : hors-ligne, config.iiif_url
//  n'est pas disponible pour la reconstruire à partir de "image_id" seul.
//

import Foundation
import SwiftData

@Model
final class FavoriteArtwork {
    @Attribute(.unique) var id: Int
    var title: String
    var artistDisplay: String?
    var dateDisplay: String?
    var imageURL: String?
    var savedAt: Date

    init(id: Int, title: String, artistDisplay: String?, dateDisplay: String?, imageURL: String?, savedAt: Date = .now) {
        self.id = id
        self.title = title
        self.artistDisplay = artistDisplay
        self.dateDisplay = dateDisplay
        self.imageURL = imageURL
        self.savedAt = savedAt
    }
}

extension FavoriteArtwork {
    /// Pour ré-ouvrir ArtworkDetailView depuis un favori. medium/dimensions/
    /// placeOfOrigin/shortDescription/artworkTypeTitle ne sont pas
    /// sauvegardés hors-ligne, donc nil ici — ArtworkDetailView masque déjà
    /// gracieusement les sections correspondantes quand elles sont absentes.
    var asArtwork: Artwork {
        Artwork(
            id: id,
            title: title,
            artistDisplay: artistDisplay,
            imageId: nil,
            dateDisplay: dateDisplay,
            mediumDisplay: nil,
            dimensions: nil,
            placeOfOrigin: nil,
            shortDescription: nil,
            artworkTypeTitle: nil
        )
    }
}
