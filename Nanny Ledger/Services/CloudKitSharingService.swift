//
//  CloudKitSharingService.swift
//  Nanny Ledger
//
//  Created by Matt Krussow on 10/8/25.
//

import Foundation
import SwiftData
import CloudKit

/// Service for managing CloudKit sharing
struct CloudKitSharingService {
    
    static func createShare(for container: ModelContainer) async throws -> CKShare {
        let ckContainer = CKContainer.default()
        let privateDatabase = ckContainer.privateCloudDatabase
        
        // Create a root record zone if it doesn't exist
        let zoneID = CKRecordZone.ID(zoneName: "NannyLedgerZone", ownerName: CKCurrentUserDefaultName)
        let zone = CKRecordZone(zoneID: zoneID)
        
        do {
            try await privateDatabase.save(zone)
        } catch let error as CKError where error.code == .serverRecordChanged {
            // Zone already exists, that's fine
        }
        
        // Create a root record for the share
        let rootRecordID = CKRecord.ID(recordName: "NannyLedgerRoot", zoneID: zoneID)
        let rootRecord = CKRecord(recordType: "NannyLedgerData", recordID: rootRecordID)
        rootRecord["title"] = "Nanny Ledger" as CKRecordValue
        rootRecord["createdAt"] = Date() as CKRecordValue
        
        // Save the root record first
        let savedRecord = try await privateDatabase.save(rootRecord)
        
        // Create the share
        let share = CKShare(rootRecord: savedRecord)
        share[CKShare.SystemFieldKey.title] = "Nanny Ledger" as CKRecordValue
        share.publicPermission = .none
        
        // Save the share
        let savedShare = try await privateDatabase.save(share)
        
        return savedShare
    }
}
