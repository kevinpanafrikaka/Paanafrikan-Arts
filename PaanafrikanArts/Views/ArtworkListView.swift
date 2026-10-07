//
//  ArtworkListView.swift
//  PaanafrikanArts
//

import SwiftUI

struct ArtworkListView: View {
    @State private var viewModel = ArtworkListViewModel()
    @Namespace private var transitionNamespace

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 12)]

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Œuvres d'Art")
                .navigationDestination(for: Artwork.self) { artwork in
                    ArtworkDetailView(artwork: artwork, imageURL: viewModel.imageURL(for: artwork))
                        .navigationTransition(.zoom(sourceID: artwork.id, in: transitionNamespace))
                }
                .searchable(text: $viewModel.searchText, prompt: "Rechercher une œuvre")
                .onSubmit(of: .search) {
                    Task { await viewModel.search() }
                }
                .onChange(of: viewModel.searchText) { _, newValue in
                    if newValue.isEmpty {
                        Task { await viewModel.load() }
                    }
                }
                .task {
                    if viewModel.state == .idle {
                        await viewModel.load()
                    }
                }
                .refreshable {
                    await viewModel.load()
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            skeletonGrid
        case .loading:
            if viewModel.artworks.isEmpty {
                skeletonGrid
            } else {
                grid
            }
        case .error(let message):
            if viewModel.artworks.isEmpty {
                ContentUnavailableView {
                    Label("Erreur", systemImage: "wifi.slash")
                } description: {
                    Text(message)
                } actions: {
                    Button("Réessayer") { Task { await viewModel.load() } }
                }
            } else {
                grid
            }
        case .loaded:
            if viewModel.artworks.isEmpty {
                ContentUnavailableView.search
            } else {
                grid
            }
        }
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.artworks) { artwork in
                    NavigationLink(value: artwork) {
                        ArtworkGridCell(
                            title: artwork.title,
                            subtitle: artwork.artistDisplay,
                            imageURL: viewModel.imageURL(for: artwork)
                        )
                    }
                    .buttonStyle(.plain)
                    .matchedTransitionSource(id: artwork.id, in: transitionNamespace)
                    .onAppear {
                        guard artwork.id == viewModel.artworks.last?.id else { return }
                        Task { await viewModel.loadMore() }
                    }
                }
            }
            .padding()

            if viewModel.isLoadingMore {
                ProgressView()
                    .padding(.bottom)
            }
        }
    }

    private var skeletonGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(0..<8, id: \.self) { _ in
                    SkeletonGridCell()
                }
            }
            .padding()
        }
    }
}

#Preview {
    ArtworkListView()
}
