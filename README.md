[README.md](https://github.com/user-attachments/files/26327562/README.md)
# FireLog

A native iOS app for volunteer firefighters and first responders to log, track, and export their department activities.

## Overview

FireLog makes it easy to record every call, training, meeting, duty shift, and more — with rich detail like call subcategory, your role on scene, location, and duration. Statistics and charts give you an at-a-glance picture of your activity over time, and built-in export tools let you share your log as a CSV or PDF report.

## Features

**Activity Logging**
Quickly add and edit activity records with fields for type, date, duration, title, location, notes, role, and report types. Call entries support detailed subcategories (Medical Alpha–Echo, Fire, MVA, HazMat) and custom types for anything that doesn't fit a preset.

**Activity Types**
- Call (with subcategories)
- Training
- Meeting
- Duty Shift
- Public Education
- Administrative
- Custom

**Statistics**
Filter your log by week, month, year, all time, or a custom date range. See activity breakdowns by type with charts powered by Swift Charts, plus total hours and call counts.

**Export**
Export your activity log as a formatted CSV or PDF report, suitable for department records or reimbursement documentation.

**Widget**
A home screen widget extension (FireLogWidget) provides quick-glance info from your lock screen or home screen.

**Deep Links**
Jump straight to a quick-log sheet for a specific activity type via the `firelog://` URL scheme (e.g. from a shortcut or widget action).

## Tech Stack

- **SwiftUI** — declarative UI
- **SwiftData** — local persistence
- **Swift Charts** — statistics visualizations
- **MapKit / CoreLocation** — location search and storage
- **WidgetKit** — home screen widget extension
- Minimum deployment target: iOS 17+

## Project Structure

```
FireLog/
├── App/
│   ├── FIRELogApp.swift       # App entry point
│   └── ContentView.swift      # Tab-based navigation (Log, Stats, Export)
├── Models/
│   ├── Activity.swift         # SwiftData model
│   └── ActivityType.swift     # Enums: ActivityType, CallSubcategory, Role, ReportType
├── Views/
│   ├── ActivityListView.swift
│   ├── ActivityDetailView.swift
│   ├── AddEditActivityView.swift
│   ├── StatisticsView.swift
│   ├── ExportView.swift
│   └── LocationSearchView.swift
└── Utilities/
    ├── ExportManager.swift    # CSV and PDF generation
    └── LocationSearchService.swift

FireLogWidget/
├── FireLogWidget.swift
├── FireLogWidgetBundle.swift
├── FireLogWidgetControl.swift
└── FireLogWidgetLiveActivity.swift
```

## Getting Started

1. Clone the repository.
2. Open `FireLog.xcodeproj` in Xcode 16 or later.
3. Select your target device or simulator (iOS 17+).
4. Build and run (`⌘R`).

No external dependencies or package manager setup is required — the app uses only Apple frameworks.

## Author

Created by Chan Lieu · EFVFD
