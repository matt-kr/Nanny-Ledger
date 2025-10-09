//
//  CloudKitSharingService.swift
//  Nanny Ledger
//
//  Created by Matt Krussow on 10/8/25.
//

import Foundation
import SwiftData
import CloudKit

/// Service for managing CloudKit sharing with SwiftData
@MainActor
struct CloudKitSharingService {
    
    /// Gets the CloudKit container for sharing
    static func getContainer() -> CKContainer {
        let containerIdentifier = "iCloud.com.mattkrussow.Nanny-Ledger"
        return CKContainer(identifier: containerIdentifier)
    }
}
