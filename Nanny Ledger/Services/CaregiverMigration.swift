//
//  CaregiverMigration.swift
//  Nanny Ledger
//
//  Created by Matt Krussow on 10/13/25.
//

import Foundation
import SwiftData

struct CaregiverMigration {
    
    /// Ensures a default caregiver exists and migrates any orphaned shifts
    static func ensureDefaultCaregiver(modelContext: ModelContext, settings: AppSettings) -> Caregiver {
        // Check if we already have caregivers
        let descriptor = FetchDescriptor<Caregiver>(
            sortBy: [SortDescriptor(\.createdDate)]
        )
        
        if let existingCaregivers = try? modelContext.fetch(descriptor),
           let firstCaregiver = existingCaregivers.first {
            // Migrate any shifts without a caregiver
            migrateOrphanedShifts(to: firstCaregiver, modelContext: modelContext)
            return firstCaregiver
        }
        
        // Create default caregiver from existing settings
        let defaultCaregiver = Caregiver(
            name: settings.recipientName.isEmpty ? "Nanny" : settings.recipientName,
            role: "Night Nanny",
            hourlyRate: settings.hourlyRate,
            defaultStartTime: settings.sundayStart, // Use Sunday as default
            defaultEndTime: settings.sundayEnd,
            zelleInfo: settings.recipientPhone,
            isActive: true
        )
        
        modelContext.insert(defaultCaregiver)
        
        // Migrate all existing shifts to this caregiver
        migrateOrphanedShifts(to: defaultCaregiver, modelContext: modelContext)
        
        // Save the default caregiver ID to settings
        settings.lastSelectedCaregiverId = defaultCaregiver.id
        
        try? modelContext.save()
        
        return defaultCaregiver
    }
    
    /// Assigns all shifts without a caregiver to the specified caregiver
    private static func migrateOrphanedShifts(to caregiver: Caregiver, modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Shift>(
            predicate: #Predicate<Shift> { shift in
                shift.caregiver == nil
            }
        )
        
        if let orphanedShifts = try? modelContext.fetch(descriptor) {
            for shift in orphanedShifts {
                shift.caregiver = caregiver
            }
            try? modelContext.save()
        }
    }
}
