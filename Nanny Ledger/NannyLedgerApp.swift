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
            let schema = Schema([Shift.self, AppSettings.self, Caregiver.self])
            
            // Configure with migration support
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                cloudKitDatabase: .automatic
            )
            
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            print("✅ ModelContainer initialized successfully")
            
        } catch {
            print("❌ Failed to initialize ModelContainer: \(error)")
            print("💡 If this is a schema migration error, delete the app and reinstall")
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
