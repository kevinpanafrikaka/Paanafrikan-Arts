//
//  PaanafrikanArtsApp.swift
//  PaanafrikanArts
//
//  Created by orange on 14/09/2026.
//

import SwiftUI
import SwiftData

@main
struct PaanafrikanArtsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([FavoriteArtwork.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
