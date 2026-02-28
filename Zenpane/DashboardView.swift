//
//  DashboardView.swift
//  Zenpane
//
//  Created by Corey Richardson on 11/1/25.
//

import SwiftUI

struct DashboardView: View {
    @Environment(\.openSettings) private var openSettings
    @StateObject private var vm = DashboardViewModel()
    @StateObject private var settings = AppSettings()
    private let scrollIndicatorInset: CGFloat = 10
    private let contentPadding = EdgeInsets(top: 24, leading: 24, bottom: 32, trailing: 50)

    var body: some View {
        GeometryReader { proxy in
            let layout = dashboardLayout(for: proxy.size)

            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow)
                    .clipShape(RoundedRectangle(cornerRadius: 24))

                ScrollView([.vertical, .horizontal], showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        todayStrip(quickActionsWidth: layout.quickActionsWidth)
                        metricsRow

                        HStack(alignment: .top, spacing: 20) {
                            VStack(spacing: 20) {
                                TodoListView(vm: vm)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                            NotesView()
                                .frame(width: layout.sideColumnWidth, alignment: .top)
                                .frame(maxHeight: .infinity, alignment: .top)

                            VStack(spacing: 20) {
                                QuoteCardView(
                                    quote: vm.quote,
                                    author: vm.author,
                                    theme: vm.activeQuoteTheme,
                                    savedQuoteCount: vm.savedQuotes.count,
                                    isSaved: vm.isCurrentQuoteSaved,
                                    onRefresh: { vm.fetchQuote() },
                                    onSave: { vm.saveCurrentQuote() }
                                )

                                WeatherCardView(
                                    location: vm.weatherLocation,
                                    headline: vm.weatherHeadline,
                                    detail: vm.weatherDetail,
                                    secondaryDetail: vm.weatherSecondaryDetail,
                                    forecast: vm.weatherForecast,
                                    onRefresh: { vm.fetchWeather() }
                                )
                            }
                            .frame(width: layout.sideColumnWidth, alignment: .top)
                            .frame(maxHeight: .infinity, alignment: .top)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
                    .padding(contentPadding)
                    .frame(
                        minWidth: max(layout.minimumContentWidth, proxy.size.width),
                        minHeight: max(layout.minimumContentHeight, proxy.size.height),
                        alignment: .topLeading
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(scrollIndicatorInset)
                .clipped()
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .compositingGroup()
        }
        .preferredColorScheme(settings.preferredAppearance.colorScheme)
        .onAppear { vm.loadData() }
        .onChange(of: settings.weatherLatitude) { _, _ in vm.fetchWeather() }
        .onChange(of: settings.weatherLongitude) { _, _ in vm.fetchWeather() }
        .onChange(of: settings.weatherCity) { _, _ in vm.fetchWeather() }
        .onChange(of: settings.preferredQuoteTheme) { _, _ in vm.fetchQuote() }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Zenpane")
                    .font(.system(size: 30, weight: .semibold))

                Text(greeting)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .trailing, spacing: 6) {
                    Text(Date.now, format: .dateTime.weekday(.wide))
                        .font(.headline)
                    Text(Date.now, format: .dateTime.month(.abbreviated).day().year())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Button(action: { openSettings() }) {
                    Image(systemName: "gearshape.fill")
                        .font(.headline)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .background(.thinMaterial.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .help("Open settings")
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func todayStrip(quickActionsWidth: CGFloat) -> some View {
        HStack(spacing: 16) {
            TodayFocusCard(
                focusTodos: vm.focusTodos,
                overdueCount: vm.overdueCount,
                upcomingCount: vm.upcomingCount
            )

            QuickActionsCard(
                userName: settings.userDisplayName,
                quoteTheme: vm.activeQuoteTheme,
                onRefreshAll: { vm.refreshDashboard() }
            )
            .frame(width: quickActionsWidth)
        }
    }

    private var metricsRow: some View {
        HStack(spacing: 16) {
            DashboardMetricCard(
                title: "Today Queue",
                value: "\(vm.todoIndices(for: .today).count)",
                detail: "Tasks due or active today",
                systemImage: "list.bullet.rectangle"
            )

            DashboardMetricCard(
                title: "Upcoming",
                value: "\(vm.upcomingCount)",
                detail: "Scheduled beyond today",
                systemImage: "calendar.badge.clock"
            )

            DashboardMetricCard(
                title: "Completed",
                value: "\(vm.completedCount)",
                detail: "Closed items",
                systemImage: "checkmark.circle.fill"
            )

            DashboardMetricCard(
                title: "Saved Quotes",
                value: "\(vm.savedQuotes.count)",
                detail: "Personal motivation library",
                systemImage: "bookmark.fill"
            )
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let name = settings.userDisplayName.isEmpty ? "there" : settings.userDisplayName

        switch hour {
        case 0..<12:
            return "Good Morning, \(name)."
        case 12..<17:
            return "Good Afternoon, \(name)."
        default:
            return "Good Evening, \(name)."
        }
    }

    private func dashboardLayout(for size: CGSize) -> DashboardLayout {
        let availableWidth = max(size.width - 48, 0)
        let sideColumnWidth = min(max(availableWidth * 0.23, 280), 340)
        let quickActionsWidth = min(max(availableWidth * 0.2, 260), 320)

        return DashboardLayout(
            sideColumnWidth: sideColumnWidth,
            quickActionsWidth: quickActionsWidth,
            minimumContentWidth: 1320,
            minimumContentHeight: 860
        )
    }
}

private struct DashboardLayout {
    let sideColumnWidth: CGFloat
    let quickActionsWidth: CGFloat
    let minimumContentWidth: CGFloat
    let minimumContentHeight: CGFloat
}

private struct DashboardMetricCard: View {
    let title: String
    let value: String
    let detail: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private struct TodayFocusCard: View {
    let focusTodos: [Todo]
    let overdueCount: Int
    let upcomingCount: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Today", systemImage: "sun.max.fill")
                        .font(.headline)
                    Text("Top priorities and operational risk")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if overdueCount > 0 {
                    Text("\(overdueCount) overdue")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.red.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            if focusTodos.isEmpty {
                Text("The current queue is clear. Capture a new task or plan a few priorities.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 10) {
                    ForEach(focusTodos) { todo in
                        HStack(spacing: 12) {
                            Image(systemName: todo.priority.symbolName)
                                .foregroundStyle(todo.priority.tint)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(todo.title)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)

                                Text(todo.dueDate.map(Self.dateText(for:)) ?? "No due date")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if todo.isPinned {
                                Image(systemName: "pin.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(12)
                        .background(.thinMaterial.opacity(0.45))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }

            Text("\(upcomingCount) upcoming task\(upcomingCount == 1 ? "" : "s") scheduled beyond today.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private nonisolated static func dateText(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Due today"
        }

        if date < .now {
            return "Past due"
        }

        return date.formatted(date: .abbreviated, time: .omitted)
    }
}

private struct QuickActionsCard: View {
    let userName: String
    let quoteTheme: String
    let onRefreshAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Quick Actions", systemImage: "bolt.fill")
                .font(.headline)

            Text("Profile: \(userName.isEmpty ? "Not set" : userName)")
                .font(.subheadline)

            Text("Quote theme: \(quoteTheme)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Refresh Dashboard", action: onRefreshAll)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("r", modifiers: [.command, .shift])

            Text("Shortcut: Shift-Command-R")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

