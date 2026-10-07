//
//  ArtworkDetailView.swift
//  PaanafrikanArts
//
//  Traduction : framework Translation d'Apple (on-device, iOS 17.4+, aucune
//  clé API) — cohérent avec le reste du projet qui n'appelle que des
//  services sans clé. Ne fonctionne pas dans le Simulateur (le modèle de
//  langue doit être téléchargé, ce qui nécessite un vrai appareil).
//

import SwiftUI
import SwiftData
import Translation

struct ArtworkDetailView: View {
    let artwork: Artwork
    let imageURL: URL?

    @Environment(FavoritesViewModel.self) private var favoritesViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var zoomScale: CGFloat = 1
    @State private var lastZoomScale: CGFloat = 1
    @State private var dragOffset: CGSize = .zero
    @State private var lastDragOffset: CGSize = .zero

    @State private var translationConfig: TranslationSession.Configuration?
    @State private var translatedDescription: String?
    @State private var isTranslating = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                zoomableImage

                VStack(alignment: .leading, spacing: 4) {
                    Text(artwork.title)
                        .font(.title2)
                        .fontWeight(.semibold)

                    if let artistDisplay = artwork.artistDisplay {
                        Text(artistDisplay)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }

                infoSection
                descriptionSection
            }
            .padding()
        }
        .navigationTitle(artwork.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                FavoriteButton(isFavorite: favoritesViewModel.isFavorite(id: artwork.id)) {
                    favoritesViewModel.toggle(artwork: artwork, imageURL: imageURL, context: modelContext)
                }
            }
        }
        .task {
            favoritesViewModel.refresh(context: modelContext)
        }
        .translationTask(translationConfig) { session in
            guard let text = artwork.shortDescription else { return }
            isTranslating = true
            defer { isTranslating = false }
            do {
                let response = try await session.translate(text)
                translatedDescription = response.targetText
            } catch {
                translatedDescription = nil
            }
        }
    }

    // MARK: - Image zoomable

    private var zoomableImage: some View {
        ArtworkThumbnail(url: imageURL, cornerRadius: 12, contentMode: .fill)
            .aspectRatio(4 / 3, contentMode: .fit)
            .scaleEffect(zoomScale)
            .offset(dragOffset)
            .gesture(magnifyGesture.simultaneously(with: dragGesture))
            .onTapGesture(count: 2) {
                withAnimation(.spring()) {
                    zoomScale = 1
                    lastZoomScale = 1
                    dragOffset = .zero
                    lastDragOffset = .zero
                }
            }
    }

    private var magnifyGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                zoomScale = max(1, min(lastZoomScale * value, 4))
            }
            .onEnded { _ in
                lastZoomScale = zoomScale
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard zoomScale > 1 else { return }
                dragOffset = CGSize(
                    width: lastDragOffset.width + value.translation.width,
                    height: lastDragOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastDragOffset = dragOffset
            }
    }

    // MARK: - Infos

    @ViewBuilder
    private var infoSection: some View {
        let rawRows: [(String, String?)] = [
            ("Catégorie", artwork.artworkTypeTitle),
            ("Date", artwork.dateDisplay),
            ("Medium", artwork.mediumDisplay),
            ("Dimensions", artwork.dimensions),
            ("Origine", artwork.placeOfOrigin)
        ]
        let rows = rawRows.compactMap { label, value in value.map { (label, $0) } }

        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(rows, id: \.0) { label, value in
                    HStack(alignment: .top, spacing: 12) {
                        Text(label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 80, alignment: .leading)
                        Text(value)
                            .font(.subheadline)
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Description + traduction

    @ViewBuilder
    private var descriptionSection: some View {
        if let description = artwork.shortDescription {
            VStack(alignment: .leading, spacing: 8) {
                Text(translatedDescription ?? description)
                    .font(.body)

                if translatedDescription != nil {
                    Button("Voir en anglais") {
                        translatedDescription = nil
                    }
                    .font(.caption)
                } else {
                    Button {
                        translationConfig = TranslationSession.Configuration(
                            source: Locale.Language(identifier: "en"),
                            target: Locale.Language(identifier: "fr")
                        )
                    } label: {
                        if isTranslating {
                            ProgressView()
                        } else {
                            Label("Traduire en français", systemImage: "character.book.closed")
                        }
                    }
                    .font(.caption)
                    .disabled(isTranslating)
                }
            }
        }
    }
}
