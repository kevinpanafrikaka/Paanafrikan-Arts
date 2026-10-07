//
//  ArtworkThumbnail.swift
//  PaanafrikanArts
//
//  N'utilise pas AsyncImage : le CDN d'images (www.artic.edu) renvoie 403 à
//  toute requête sans header "Referer" (vérifié en direct), et AsyncImage
//  ne permet pas d'ajouter des headers custom à sa requête.
//
//  Depuis le 2026-09-14, www.artic.edu est en plus passé derrière un
//  challenge JS Cloudflare (le header Referer seul ne suffit plus). Sur un
//  403, le fetch bascule sur CloudflareChallengeResolver, qui récupère
//  l'image depuis une WKWebView plutôt que via URLSession (voir ce fichier
//  pour le détail : un simple cookie recopié ne suffit pas).
//

import SwiftUI
import UIKit

struct ArtworkThumbnail: View {
    let url: URL?
    var cornerRadius: CGFloat = 8
    /// `.fill` pour les vignettes de grille ET l'écran détail (carré/cadre
    /// 4:3 toujours entièrement rempli, quitte à rogner les bords si le
    /// format natif de l'œuvre diffère). `.fit` reste dispo si besoin d'un
    /// écran où l'œuvre entière doit rester visible sans recadrage.
    var contentMode: ContentMode = .fill

    @State private var image: UIImage?
    @State private var didFail = false

    var body: some View {
        // GeometryReader impose une taille de carte fixe, dictée uniquement
        // par le parent (ex: .aspectRatio(1, contentMode: .fit) posé sur
        // ArtworkThumbnail dans ArtworkGridCell). Le format natif de l'image
        // envoyée par l'API (portrait, paysage, carré...) n'a alors plus
        // aucune influence sur la taille de la carte : seul son contenu
        // interne est recadré (.fill) ou letterboxé (.fit) pour tenir
        // exactement dans ce cadre fixe.
        GeometryReader { geometry in
            ZStack {
                placeholder
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else if url != nil && !didFail {
                    ProgressView()
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .task(id: url) {
            await load()
        }
    }

    private func load() async {
        image = nil
        didFail = false
        guard let url else { return }

        switch await fetchImage(url: url) {
        case .success(let loadedImage):
            image = loadedImage
        case .blockedByCloudflare:
            // Le challenge de www.artic.edu lie le cookie à l'empreinte
            // réseau du moteur WebKit : on ne peut pas juste recopier le
            // cookie vers URLSession, il faut fetch l'image depuis la
            // WKWebView elle-même. Voir CloudflareChallengeResolver.swift.
            if let data = await CloudflareChallengeResolver.shared.fetchImageData(for: url),
               let loadedImage = UIImage(data: data) {
                image = loadedImage
            } else {
                didFail = true
            }
        case .failure:
            didFail = true
        }
    }

    private enum FetchResult {
        case success(UIImage)
        case blockedByCloudflare
        case failure
    }

    private func fetchImage(url: URL) async -> FetchResult {
        var request = URLRequest(url: url)
        request.setValue("https://www.artic.edu/", forHTTPHeaderField: "Referer")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return .failure }
            guard 200...299 ~= httpResponse.statusCode else {
                return httpResponse.statusCode == 403 ? .blockedByCloudflare : .failure
            }
            guard let loadedImage = UIImage(data: data) else { return .failure }
            return .success(loadedImage)
        } catch {
            return .failure
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.secondary.opacity(0.15))
            .overlay {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
    }
}
