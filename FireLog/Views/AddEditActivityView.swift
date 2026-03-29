//
//  AddEditActivityView.swift
//  FireLog
//
//  Created by Chan Lieu on 3/25/26.
//


import SwiftUI
import SwiftData
import MapKit

struct AddEditActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var activityToEdit: Activity? = nil
    var initialType: ActivityType? = nil

    @State private var selectedType: ActivityType = .call
    @State private var callSubcategory: CallSubcategory = .medicalDelta
    @State private var callIDPrefix: String = ""
    @State private var callIDNumber: String = ""
    @State private var date: Date = Date()
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
    @State private var durationHours: Int = 0
    @State private var durationMinutes: Int = 30
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var location: String = ""
    @State private var locationLatitude: Double?
    @State private var locationLongitude: Double?
    @State private var showingLocationSearch = false
    @State private var hasLoaded = false
    @State private var selectedRole: Role?
    @State private var selectedReportTypes: Set<ReportType> = []
    @State private var customTypeName: String = ""

    // MARK: - Synced Bindings (Start Time <-> End Time <-> Duration)

    private var startTimeBinding: Binding<Date> {
        Binding(
            get: { startTime },
            set: { newValue in
                startTime = newValue
                let totalMinutes = durationHours * 60 + durationMinutes
                endTime = Calendar.current.date(byAdding: .minute, value: totalMinutes, to: newValue) ?? newValue
            }
        )
    }

    private var endTimeBinding: Binding<Date> {
        Binding(
            get: { endTime },
            set: { newValue in
                endTime = newValue
                let diff = max(0, Int(newValue.timeIntervalSince(startTime) / 60))
                durationHours = diff / 60
                durationMinutes = diff % 60
            }
        )
    }

    private var durationHoursBinding: Binding<Int> {
        Binding(
            get: { durationHours },
            set: { newValue in
                durationHours = newValue
                let totalMinutes = newValue * 60 + durationMinutes
                endTime = Calendar.current.date(byAdding: .minute, value: totalMinutes, to: startTime) ?? startTime
            }
        )
    }

    private var durationMinutesBinding: Binding<Int> {
        Binding(
            get: { durationMinutes },
            set: { newValue in
                durationMinutes = newValue
                let totalMinutes = durationHours * 60 + newValue
                endTime = Calendar.current.date(byAdding: .minute, value: totalMinutes, to: startTime) ?? startTime
            }
        )
    }

    private var yearPrefix: String {
        let year = Calendar.current.component(.year, from: Date())
        return String(format: "%02d", year % 100)
    }
    
    private var defaultCallIDPrefix: String {
        yearPrefix
    }

    /// Duty shifts can span multiple days; all other types cap at 23h.
    private var maxDurationHours: Int {
        selectedType == .dutyShift ? 47 : 23
    }

    private var isEditing: Bool { activityToEdit != nil }
    private var canSave: Bool { durationHours > 0 || durationMinutes > 0 }

    var body: some View {
        Form {
            typeSection
            detailsSection
            roleSection
            reportingSection
            locationSection
            notesSection
        }
        .navigationTitle(isEditing ? "Edit Activity" : "Log Activity")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .frame(minHeight: 44)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Log", action: save)
                    .frame(minHeight: 44)
                    .disabled(!canSave)
            }
        }
        .onAppear {
            guard !hasLoaded else { return }
            hasLoaded = true
            loadExistingActivity()
        }
        .onChange(of: selectedType) { _, newType in
            // Cap hours if switching away from a type that allows longer durations.
            let newMax = newType == .dutyShift ? 47 : 23
            if durationHours > newMax {
                durationHours = newMax
                let totalMinutes = newMax * 60 + durationMinutes
                endTime = Calendar.current.date(byAdding: .minute, value: totalMinutes, to: startTime) ?? startTime
            }
        }
        .sheet(isPresented: $showingLocationSearch) {
            NavigationStack {
                LocationSearchView { name, latitude, longitude in
                    location = name
                    locationLatitude = latitude
                    locationLongitude = longitude
                }
            }
        }
    }

    // MARK: - Sections

    private var typeSection: some View {
        Section("Activity Type") {
            Picker("Type", selection: $selectedType) {
                ForEach(ActivityType.allCases, id: \.self) { type in
                    Label(type.displayName, systemImage: type.systemImage).tag(type)
                }
            }
            .pickerStyle(.navigationLink)
            .frame(minHeight: 44)

            if selectedType == .call {
                Picker("Subcategory", selection: $callSubcategory) {
                    ForEach(CallSubcategory.allCases) { sub in
                        Text(sub.displayName).tag(sub)
                    }
                }
                .pickerStyle(.navigationLink)
                .frame(minHeight: 44)
            }

            if selectedType == .custom {
                TextField("Custom Type Name", text: $customTypeName)
                    .frame(minHeight: 44)
            }
        }
    }

    private var detailsSection: some View {
        Section("Details") {
            if selectedType == .call {
                HStack {
                    Text("Call ID")
                        .foregroundStyle(.secondary)
                    Spacer()
                    TextField("XX", text: $callIDPrefix)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 40)
                        .onChange(of: callIDPrefix) { _, newValue in
                            // Limit to 2 digits
                            if newValue.count > 2 {
                                callIDPrefix = String(newValue.prefix(2))
                            }
                        }
                    Text("-")
                    TextField("XXXX", text: $callIDNumber)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.leading)
                        .frame(width: 70)
                }
                .frame(minHeight: 44)
            }

            TextField("Title (optional)", text: $title)
                .frame(minHeight: 44)

            DatePicker("Date", selection: $date, displayedComponents: .date)
                .frame(minHeight: 44)

            DatePicker("Start Time", selection: startTimeBinding, displayedComponents: .hourAndMinute)
                .frame(minHeight: 44)

            DatePicker("End Time", selection: endTimeBinding, displayedComponents: .hourAndMinute)
                .frame(minHeight: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text("Duration")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    Picker("Hours", selection: durationHoursBinding) {
                        ForEach(0...maxDurationHours, id: \.self) { h in
                            Text("\(h)h").tag(h)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)

                    Picker("Minutes", selection: durationMinutesBinding) {
                        ForEach(0..<60, id: \.self) { m in
                            Text("\(m)m").tag(m)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 120)
            }
        }
    }

    private var roleSection: some View {
        Section("Role") {
            ForEach(Role.allCases) { role in
                Button {
                    selectedRole = selectedRole == role ? nil : role
                } label: {
                    HStack {
                        Text(role.displayName)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: selectedRole == role ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selectedRole == role ? Color.accentColor : .secondary)
                    }
                }
                .frame(minHeight: 44)
            }
        }
    }

    private var reportingSection: some View {
        Section("Reporting") {
            ForEach(ReportType.allCases) { type in
                Button {
                    if selectedReportTypes.contains(type) {
                        selectedReportTypes.remove(type)
                    } else {
                        selectedReportTypes.insert(type)
                    }
                } label: {
                    HStack {
                        Text(type.displayName)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: selectedReportTypes.contains(type) ? "checkmark.square.fill" : "square")
                            .foregroundStyle(selectedReportTypes.contains(type) ? Color.accentColor : .secondary)
                    }
                }
                .frame(minHeight: 44)
            }
        }
    }

    private var locationSection: some View {
        Section("Location") {
            if location.isEmpty {
                Button {
                    showingLocationSearch = true
                } label: {
                    Label("Search Location", systemImage: "magnifyingglass")
                }
                .frame(minHeight: 44)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Label(location, systemImage: "mappin.and.ellipse")

                    if let lat = locationLatitude, let lng = locationLongitude {
                        Map(initialPosition: .region(MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        ))) {
                            Marker(location, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng))
                        }
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .allowsHitTesting(false)
                    }
                }
                .frame(minHeight: 44)

                Button(role: .destructive) {
                    location = ""
                    locationLatitude = nil
                    locationLongitude = nil
                } label: {
                    Label("Remove Location", systemImage: "xmark.circle")
                }
                .frame(minHeight: 44)
            }
        }
    }

    private var notesSection: some View {
        Section("Notes") {
            TextEditor(text: $notes)
                .frame(minHeight: 88)
        }
    }

    // MARK: - Actions

    private func loadExistingActivity() {
        guard let a = activityToEdit else {
            // Set default prefix for new activities
            callIDPrefix = defaultCallIDPrefix
            if let initial = initialType {
                selectedType = initial
            }
            return
        }
        selectedType = a.type
        date = a.date
        startTime = a.date
        durationHours = a.durationMinutes / 60
        durationMinutes = a.durationMinutes % 60
        endTime = Calendar.current.date(byAdding: .minute, value: a.durationMinutes, to: a.date) ?? a.date
        title = a.title
        notes = a.notes
        location = a.location
        locationLatitude = a.locationLatitude
        locationLongitude = a.locationLongitude
        selectedRole = a.role
        selectedReportTypes = a.reportTypes
        if let cid = a.callID, let dashIndex = cid.firstIndex(of: "-") {
            callIDPrefix = String(cid[..<dashIndex])
            callIDNumber = String(cid[cid.index(after: dashIndex)...])
        } else {
            callIDPrefix = defaultCallIDPrefix
        }
        customTypeName = a.customTypeName
        if a.type == .call, let sub = CallSubcategory(rawValue: a.customTypeName) {
            callSubcategory = sub
        }
    }

    private func save() {
        let totalMinutes = durationHours * 60 + durationMinutes

        // Combine date (day) with startTime (hour/minute)
        let calendar = Calendar.current
        let dayComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        var combined = DateComponents()
        combined.year = dayComponents.year
        combined.month = dayComponents.month
        combined.day = dayComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        let activityDate = calendar.date(from: combined) ?? date

        let resolvedCustomName: String
        if selectedType == .call {
            resolvedCustomName = callSubcategory.rawValue
        } else {
            resolvedCustomName = customTypeName
        }

        if let a = activityToEdit {
            a.type = selectedType
            a.date = activityDate
            a.durationMinutes = totalMinutes
            a.title = title
            a.notes = notes
            a.location = location
            a.locationLatitude = locationLatitude
            a.locationLongitude = locationLongitude
            a.role = selectedRole
            a.reportTypes = selectedReportTypes
            a.callID = selectedType == .call && !callIDPrefix.isEmpty && !callIDNumber.isEmpty ? "\(callIDPrefix)-\(callIDNumber)" : nil
            a.customTypeName = resolvedCustomName
            a.updatedAt = Date()
        } else {
            let activity = Activity(
                type: selectedType,
                date: activityDate,
                durationMinutes: totalMinutes,
                title: title,
                notes: notes,
                location: location,
                locationLatitude: locationLatitude,
                locationLongitude: locationLongitude,
                customTypeName: resolvedCustomName
            )
            activity.role = selectedRole
            activity.reportTypes = selectedReportTypes
            activity.callID = !callIDPrefix.isEmpty && !callIDNumber.isEmpty ? "\(callIDPrefix)-\(callIDNumber)" : nil
            modelContext.insert(activity)
        }
        dismiss()
    }
}
