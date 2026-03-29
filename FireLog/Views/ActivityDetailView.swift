//
//  ActivityDetailView.swift
//  FireLog
//
//  Created by Chan Lieu on 3/25/26.
//


import SwiftUI
import SwiftData
import MapKit

struct ActivityDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let activity: Activity

    @State private var showingEdit = false
    @State private var showingDeleteAlert = false

    var body: some View {
        List {
            headerSection
            whenSection

            if activity.role != nil {
                roleSection
            }

            if !activity.reportTypes.isEmpty {
                reportingSection
            }

            if !activity.location.isEmpty {
                locationSection
            }

            if !activity.notes.isEmpty {
                notesSection
            }

            metadataSection
            deleteSection
        }
        .navigationTitle(activity.title.isEmpty ? activity.displayTypeName : activity.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEdit = true }
                    .frame(minHeight: 44)
            }
        }
        .sheet(isPresented: $showingEdit) {
            NavigationStack {
                AddEditActivityView(activityToEdit: activity)
            }
        }
        .confirmationDialog(
            "Delete Activity",
            isPresented: $showingDeleteAlert,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                modelContext.delete(activity)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        Section {
            HStack {
                Spacer()
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(activity.type.color.opacity(0.15))
                            .frame(width: 88, height: 88)
                        Image(systemName: activity.displayIcon)
                            .foregroundStyle(activity.type.color)
                            .font(.system(size: 40))
                    }
                    Text(activity.displayTypeName)
                        .font(.title3.bold())
                }
                Spacer()
            }
            .padding(.vertical, 12)
            .listRowBackground(Color.clear)
        }
    }

    private var whenSection: some View {
        Section("When") {
            LabeledContent("Date") {
                Text(activity.date.formatted(date: .complete, time: .omitted))
                    .foregroundStyle(.secondary)
            }
            .frame(minHeight: 44)

            LabeledContent("Time") {
                Text(activity.date.formatted(date: .omitted, time: .shortened))
                    .foregroundStyle(.secondary)
            }
            .frame(minHeight: 44)

            LabeledContent("Duration") {
                Text(activity.durationFormatted)
                    .foregroundStyle(.secondary)
            }
            .frame(minHeight: 44)
        }
    }

    private var roleSection: some View {
        Section("Role") {
            if let role = activity.role {
                Label(role.displayName, systemImage: "person.fill")
                    .frame(minHeight: 44)
            }
        }
    }

    private var reportingSection: some View {
        Section("Reporting") {
            ForEach(activity.reportTypes.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { type in
                Label(type.displayName, systemImage: "doc.text.fill")
                    .frame(minHeight: 44)
            }
        }
    }

    private var locationSection: some View {
        Section("Location") {
            Label(activity.location, systemImage: "mappin.and.ellipse")
                .frame(minHeight: 44)

            if let coordinate = activity.coordinate {
                Map(initialPosition: .region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                ))) {
                    Marker(activity.location, coordinate: coordinate)
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
    }

    private var notesSection: some View {
        Section("Notes") {
            Text(activity.notes)
                .frame(minHeight: 44, alignment: .topLeading)
        }
    }

    private var metadataSection: some View {
        Section("Logged") {
            LabeledContent("Created") {
                Text(activity.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .foregroundStyle(.secondary)
            }
            .frame(minHeight: 44)

            if activity.updatedAt.timeIntervalSince(activity.createdAt) > 2 {
                LabeledContent("Updated") {
                    Text(activity.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        .foregroundStyle(.secondary)
                }
                .frame(minHeight: 44)
            }
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                HStack {
                    Spacer()
                    Label("Delete Activity", systemImage: "trash")
                    Spacer()
                }
            }
            .frame(minHeight: 44)
        }
    }
}
