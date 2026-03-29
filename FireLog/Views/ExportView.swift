//
//  ExportView.swift
//  FireLog
//
//  Created by Chan Lieu on 3/25/26.
//


import SwiftUI
import SwiftData

struct ExportView: View {
    @Query(sort: \Activity.date, order: .reverse) private var allActivities: [Activity]

    @State private var startDate: Date = Calendar.current.date(
        byAdding: .year, value: -1, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    @State private var selectedTypes: Set<ActivityType> = Set(ActivityType.allCases)
    @State private var shareURL: URL?
    @State private var isGenerating = false
    @State private var errorMessage: String?

    private var filtered: [Activity] {
        allActivities.filter {
            $0.date >= startDate && $0.date <= endDate && selectedTypes.contains($0.type)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                dateRangeSection
                typesSection
                summarySection
                exportSection
            }
            .navigationTitle("Export")
            .sheet(item: Binding(
                get: { shareURL.map { ShareableURL(url: $0) } },
                set: { if $0 == nil { shareURL = nil } }
            )) { item in
                ShareSheet(url: item.url)
            }
        }
    }

    // MARK: - Sections

    private var dateRangeSection: some View {
        Section("Date Range") {
            DatePicker("From", selection: $startDate, displayedComponents: .date)
                .frame(minHeight: 44)
            DatePicker("To", selection: $endDate, in: startDate..., displayedComponents: .date)
                .frame(minHeight: 44)
        }
    }

    private var typesSection: some View {
        Section("Activity Types") {
            ForEach(ActivityType.allCases, id: \.self) { (type: ActivityType) in
                Button {
                    if selectedTypes.contains(type) {
                        selectedTypes.remove(type)
                    } else {
                        selectedTypes.insert(type)
                    }
                } label: {
                    HStack {
                        Image(systemName: type.systemImage)
                            .foregroundStyle(type.color)
                            .frame(width: 28)
                        Text(type.displayName)
                            .foregroundStyle(.primary)
                        Spacer()
                        if selectedTypes.contains(type) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .frame(minHeight: 44)
                }
            }
        }
    }

    private var summarySection: some View {
        Section {
            HStack {
                Text("\(filtered.count) activities selected")
                Spacer()
                Text(String(
                    format: "%.1fh total",
                    Double(filtered.reduce(0) { $0 + $1.durationMinutes }) / 60
                ))
            }
            .foregroundStyle(.secondary)
            .frame(minHeight: 44)

            if let error = errorMessage {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .font(.callout)
            }
        }
    }

    private var exportSection: some View {
        Section {
            exportButton(label: "Export CSV", icon: "tablecells") { exportCSV() }
            exportButton(label: "Export PDF", icon: "doc.richtext") { exportPDF() }
        }
    }

    @ViewBuilder
    private func exportButton(
        label: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Spacer()
                if isGenerating {
                    ProgressView()
                } else {
                    Label(label, systemImage: icon)
                }
                Spacer()
            }
            .frame(minHeight: 44)
        }
        .disabled(filtered.isEmpty || isGenerating)
    }

    // MARK: - Actions

    private func exportCSV() {
        generate { try ExportManager.generateCSV(activities: self.filtered) }
    }

    private func exportPDF() {
        generate { try ExportManager.generatePDF(activities: self.filtered) }
    }

    private func generate(_ work: @escaping () throws -> URL) {
        isGenerating = true
        errorMessage = nil
        Task {
            do {
                let url = try work()
                await MainActor.run {
                    shareURL = url
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isGenerating = false
                }
            }
        }
    }
}

// MARK: - Share Helpers

struct ShareableURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}