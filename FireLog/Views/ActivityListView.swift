//
//  ActivityListView.swift
//  FireLog
//
//  Created by Chan Lieu on 3/25/26.
//


import SwiftUI
import SwiftData

struct ActivityListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Activity.date, order: .reverse) private var activities: [Activity]

    @State private var showingAdd = false
    @State private var searchText = ""
    @State private var filterType: ActivityType?

    private var filtered: [Activity] {
        activities.filter { activity in
            let matchSearch = searchText.isEmpty
                || activity.title.localizedCaseInsensitiveContains(searchText)
                || activity.notes.localizedCaseInsensitiveContains(searchText)
                || activity.location.localizedCaseInsensitiveContains(searchText)
                || activity.displayTypeName.localizedCaseInsensitiveContains(searchText)
            let matchType = filterType == nil || activity.type == filterType
            return matchSearch && matchType
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                typeFilterBar
                activityList
            }
            .navigationTitle("FIRELog")
            .searchable(text: $searchText, prompt: "Search activities")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                            .frame(width: 44, height: 44)
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                NavigationStack {
                    AddEditActivityView()
                }
            }
        }
    }

    private var typeFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                TypeFilterChip(
                    label: "All",
                    icon: nil,
                    color: .accentColor,
                    isSelected: filterType == nil
                ) {
                    filterType = nil
                }
                ForEach(ActivityType.allCases, id: \.self) { type in
                    TypeFilterChip(
                        label: type.displayName,
                        icon: type.systemImage,
                        color: type.color,
                        isSelected: filterType == type
                    ) {
                        filterType = filterType == type ? nil : type
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var activityList: some View {
        if filtered.isEmpty {
            ContentUnavailableView(
                searchText.isEmpty ? "No Activities" : "No Results",
                systemImage: "list.bullet.clipboard",
                description: Text(
                    searchText.isEmpty
                        ? "Tap + to log your first activity."
                        : "Try a different search or filter."
                )
            )
        } else {
            List {
                ForEach(filtered) { activity in
                    NavigationLink(value: activity) {
                        ActivityRowView(activity: activity)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                .onDelete(perform: delete)
            }
            .listStyle(.plain)
            .navigationDestination(for: Activity.self) { activity in
                ActivityDetailView(activity: activity)
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filtered[index])
        }
    }
}

// MARK: - Row

struct ActivityRowView: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .topLeading) {
                Circle()
                    .fill(activity.type.color.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: activity.displayIcon)
                    .foregroundStyle(activity.type.color)
                    .font(.system(size: 22))
                    .frame(width: 48, height: 48)
                if !activity.reportTypes.isEmpty {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.system(size: 12))
                        .offset(x: -2, y: -2)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title.isEmpty ? activity.displayTypeName : activity.title)
                    .font(.headline)

                HStack(spacing: 6) {
                    Text(activity.date.formatted(date: .abbreviated, time: .omitted))
                    Text("·")
                    Text(activity.durationFormatted)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                if !activity.location.isEmpty {
                    Label(activity.location, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
        .frame(minHeight: 44)
    }
}

// MARK: - Filter Chip

struct TypeFilterChip: View {
    let label: String
    let icon: String?
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon).font(.caption)
                }
                Text(label).font(.subheadline)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? color.opacity(0.18) : Color(.systemGray6))
            .foregroundStyle(isSelected ? color : .primary)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isSelected ? color : Color.clear, lineWidth: 1.5))
        }
        .frame(minHeight: 44)
    }
}
