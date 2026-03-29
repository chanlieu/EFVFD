//
//  FIRELogApp.swift
//  FireLog
//
//  Created by Chan Lieu on 3/25/26.
//


import SwiftUI
import SwiftData

@main
struct FIRELogApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([Activity.self])
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to initialize model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
