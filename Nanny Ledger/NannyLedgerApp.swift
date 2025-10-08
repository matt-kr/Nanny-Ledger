//
//  NannyLedgerApp.swift
//  Nanny Ledger
//
//  Created by Matt Krussow on 10/8/25.
//

import SwiftUI
import SwiftData

@main
struct NannyLedgerApp: App {
    let container: ModelContainer
    
    init() {
        do {
            let schema = Schema([Shift.self, AppSettings.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(container)
    }
}
