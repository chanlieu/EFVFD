//
//  ActivityType.swift
//  FireLog
//
//  Created by Chan Lieu on 3/25/26.
//


import SwiftUI

enum ActivityType: String, CaseIterable, Codable {
    case call             = "call"
    case training         = "training"
    case meeting          = "meeting"
    case dutyShift      = "duty_shift"
    case publicEducation  = "public_education"
    case administrative   = "administrative"
    case custom           = "custom"

    var displayName: String {
        switch self {
        case .call:            return "Call"
        case .training:        return "Training"
        case .meeting:         return "Meeting"
        case .dutyShift:     return "Duty Shift"
        case .publicEducation: return "Public Education"
        case .administrative:  return "Administrative"
        case .custom:          return "Custom"
        }
    }

    var systemImage: String {
        switch self {
        case .call:            return "flame.fill"
        case .training:        return "figure.run"
        case .meeting:         return "person.3.fill"
        case .dutyShift:       return "building.2.fill"
        case .publicEducation: return "graduationcap.fill"
        case .administrative:  return "doc.text.fill"
        case .custom:          return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .call:            return .red
        case .training:        return .orange
        case .meeting:         return .blue
        case .dutyShift:       return .green
        case .publicEducation: return .purple
        case .administrative:  return Color(.systemGray)
        case .custom:          return .yellow
        }
    }
}

// MARK: - Call Subcategories

enum CallSubcategory: String, CaseIterable, Identifiable {
    case medicalAlpha     = "Medical: Alpha"
    case medicalBravo     = "Medical: Bravo"
    case medicalCharlie   = "Medical: Charlie"
    case medicalDelta     = "Medical: Delta"
    case medicalEcho      = "Medical: Echo"
    case fireAlarm        = "Fire: Alarm"
    case fireMutualAid    = "Fire: Mutual Aid"
    case fireSmokeGas     = "Fire: Smoke/Gas"
    case fireWiresDown    = "Fire: Wires Down"
    case mvaAlpha         = "MVA: Alpha"
    case mvaBravo         = "MVA: Bravo"
    case mvaCharlie       = "MVA: Charlie"
    case mvaDelta         = "MVA: Delta"
    case hazMat           = "HazMat"

    var id: String { rawValue }
    var displayName: String { rawValue }

    var systemImage: String {
        switch self {
        case .medicalAlpha, .medicalBravo, .medicalCharlie, .medicalDelta, .medicalEcho:
            return "cross.fill"
        default:
            return "flame.fill"
        }
    }
}
// MARK: - Role

enum Role: String, CaseIterable, Identifiable {
    case driver    = "Driver"
    case officer   = "Officer"
    case responder = "Responder"
    case scene     = "Scene"

    var id: String { rawValue }
    var displayName: String { rawValue }
}

// MARK: - Report Types

enum ReportType: String, CaseIterable, Identifiable {
    case narrative = "Narrative"
    case pcr       = "PCR"

    var id: String { rawValue }
    var displayName: String { rawValue }
}

