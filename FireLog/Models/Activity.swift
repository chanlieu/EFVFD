//
//  Activity.swift
//  FireLog
//
//  Created by Chan Lieu on 3/25/26.
//


import SwiftData
import Foundation
import CoreLocation

@Model
final class Activity {
    var id: UUID
    var typeRawValue: String
    var date: Date
    var durationMinutes: Int
    var title: String
    var notes: String
    var location: String
    var locationLatitude: Double?
    var locationLongitude: Double?
    var customTypeName: String
    var roleRawValue: String?
    var reportTypesRawValue: String?
    var callID: String?
    var createdAt: Date
    var updatedAt: Date

    var type: ActivityType {
        get { ActivityType(rawValue: typeRawValue) ?? .custom }
        set { typeRawValue = newValue.rawValue }
    }

    /// The name shown in UI: subcategory for calls, custom name if set, otherwise the type's display name.
    var displayTypeName: String {
        if (type == .call || type == .custom) && !customTypeName.isEmpty {
            return customTypeName
        }
        return type.displayName
    }

    var role: Role? {
        get { roleRawValue.flatMap { Role(rawValue: $0) } }
        set { roleRawValue = newValue?.rawValue }
    }

    var reportTypes: Set<ReportType> {
        get {
            guard let raw = reportTypesRawValue, !raw.isEmpty else { return [] }
            return Set(raw.split(separator: ",").compactMap { ReportType(rawValue: String($0)) })
        }
        set {
            if newValue.isEmpty {
                reportTypesRawValue = nil
            } else {
                reportTypesRawValue = newValue.map(\.rawValue).sorted().joined(separator: ",")
            }
        }
    }

    /// Returns a coordinate if both latitude and longitude are stored.
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = locationLatitude, let lng = locationLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    /// The SF Symbol name, using the subcategory icon for calls when available.
    var displayIcon: String {
        if type == .call, let sub = CallSubcategory(rawValue: customTypeName) {
            return sub.systemImage
        }
        return type.systemImage
    }

    /// Human-readable duration string, e.g. "1h 30m".
    var durationFormatted: String {
        let h = durationMinutes / 60
        let m = durationMinutes % 60
        switch (h, m) {
        case (0, _): return "\(m)m"
        case (_, 0): return "\(h)h"
        default:     return "\(h)h \(m)m"
        }
    }

    init(
        id: UUID = UUID(),
        type: ActivityType = .call,
        date: Date = Date(),
        durationMinutes: Int = 30,
        title: String = "",
        notes: String = "",
        location: String = "",
        locationLatitude: Double? = nil,
        locationLongitude: Double? = nil,
        customTypeName: String = ""
    ) {
        self.id = id
        self.typeRawValue = type.rawValue
        self.date = date
        self.durationMinutes = durationMinutes
        self.title = title
        self.notes = notes
        self.location = location
        self.locationLatitude = locationLatitude
        self.locationLongitude = locationLongitude
        self.customTypeName = customTypeName
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}