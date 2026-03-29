//
//  StatisticsView.swift
//  FireLog
//
//  Created by Chan Lieu on 3/25/26.
//


import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Query(sort: \Activity.date, order: .reverse) private var allActivities: [Activity]
    @State private var period: StatPeriod = .thisWeek
    @State private var selectedTypes: Set<ActivityType> = Set(ActivityType.allCases)
    @State private var isTypeFilterExpanded = false
    @State private var selectedChartType: ActivityType?
    @State private var selectedAngleValue: Double?
    @State private var customStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customEndDate: Date = Date()

    enum StatPeriod: String, CaseIterable {
        case thisWeek  = "Week"
        case thisMonth = "Month"
        case thisYear  = "Year"
        case allTime   = "All"
        case custom    = "Custom"

        var startDate: Date? {
            let cal = Calendar.current
            let now = Date()
            switch self {
            case .thisWeek:
                return cal.dateInterval(of: .weekOfYear, for: now)?.start
            case .thisMonth:
                return cal.date(from: cal.dateComponents([.year, .month], from: now))
            case .thisYear:
                return cal.date(from: cal.dateComponents([.year], from: now))
            case .allTime, .custom:
                return nil
            }
        }
    }

    private var activities: [Activity] {
        allActivities.filter { activity in
            guard selectedTypes.contains(activity.type) else { return false }
            if period == .custom {
                let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: customEndDate) ?? customEndDate
                return activity.date >= customStartDate && activity.date <= endOfDay
            }
            return period.startDate.map { activity.date >= $0 } ?? true
        }
    }

    private var totalMinutesCount: Int {
        activities.reduce(0) { $0 + $1.durationMinutes }
    }

    private var totalHours: Double {
        Double(totalMinutesCount) / 60
    }

    private func formatHoursMinutes(_ totalMinutes: Int) -> String {
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        return String(format: "%d:%02d", h, m)
    }

    private func formatHoursMinutes(hours: Double) -> String {
        formatHoursMinutes(Int(hours * 60))
    }

    private func countForType(_ type: ActivityType) -> Int {
        activities.filter { $0.type == type }.count
    }

    private func typeForAngle(_ angle: Double) -> ActivityType? {
        var cumulative = 0.0
        for item in hoursByType {
            cumulative += item.hours
            if angle <= cumulative {
                return item.type
            }
        }
        return hoursByType.last?.type
    }

    private var hoursByType: [(type: ActivityType, hours: Double)] {
        let grouped = Dictionary(grouping: activities, by: \.type)
        return ActivityType.allCases.compactMap { type in
            let mins = grouped[type]?.reduce(0) { $0 + $1.durationMinutes } ?? 0
            guard mins > 0 else { return nil }
            return (type: type, hours: Double(mins) / 60)
        }.sorted { $0.hours > $1.hours }
    }

    private var callSubcategoryBreakdown: [(name: String, hours: Double, count: Int)] {
        let callActivities = activities.filter { $0.type == .call }
        let grouped = Dictionary(grouping: callActivities) { $0.customTypeName }
        return grouped.map { (name, acts) in
            let mins = acts.reduce(0) { $0 + $1.durationMinutes }
            return (name: name.isEmpty ? "Uncategorized" : name, hours: Double(mins) / 60, count: acts.count)
        }.sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            List {
                periodPicker
                typeFilter
                summaryCards

                if hoursByType.isEmpty {
                    ContentUnavailableView(
                        "No Data",
                        systemImage: "chart.bar",
                        description: Text("Log activities to see your stats here.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    chartSection
                    breakdownSection
                }
            }
            .navigationTitle("Statistics")
        }
    }

    // MARK: - Sections

    private var periodPicker: some View {
        Section {
            Picker("Period", selection: $period.animation()) {
                ForEach(StatPeriod.allCases, id: \.self) { p in
                    Text(p.rawValue).tag(p)
                }
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            if period == .custom {
                DatePicker("From", selection: $customStartDate, displayedComponents: .date)
                    .frame(minHeight: 44)
                    .transition(.opacity.combined(with: .move(edge: .top)))

                DatePicker("To", selection: $customEndDate, in: customStartDate..., displayedComponents: .date)
                    .frame(minHeight: 44)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var typeFilter: some View {
        Section {
            DisclosureGroup("Activity Types", isExpanded: $isTypeFilterExpanded) {
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
                    }
                    .frame(minHeight: 44)
                }
            }
        }
    }

    private var summaryCards: some View {
        Section {
            HStack(spacing: 0) {
                StatSummaryCard(
                    value: formatHoursMinutes(totalMinutesCount),
                    unit: "hours",
                    icon: "clock.fill",
                    color: .blue
                )
                Divider()
                StatSummaryCard(
                    value: "\(activities.count)",
                    unit: "activities",
                    icon: "list.bullet.clipboard.fill",
                    color: .orange
                )
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }

    private var chartSection: some View {
        Section("Hours by Type") {
            Chart(hoursByType, id: \.type) { item in
                SectorMark(
                    angle: .value("Hours", item.hours),
                    innerRadius: .ratio(0.6),
                    angularInset: 1.5
                )
                .foregroundStyle(item.type.color)
                .opacity(selectedChartType == nil || selectedChartType == item.type ? 1.0 : 0.4)
                .cornerRadius(4)
            }
            .chartAngleSelection(value: $selectedAngleValue)
            .chartBackground { proxy in
                GeometryReader { geo in
                    let frame = geo[proxy.plotFrame!]
                    VStack(spacing: 2) {
                        if let selected = selectedChartType {
                            Text("\(countForType(selected))")
                                .font(.title2.bold())
                                .monospacedDigit()
                            Text(selected.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(formatHoursMinutes(totalMinutesCount))
                                .font(.title2.bold())
                                .monospacedDigit()
                            Text("total")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .position(x: frame.midX, y: frame.midY)
                }
            }
            .frame(height: 220)
            .onChange(of: selectedAngleValue) { _, newValue in
                if let angle = newValue {
                    selectedChartType = typeForAngle(angle)
                } else {
                    selectedChartType = nil
                }
            }
        }
    }

    private var breakdownSection: some View {
        Section("Breakdown") {
            ForEach(hoursByType, id: \.type) { item in
                breakdownRow(item)
            }
        }
    }

    @ViewBuilder
    private func breakdownRow(_ item: (type: ActivityType, hours: Double)) -> some View {
        HStack {
            Image(systemName: item.type.systemImage)
                .foregroundStyle(item.type.color)
                .frame(width: 28)
            Text(item.type.displayName)
            Spacer()
            Text(formatHoursMinutes(hours: item.hours))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .frame(minHeight: 44)

        if item.type == .call {
            ForEach(callSubcategoryBreakdown, id: \.name) { sub in
                HStack {
                    Text(sub.name)
                        .font(.subheadline)
                    Spacer()
                    Text("(\(sub.count))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text(formatHoursMinutes(hours: sub.hours))
                        .font(.subheadline)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, 36)
                .frame(minHeight: 36)
            }
        }
    }
}

// MARK: - Summary Card

struct StatSummaryCard: View {
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title2)
            Text(value)
                .font(.title.bold())
                .monospacedDigit()
            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}
