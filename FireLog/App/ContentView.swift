//
//  ContentView.swift
//  FireLog
//
//  Created by Chan Lieu on 3/25/26.
//


import SwiftUI

struct ContentView: View {
    @State private var quickLogType: ActivityType?
    @State private var showingQuickLog = false

    var body: some View {
        TabView {
            ActivityListView()
                .tabItem {
                    Label("Log", systemImage: "list.bullet.clipboard.fill")
                }

            StatisticsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }

            ExportView()
                .tabItem {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
        .sheet(isPresented: $showingQuickLog) {
            NavigationStack {
                AddEditActivityView(initialType: quickLogType)
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "firelog" else { return }
        let typeParam = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "type" })?.value
        quickLogType = typeParam.flatMap { ActivityType(rawValue: $0) }
        showingQuickLog = true
    }
}
