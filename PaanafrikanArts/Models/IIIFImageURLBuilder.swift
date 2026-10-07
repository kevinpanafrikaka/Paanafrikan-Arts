//
//  IIIFImageURLBuilder.swift
//  PaanafrikanArts
//
//  Format vérifié sur la doc officielle (api.artic.edu/docs/#images) :
//  {iiif_url}/{image_id}/full/{width},/0/default.jpg
//  Ne jamais coder en dur la base "iiif_url" : elle vient toujours de
//  config.iiif_url dans la réponse de l'API.
//

import Foundation

enum IIIFImageURLBuilder {
    static func imageURL(iiifBaseURL: String, imageId: String, width: Int = 843) -> URL? {
        URL(string: "\(iiifBaseURL)/\(imageId)/full/\(width),/0/default.jpg")
    }
}
