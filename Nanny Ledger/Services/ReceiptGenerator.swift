//
//  ReceiptGenerator.swift
//  Nanny Ledger
//
//  Created by Matt Krussow on 10/13/25.
//

import Foundation
import UIKit

struct ReceiptGenerator {
    
    static func generateReceiptHTML(
        shifts: [Shift],
        caregiver: Caregiver,
        receiptData: ReceiptData
    ) -> String {
        guard !shifts.isEmpty else { return "" }
        
        // Filter shifts by date range
        let filteredShifts = shifts.filter { shift in
            let shiftDate = Calendar.current.startOfDay(for: shift.date)
            let startDate = Calendar.current.startOfDay(for: receiptData.startDate)
            let endDate = Calendar.current.startOfDay(for: receiptData.endDate)
            return shiftDate >= startDate && shiftDate <= endDate
        }
        
        guard !filteredShifts.isEmpty else { return "" }
        
        let sortedShifts = filteredShifts.sorted { $0.date < $1.date }
        let totalHours = sortedShifts.reduce(0.0) { $0 + $1.roundedHours }
        let totalAmount = totalHours * caregiver.hourlyRate
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        var shiftRows = ""
        for shift in sortedShifts {
            let dateStr = dateFormatter.string(from: shift.date)
            let hours = shift.roundedHours
            let amount = hours * caregiver.hourlyRate
            let amountStr = Self.formatCurrency(amount)
            
            shiftRows += """
            <tr>
                <td>\(dateStr)</td>
                <td>\(shift.startTime) - \(shift.endTime)</td>
                <td class="right">\(String(format: "%.2f", hours))</td>
                <td class="right">\(amountStr)</td>
            </tr>
            """
        }
        
        // Provider info HTML
        // Provider info HTML - 2 column layout (3 items each)
        var providerLeft = ""
        providerLeft += "<p><strong>Name:</strong> \(receiptData.providerName)</p>"
        providerLeft += "<p><strong>Service:</strong> \(receiptData.serviceProvided)</p>"
        
        if receiptData.includeProviderTaxId {
            let taxId = receiptData.providerTaxId ?? ""
            providerLeft += "<p><strong>SSN/EIN:</strong> \(taxId.isEmpty ? "_________________" : taxId)</p>"
        }
        
        var providerRight = ""
        providerRight += "<p><strong>Phone:</strong> \(receiptData.providerPhone.isEmpty ? "_________________" : receiptData.providerPhone)</p>"
        
        if receiptData.includeProviderEmail {
            let email = receiptData.providerEmail ?? ""
            providerRight += "<p><strong>Email:</strong> \(email.isEmpty ? "_________________" : email)</p>"
        }
        
        if receiptData.includeProviderAddress {
            let address = receiptData.providerAddress ?? ""
            providerRight += "<p><strong>Address:</strong> \(address.isEmpty ? "_________________" : address)</p>"
        }
        
        // Client info HTML - 2 column layout
        var clientLeft = ""
        clientLeft += "<p><strong>Name:</strong> \(receiptData.clientName)</p>"
        
        if let address = receiptData.clientAddress, !address.isEmpty {
            clientLeft += "<p><strong>Address:</strong> \(address)</p>"
        }
        
        var clientRight = ""
        if let phone = receiptData.clientPhone, !phone.isEmpty {
            clientRight += "<p><strong>Phone:</strong> \(phone)</p>"
        }
        
        if let email = receiptData.clientEmail, !email.isEmpty {
            clientRight += "<p><strong>Email:</strong> \(email)</p>"
        }
        
        // Notes section
        var notesHTML = ""
        if let notes = receiptData.notes, !notes.isEmpty {
            notesHTML += "<div class=\"notes\">"
            notesHTML += "<h3>Notes</h3>"
            notesHTML += "<p style='white-space: pre-line;'>\(notes)</p>"
            notesHTML += "</div>"
        }
        
        // Signature section
        var signatureHTML = ""
        if receiptData.includeSignatureLine || receiptData.includeClientSignature {
            signatureHTML += "<div class=\"signature\">"
            
            if receiptData.includeSignatureLine {
                signatureHTML += "<div class=\"signature-line\">"
                signatureHTML += "<div class=\"line\"></div>"
                signatureHTML += "<p>Provider Signature</p>"
                signatureHTML += "</div>"
                signatureHTML += "<div class=\"signature-line\">"
                signatureHTML += "<div class=\"line\"></div>"
                signatureHTML += "<p>Date</p>"
                signatureHTML += "</div>"
            }
            
            if receiptData.includeClientSignature {
                signatureHTML += "<div class=\"signature-line\">"
                signatureHTML += "<div class=\"line\"></div>"
                signatureHTML += "<p>Client Signature</p>"
                signatureHTML += "</div>"
                signatureHTML += "<div class=\"signature-line\">"
                signatureHTML += "<div class=\"line\"></div>"
                signatureHTML += "<p>Date</p>"
                signatureHTML += "</div>"
            }
            
            signatureHTML += "</div>"
        }
        
        // Format currency values
        let rateStr = Self.formatCurrency(caregiver.hourlyRate)
        let totalAmountStr = Self.formatCurrency(totalAmount)
        
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Childcare Receipt</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
                    max-width: 800px;
                    margin: 20px auto;
                    padding: 15px;
                    color: #333;
                }
                .header {
                    text-align: center;
                    margin-bottom: 20px;
                    border-bottom: 3px solid #5E5CE6;
                    padding-bottom: 15px;
                }
                .header h1 {
                    margin: 0;
                    color: #5E5CE6;
                    font-size: 28px;
                }
                .header p {
                    margin: 5px 0;
                    color: #666;
                    font-size: 14px;
                }
                .info-section {
                    display: flex;
                    flex-direction: column;
                    gap: 12px;
                    margin-bottom: 20px;
                }
                .info-box {
                    padding: 12px;
                    background: #f5f5f7;
                    border-radius: 8px;
                }
                .info-box h3 {
                    margin: 0 0 8px 0;
                    font-size: 12px;
                    color: #666;
                    text-transform: uppercase;
                    letter-spacing: 0.5px;
                }
                .info-box p {
                    margin: 4px 0;
                    font-size: 14px;
                }
                .provider-columns {
                    display: grid;
                    grid-template-columns: 1fr 1fr;
                    gap: 15px;
                }
                .client-columns {
                    display: grid;
                    grid-template-columns: 1fr 1fr;
                    gap: 15px;
                }
                .client-columns p {
                    word-wrap: break-word;
                    overflow-wrap: break-word;
                }
                .period-inline {
                    display: flex;
                    align-items: center;
                    gap: 8px;
                }
                .period-inline p {
                    margin: 0;
                }
                table {
                    width: 100%;
                    border-collapse: collapse;
                    margin: 15px 0;
                }
                th {
                    background: #5E5CE6;
                    color: white;
                    padding: 10px;
                    text-align: left;
                    font-weight: 600;
                    font-size: 14px;
                }
                th.right, td.right {
                    text-align: right;
                }
                td {
                    padding: 10px;
                    border-bottom: 1px solid #e5e5e7;
                    font-size: 14px;
                }
                tr:last-child td {
                    border-bottom: none;
                }
                .totals {
                    margin-top: 15px;
                    padding: 15px;
                    background: #f5f5f7;
                    border-radius: 8px;
                }
                .total-row {
                    display: flex;
                    justify-content: space-between;
                    margin: 8px 0;
                    font-size: 15px;
                }
                .total-row.grand {
                    font-size: 18px;
                    font-weight: bold;
                    color: #5E5CE6;
                    border-top: 2px solid #5E5CE6;
                    padding-top: 12px;
                    margin-top: 12px;
                }
                .notes {
                    margin: 20px 0;
                    padding: 15px;
                    background: #fffbea;
                    border-left: 4px solid #f59e0b;
                    border-radius: 4px;
                }
                .notes h3 {
                    margin: 0 0 8px 0;
                    font-size: 14px;
                    color: #92400e;
                }
                .notes p {
                    margin: 0;
                    color: #78350f;
                    line-height: 1.4;
                    font-size: 13px;
                }
                .signature {
                    margin-top: 25px;
                    display: grid;
                    grid-template-columns: 1fr 1fr;
                    gap: 15px 30px;
                }
                .signature-line {
                    min-width: 0;
                }
                .signature-line .line {
                    border-bottom: 2px solid #333;
                    margin-bottom: 6px;
                    height: 30px;
                }
                .signature-line p {
                    margin: 0;
                    font-size: 12px;
                    color: #666;
                }
                .footer {
                    margin-top: 25px;
                    padding-top: 15px;
                    border-top: 1px solid #e5e5e7;
                    text-align: center;
                    color: #666;
                    font-size: 12px;
                }
                @media print {
                    body {
                        margin: 0;
                        padding: 20px;
                    }
                }
            </style>
        </head>
        <body>
            <div class="header">
                <h1>\(receiptData.receiptTitle)</h1>
                <p>Receipt #\(receiptData.receiptNumber)</p>
            </div>
            
            <div class="info-section">
                <div class="info-box">
                    <h3>Service Provider</h3>
                    <div class="provider-columns">
                        <div>\(providerLeft)</div>
                        <div>\(providerRight)</div>
                    </div>
                </div>
                
                <div class="info-box">
                    <h3>Client</h3>
                    <div class="client-columns">
                        <div>\(clientLeft)</div>
                        <div>\(clientRight)</div>
                    </div>
                </div>
                
                <div class="info-box">
                    <h3>Period</h3>
                    <div class="period-inline">
                        <p><strong>From:</strong> \(dateFormatter.string(from: receiptData.startDate))</p>
                        <p><strong>To:</strong> \(dateFormatter.string(from: receiptData.endDate))</p>
                    </div>
                </div>
            </div>
            
            <table>
                <thead>
                    <tr>
                        <th>Date</th>
                        <th>Hours</th>
                        <th class="right">Duration</th>
                        <th class="right">Amount</th>
                    </tr>
                </thead>
                <tbody>
                    \(shiftRows)
                </tbody>
            </table>
            
            <div class="totals">
                <div class="total-row">
                    <span>Hourly Rate:</span>
                    <span>\(rateStr)/hour</span>
                </div>
                <div class="total-row">
                    <span>Total Hours:</span>
                    <span>\(String(format: "%.2f", totalHours)) hours</span>
                </div>
                <div class="total-row">
                    <span>Number of Shifts:</span>
                    <span>\(sortedShifts.count) \(sortedShifts.count == 1 ? "shift" : "shifts")</span>
                </div>
                <div class="total-row grand">
                    <span>Total Amount:</span>
                    <span>\(totalAmountStr)</span>
                </div>
            </div>
            
            \(notesHTML)
            
            \(signatureHTML)
        </body>
        </html>
        """
        
        return html
    }
    
    static func generateReceiptPDF(
        shifts: [Shift],
        caregiver: Caregiver,
        receiptData: ReceiptData
    ) -> Data? {
        let html = generateReceiptHTML(shifts: shifts, caregiver: caregiver, receiptData: receiptData)
        
        let printFormatter = UIMarkupTextPrintFormatter(markupText: html)
        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)
        
        let pageSize = CGSize(width: 612, height: 792) // US Letter size in points
        let printableRect = CGRect(x: 36, y: 36, width: pageSize.width - 72, height: pageSize.height - 72)
        let paperRect = CGRect(origin: .zero, size: pageSize)
        
        renderer.setValue(NSValue(cgRect: paperRect), forKey: "paperRect")
        renderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")
        
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, paperRect, nil)
        
        for i in 0..<renderer.numberOfPages {
            UIGraphicsBeginPDFPage()
            let bounds = UIGraphicsGetPDFContextBounds()
            renderer.drawPage(at: i, in: bounds)
        }
        
        UIGraphicsEndPDFContext()
        
        return pdfData as Data
    }
    
    private static func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .current
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}
