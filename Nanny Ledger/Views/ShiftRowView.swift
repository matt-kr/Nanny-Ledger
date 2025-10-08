//
//  ShiftRowView.swift
//  Nanny Ledger
//
//  Created by Matt Krussow on 10/8/25.
//

import SwiftUI

struct ShiftRowView: View {
    let shift: Shift
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(shift.date.formattedWithWeekday())
                    .font(.headline)
                
                Text("\(shift.startTime) – \(shift.endTime)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(String(format: "%.2f", shift.roundedHours))h")
                    .font(.headline)
                
                Text("~\(String(format: "%.1f", shift.durationHours)) hrs")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
