//
//  ExportManager.swift
//  FireLog
//
//  Created by Chan Lieu on 3/25/26.
//


import Foundation
import UIKit

enum ExportManager {

    // MARK: - CSV

    static func generateCSV(activities: [Activity]) throws -> URL {
        let dateFmt = DateFormatter()
        dateFmt.dateStyle = .short
        dateFmt.timeStyle = .none

        let timeFmt = DateFormatter()
        timeFmt.dateStyle = .none
        timeFmt.timeStyle = .short

        var lines = [#"Date,Time,Type,Title,"Duration (min)",Location,Notes"#]

        for a in activities.sorted(by: { $0.date < $1.date }) {
            let row: [String] = [
                dateFmt.string(from: a.date),
                timeFmt.string(from: a.date),
                a.displayTypeName,
                a.title,
                "\(a.durationMinutes)",
                a.location,
                a.notes.replacingOccurrences(of: "\n", with: " ")
            ]
            lines.append(row.map { csvEscape($0) }.joined(separator: ","))
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("FIRELog_\(timestamp()).csv")
        try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: - PDF

    static func generatePDF(activities: [Activity]) throws -> URL {
        let sorted = activities.sorted { $0.date < $1.date }
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let margin: CGFloat = 50
        let contentW = pageRect.width - margin * 2
        // Column x-positions: Date | Type | Title | Duration | Location
        let cols: [CGFloat] = [
            margin + 4,
            margin + 100,
            margin + 210,
            margin + 330,
            margin + 410
        ]

        // Mutable state box — avoids inout-in-closure restrictions
        final class PageState {
            var y: CGFloat = 0
        }
        let state = PageState()

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let pdfData = renderer.pdfData { pdfCtx in

            // ---- helpers defined as local closures capturing `state` ----

            let beginPage: () -> Void = {
                pdfCtx.beginPage()
                state.y = margin

                // Title
                "FIRELog \u{2014} Activity Report".draw(
                    at: CGPoint(x: margin, y: state.y),
                    withAttributes: [
                        .font: UIFont.boldSystemFont(ofSize: 20),
                        .foregroundColor: UIColor.label
                    ]
                )
                state.y += 28

                // Generated date
                let sub = "Generated: \(Date().formatted(date: .long, time: .shortened))"
                sub.draw(
                    at: CGPoint(x: margin, y: state.y),
                    withAttributes: [
                        .font: UIFont.systemFont(ofSize: 11),
                        .foregroundColor: UIColor.secondaryLabel
                    ]
                )
                state.y += 24

                // Divider
                if let ctx = UIGraphicsGetCurrentContext() {
                    ctx.setStrokeColor(UIColor.separator.cgColor)
                    ctx.setLineWidth(0.5)
                    ctx.move(to: CGPoint(x: margin, y: state.y))
                    ctx.addLine(to: CGPoint(x: pageRect.width - margin, y: state.y))
                    ctx.strokePath()
                }
                state.y += 16
            }

            let ensureSpace: (CGFloat) -> Void = { required in
                if state.y + required > pageRect.height - margin {
                    beginPage()
                }
            }

            let drawText: (String, CGPoint, UIFont, UIColor) -> Void = { text, pt, font, color in
                text.draw(at: pt, withAttributes: [
                    .font: font,
                    .foregroundColor: color
                ])
            }

            // ---- First page ----
            beginPage()

            // Summary block
            let totalH = Double(sorted.reduce(0) { $0 + $1.durationMinutes }) / 60
            drawText("Summary",
                     CGPoint(x: margin, y: state.y),
                     .boldSystemFont(ofSize: 13), .label)
            state.y += 20
            drawText("Total Activities: \(sorted.count)",
                     CGPoint(x: margin, y: state.y),
                     .systemFont(ofSize: 12), .label)
            state.y += 18
            drawText(String(format: "Total Hours: %.1fh", totalH),
                     CGPoint(x: margin, y: state.y),
                     .systemFont(ofSize: 12), .label)
            state.y += 28

            // Table header row
            ensureSpace(28)
            UIColor.systemBlue.withAlphaComponent(0.12).setFill()
            UIRectFill(CGRect(x: margin, y: state.y, width: contentW, height: 24))
            let headerFont = UIFont.boldSystemFont(ofSize: 10)
            let headers = ["Date", "Type", "Title", "Dur.", "Location"]
            for (title, x) in zip(headers, cols) {
                drawText(title, CGPoint(x: x, y: state.y + 7), headerFont, .label)
            }
            state.y += 26

            // Data rows
            let rowFont = UIFont.systemFont(ofSize: 10)
            for (i, a) in sorted.enumerated() {
                ensureSpace(22)
                if i % 2 == 0 {
                    UIColor.systemGray6.setFill()
                    UIRectFill(CGRect(x: margin, y: state.y, width: contentW, height: 22))
                }
                let values = [
                    a.date.formatted(.dateTime.month(.abbreviated).day().year()),
                    String(a.displayTypeName.prefix(16)),
                    String(a.title.prefix(18)),
                    a.durationFormatted,
                    String(a.location.prefix(16))
                ]
                for (val, x) in zip(values, cols) {
                    drawText(val, CGPoint(x: x, y: state.y + 5), rowFont, .label)
                }
                state.y += 22
            }
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("FIRELog_\(timestamp()).pdf")
        try pdfData.write(to: url)
        return url
    }

    // MARK: - Helpers

    private static func csvEscape(_ s: String) -> String {
        "\"\(s.replacingOccurrences(of: "\"", with: "\"\""))\"" 
    }

    private static func timestamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd_HHmmss"
        return f.string(from: Date())
    }
}