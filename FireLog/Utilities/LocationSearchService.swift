//
//  LocationSearchService.swift
//  FireLog
//
//  Created by Chan Lieu on 3/26/26.
//

import MapKit

@Observable
final class LocationSearchService: NSObject, MKLocalSearchCompleterDelegate {
    var queryFragment: String = "" {
        didSet {
            if queryFragment.isEmpty {
                results = []
                completer.cancel()
            } else {
                completer.queryFragment = queryFragment
            }
        }
    }

    private(set) var results: [MKLocalSearchCompletion] = []
    private(set) var isSearching: Bool = false

    private let completer: MKLocalSearchCompleter

    override init() {
        completer = MKLocalSearchCompleter()
        completer.resultTypes = [.address, .pointOfInterest]
        super.init()
        completer.delegate = self
    }

    // MARK: - MKLocalSearchCompleterDelegate

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        isSearching = false
        results = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        isSearching = false
        results = []
    }

    // MARK: - Full Search

    /// Resolves a completion to a full MKMapItem with coordinates.
    func resolveLocation(_ completion: MKLocalSearchCompletion) async throws -> MKMapItem? {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        return response.mapItems.first
    }
}
