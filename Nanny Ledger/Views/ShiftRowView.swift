//
//  ShiftRowView.swift
//  Nanny Ledger
//
//  Created by Matt Krussow on 10/8/25.
//

import SwiftUI

struct ShiftRowView: View {
    let shift: Shift
    var rate: Double? = nil
    var onDelete: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil
    var onTogglePaid: (() -> Void)? = nil

    private var weekdayAbbrev: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: shift.date).uppercased()
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: shift.date)
    }

    private var monthDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: shift.date)
    }

    var body: some View {
        HStack(spacing: 14) {
            // Date badge
            VStack(spacing: 2) {
                Text(weekdayAbbrev)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(dayNumber)
                    .font(.title3.weight(.bold))
            }
            .frame(width: 46, height: 46)
            .background(Theme.gradient.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(monthDay)
                    .font(.subheadline.weight(.semibold))
                Text(shift.timeRangeDisplay)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                HStack(spacing: 4) {
                    if shift.isPaid {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    Text("\(shift.roundedHours.hoursString)h")
                        .font(.subheadline.weight(.semibold))
                }

                if let rate {
                    Text(shift.earnings(at: rate).currencyString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onTapGesture {
            onTap?()
        }
        .contextMenu {
            if let onTap {
                Button {
                    onTap()
                } label: {
                    Label("Edit Shift", systemImage: "pencil")
                }
            }

            if let onTogglePaid {
                Button {
                    onTogglePaid()
                } label: {
                    Label(
                        shift.isPaid ? "Mark as Unpaid" : "Mark as Paid",
                        systemImage: shift.isPaid ? "xmark.seal" : "checkmark.seal"
                    )
                }
            }

            if let onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}
