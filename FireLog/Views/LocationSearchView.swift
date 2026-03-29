//
//  LocationSearchView.swift
//  FireLog
//
//  Created by Chan Lieu on 3/26/26.
//

import SwiftUI
import MapKit

struct LocationSearchView: View {
    @Environment(\.dismiss) private var dismiss

    /// Callback when the user selects a location.
    var onSelect: (String, Double, Double) -> Void

    @State private var searchService = LocationSearchService()
    @State private var isResolving = false
    @State private var errorMessage: String?
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        List {
            if let error = errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                        .font(.callout)
                }
            }

            if searchService.results.isEmpty && !searchService.queryFragment.isEmpty {
                ContentUnavailableView.search(text: searchService.queryFragment)
            } else {
                ForEach(searchService.results, id: \.self) { completion in
                    Button {
                        select(completion)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(completion.title)
                                .font(.body)
                                .foregroundStyle(.primary)
                            if !completion.subtitle.isEmpty {
                                Text(completion.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(minHeight: 44)
                    }
                    .disabled(isResolving)
                }
            }
        }
        .navigationTitle("Search Location")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $searchService.queryFragment,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search for a place"
        )
        .searchFocused($isSearchFocused)
        .onAppear { isSearchFocused = true }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .frame(minHeight: 44)
            }
        }
        .overlay {
            if isResolving {
                ProgressView("Loading...")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Actions

    private func select(_ completion: MKLocalSearchCompletion) {
        isResolving = true
        errorMessage = nil
        Task {
            do {
                guard let mapItem = try await searchService.resolveLocation(completion) else {
                    errorMessage = "Could not find location details."
                    isResolving = false
                    return
                }
                let name = [completion.title, completion.subtitle]
                    .filter { !$0.isEmpty }
                    .joined(separator: ", ")
                let coordinate = mapItem.location.coordinate
                onSelect(name, coordinate.latitude, coordinate.longitude)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isResolving = false
            }
        }
    }
}
