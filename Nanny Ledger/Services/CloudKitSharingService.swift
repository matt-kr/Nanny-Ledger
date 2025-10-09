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
        // Use the specific container identifier instead of default
        let containerIdentifier = "iCloud.com.mattkrussow.Nanny-Ledger"
        let ckContainer = CKContainer(identifier: containerIdentifier)
        let privateDatabase = ckContainer.privateCloudDatabase
        
        print("🔵 Using CloudKit container: \(containerIdentifier)")
        
        // Create a root record zone if it doesn't exist
        let zoneID = CKRecordZone.ID(zoneName: "NannyLedgerZone", ownerName: CKCurrentUserDefaultName)
        let zone = CKRecordZone(zoneID: zoneID)
        
        print("🔵 Creating/verifying zone: \(zoneID.zoneName)")
        
        do {
            try await privateDatabase.save(zone)
            print("✅ Zone created/verified successfully")
        } catch let error as CKError where error.code == .serverRecordChanged {
            // Zone already exists, that's fine
            print("✅ Zone already exists")
        } catch {
            print("❌ Zone creation failed: \(error)")
            throw error
        }
        
        // Create a root record for the share
        let rootRecordID = CKRecord.ID(recordName: "NannyLedgerRoot", zoneID: zoneID)
        let rootRecord = CKRecord(recordType: "NannyLedgerData", recordID: rootRecordID)
        rootRecord["title"] = "Nanny Ledger" as CKRecordValue
        rootRecord["createdAt"] = Date() as CKRecordValue
        
        print("🔵 Creating share with root record...")
        
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
        
        print("🔵 Saving share to CloudKit...")
        
        return try await withCheckedThrowingContinuation { continuation in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success():
                    print("✅ Share saved successfully!")
                    print("📤 Share URL: \(share.url?.absoluteString ?? "none")")
                    continuation.resume(returning: share)
                case .failure(let error):
                    print("❌ Failed to save share: \(error)")
                    continuation.resume(throwing: error)
                }
            }
            
            privateDatabase.add(operation)
        }
    }
}
