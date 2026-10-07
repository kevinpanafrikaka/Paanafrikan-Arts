//
//  ArtworkGridCell.swift
//  PaanafrikanArts
//

import SwiftUI

struct ArtworkGridCell: View {
    let title: String
    let subtitle: String?
    let imageURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ArtworkThumbnail(url: imageURL)
                .aspectRatio(1, contentMode: .fit)

            // Hauteur fixe : les titres de longueur variable donnaient des
            // cellules de hauteurs différentes sur une même ligne de la grille.
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(height: 46, alignment: .topLeading)
        }
    }
}
