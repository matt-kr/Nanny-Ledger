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
        
        // Create the share
        let share = CKShare(rootRecord: rootRecord)
        share[CKShare.SystemFieldKey.title] = "Nanny Ledger" as CKRecordValue
        share.publicPermission = .none
        
        // Don't set minimum version requirements to avoid compatibility issues
        // share[CKShare.SystemFieldKey.thumbnailImageData] = nil
        
        // Save both the root record and share in a single operation
        let operation = CKModifyRecordsOperation(recordsToSave: [rootRecord, share], recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys
        operation.qualityOfService = .userInitiated
        
        return try await withCheckedThrowingContinuation { continuation in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success():
                    continuation.resume(returning: share)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            privateDatabase.add(operation)
        }
    }
}
