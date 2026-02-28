//
//  DashboardViewModel.swift
//  Zenpane
//
//  Created by Corey Richardson on 11/1/25.
//

import Foundation
import SwiftUI
import Combine

struct Quote: Codable {
    let content: String
    let author: String
}

struct SavedQuote: Identifiable, Codable, Hashable {
    let id: UUID
    let content: String
    let author: String
    let theme: String
    let savedAt: Date

    init(id: UUID = UUID(), content: String, author: String, theme: String, savedAt: Date = .now) {
        self.id = id
        self.content = content
        self.author = author
        self.theme = theme
        self.savedAt = savedAt
    }
}

enum TodoPriority: String, Codable, CaseIterable, Identifiable {
    case high
    case medium
    case low

    var id: String { rawValue }

    var title: String {
        switch self {
        case .high:
            return "High"
        case .medium:
            return "Medium"
        case .low:
            return "Low"
        }
    }

    var symbolName: String {
        switch self {
        case .high:
            return "exclamationmark.circle.fill"
        case .medium:
            return "equal.circle.fill"
        case .low:
            return "arrow.down.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .blue
        }
    }
}

enum TodoFilter: String, CaseIterable, Identifiable {
    case today
    case upcoming
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today:
            return "Today"
        case .upcoming:
            return "Upcoming"
        case .completed:
            return "Completed"
        }
    }
}

struct Todo: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var completed: Bool
    var priority: TodoPriority
    var dueDate: Date?
    var isPinned: Bool
    let createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        completed: Bool = false,
        priority: TodoPriority = .medium,
        dueDate: Date? = .now,
        isPinned: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.completed = completed
        self.priority = priority
        self.dueDate = dueDate
        self.isPinned = isPinned
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case completed
        case priority
        case dueDate
        case isPinned
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        completed = try container.decodeIfPresent(Bool.self, forKey: .completed) ?? false
        priority = try container.decodeIfPresent(TodoPriority.self, forKey: .priority) ?? .medium
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
    }
}

struct ForecastPeriod: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let temperatureText: String
    let detail: String
}

struct WeatherSnapshot {
    let location: String
    let headline: String
    let detail: String
    let secondaryDetail: String
    let forecast: [ForecastPeriod]
}

struct NWSPointsResponse: Decodable {
    let properties: NWSPointsProperties
}

struct NWSPointsProperties: Decodable {
    let forecast: URL
    let forecastHourly: URL
}

struct NWSForecastResponse: Decodable {
    let properties: NWSForecastProperties
}

struct NWSForecastProperties: Decodable {
    let periods: [NWSForecastPeriod]
}

struct NWSForecastPeriod: Decodable {
    let name: String
    let temperature: Int
    let temperatureUnit: String
    let shortForecast: String
}

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var quote: String = "Loading quote..."
    @Published var author: String = ""
    @Published var savedQuotes: [SavedQuote] = []
    @Published var activeQuoteTheme: String = "Focus"

    @Published var weatherLocation: String = ""
    @Published var weatherHeadline: String = "Fetching weather..."
    @Published var weatherDetail: String = "Checking conditions"
    @Published var weatherSecondaryDetail: String = "Waiting for forecast"
    @Published var weatherForecast: [ForecastPeriod] = []

    @Published var todos: [Todo] = []

    private let settings = AppSettings()
    private let quoteStorageKey = "savedQuotes"
    private let todoStorageKey = "todos"

    func loadData() {
        loadTodos()
        loadSavedQuotes()
        activeQuoteTheme = settings.preferredQuoteTheme
        fetchQuote()
        fetchWeather()
    }

    func refreshDashboard() {
        activeQuoteTheme = settings.preferredQuoteTheme
        fetchQuote()
        fetchWeather()
    }

    func fetchQuote() {
        activeQuoteTheme = settings.preferredQuoteTheme

        guard let url = URL(string: "https://zenquotes.io/api/random") else {
            applyFallbackQuote()
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self else { return }

            guard let data else {
                Task { @MainActor in
                    self.applyFallbackQuote()
                }
                return
            }

            Task { @MainActor in
                if let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                   let item = array.first,
                   let quote = item["q"] as? String,
                   let author = item["a"] as? String {
                    self.quote = "“\(quote)”"
                    self.author = author
                } else {
                    self.applyFallbackQuote()
                }
            }
        }.resume()
    }

    func saveCurrentQuote() {
        guard !quote.isEmpty, !isCurrentQuoteSaved else { return }

        savedQuotes.insert(
            SavedQuote(content: quote, author: author, theme: activeQuoteTheme),
            at: 0
        )
        saveSavedQuotes()
    }

    var isCurrentQuoteSaved: Bool {
        savedQuotes.contains { $0.content == quote && $0.author == author }
    }

    func fetchWeather() {
        Task {
            await loadWeather()
        }
    }

    private func loadWeather() async {
        weatherLocation = settings.weatherCity

        do {
            let snapshot = try await fetchNationalWeatherSnapshot(
                latitude: settings.weatherLatitude,
                longitude: settings.weatherLongitude,
                city: settings.weatherCity
            )
            weatherLocation = snapshot.location
            weatherHeadline = snapshot.headline
            weatherDetail = snapshot.detail
            weatherSecondaryDetail = snapshot.secondaryDetail
            weatherForecast = snapshot.forecast
        } catch {
            weatherHeadline = "Unavailable"
            weatherDetail = weatherErrorMessage(for: error)
            weatherSecondaryDetail = "Review connection or location settings"
            weatherForecast = []
        }
    }

    private func fetchNationalWeatherSnapshot(
        latitude: Double,
        longitude: Double,
        city: String
    ) async throws -> WeatherSnapshot {
        guard let pointsURL = URL(string: "https://api.weather.gov/points/\(latitude),\(longitude)") else {
            throw WeatherError.invalidForecastURL
        }

        let pointsData = try await fetchWeatherData(from: pointsURL)
        let pointsResponse = try JSONDecoder().decode(NWSPointsResponse.self, from: pointsData)

        async let hourlyData = fetchWeatherData(from: pointsResponse.properties.forecastHourly)
        async let dailyData = fetchWeatherData(from: pointsResponse.properties.forecast)

        let hourlyForecast = try JSONDecoder().decode(
            NWSForecastResponse.self,
            from: await hourlyData
        )
        let dailyForecast = try JSONDecoder().decode(
            NWSForecastResponse.self,
            from: await dailyData
        )

        guard let currentPeriod = hourlyForecast.properties.periods.first else {
            throw WeatherError.missingForecast
        }

        let outlook = Array(dailyForecast.properties.periods.prefix(3)).map { period in
            ForecastPeriod(
                name: period.name,
                temperatureText: "\(period.temperature)°\(period.temperatureUnit)",
                detail: period.shortForecast
            )
        }

        let secondaryDetail: String
        if let nextPeriod = dailyForecast.properties.periods.dropFirst().first {
            secondaryDetail = "\(nextPeriod.name): \(nextPeriod.temperature)°\(nextPeriod.temperatureUnit) • \(nextPeriod.shortForecast)"
        } else {
            secondaryDetail = "No extended forecast available"
        }

        return WeatherSnapshot(
            location: city,
            headline: "\(currentPeriod.temperature)°\(currentPeriod.temperatureUnit)",
            detail: currentPeriod.shortForecast,
            secondaryDetail: secondaryDetail,
            forecast: outlook
        )
    }

    private func fetchWeatherData(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue("Zenpane macOS app", forHTTPHeaderField: "User-Agent")
        request.setValue("application/geo+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 404 {
                throw WeatherError.locationUnsupported
            }
            throw WeatherError.httpStatus(httpResponse.statusCode)
        }

        return data
    }

    private enum WeatherError: LocalizedError {
        case invalidForecastURL
        case invalidResponse
        case missingForecast
        case locationUnsupported
        case httpStatus(Int)

        var errorDescription: String? {
            switch self {
            case .invalidForecastURL:
                return "Invalid weather URL"
            case .invalidResponse:
                return "Invalid weather response"
            case .missingForecast:
                return "No weather forecast available"
            case .locationUnsupported:
                return "Weather.gov supports US locations only"
            case .httpStatus:
                return "Weather service returned an error"
            }
        }
    }

    private func weatherErrorMessage(for error: Error) -> String {
        if let weatherError = error as? WeatherError {
            return weatherError.localizedDescription
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed, .notConnectedToInternet:
                return "Weather unavailable. Check your internet connection."
            default:
                break
            }
        }

        return "Unable to load weather right now."
    }

    func loadTodos() {
        if let data = UserDefaults.standard.data(forKey: todoStorageKey),
           let decoded = try? JSONDecoder().decode([Todo].self, from: data) {
            todos = decoded
        }
    }

    func saveTodos() {
        if let encoded = try? JSONEncoder().encode(todos) {
            UserDefaults.standard.set(encoded, forKey: todoStorageKey)
        }
    }

    func addTodo(title: String, priority: TodoPriority = .medium, dueDate: Date? = .now, pinned: Bool = false) {
        todos.append(Todo(title: title, priority: priority, dueDate: dueDate, isPinned: pinned))
        saveTodos()
    }

    func toggleTodo(id: Todo.ID) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].completed.toggle()
        saveTodos()
    }

    func removeTodo(id: Todo.ID) {
        todos.removeAll { $0.id == id }
        saveTodos()
    }

    func removeCompletedTodos() {
        todos.removeAll { $0.completed }
        saveTodos()
    }

    func updateTodoTitle(id: Todo.ID, title: String) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].title = title
        saveTodos()
    }

    func updateTodoPriority(id: Todo.ID, priority: TodoPriority) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].priority = priority
        saveTodos()
    }

    func updateTodoDueDate(id: Todo.ID, dueDate: Date?) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].dueDate = dueDate
        saveTodos()
    }

    func togglePin(id: Todo.ID) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].isPinned.toggle()
        saveTodos()
    }

    func todoIndices(for filter: TodoFilter) -> [Int] {
        let calendar = Calendar.current

        return todos.indices
            .filter { index in
                let todo = todos[index]

                switch filter {
                case .today:
                    guard !todo.completed else { return false }
                    guard let dueDate = todo.dueDate else { return true }
                    return calendar.isDateInToday(dueDate) || dueDate < calendar.startOfDay(for: .now)
                case .upcoming:
                    guard !todo.completed else { return false }
                    guard let dueDate = todo.dueDate else { return false }
                    return dueDate > calendar.endOfDay(for: .now)
                case .completed:
                    return todo.completed
                }
            }
            .sorted { lhs, rhs in
                let left = todos[lhs]
                let right = todos[rhs]

                if left.isPinned != right.isPinned {
                    return left.isPinned && !right.isPinned
                }

                if left.priority != right.priority {
                    return left.priority.sortOrder < right.priority.sortOrder
                }

                switch (left.dueDate, right.dueDate) {
                case let (lhsDate?, rhsDate?):
                    return lhsDate < rhsDate
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    return left.createdAt < right.createdAt
                }
            }
    }

    var focusTodos: [Todo] {
        todoIndices(for: .today)
            .prefix(3)
            .map { todos[$0] }
    }

    var overdueCount: Int {
        let startOfToday = Calendar.current.startOfDay(for: .now)
        return todos.filter {
            !$0.completed && ($0.dueDate.map { $0 < startOfToday } ?? false)
        }.count
    }

    var upcomingCount: Int {
        let endOfToday = Calendar.current.endOfDay(for: .now)
        return todos.filter {
            !$0.completed && ($0.dueDate.map { $0 > endOfToday } ?? false)
        }.count
    }

    var completedCount: Int {
        todos.filter { $0.completed }.count
    }

    private func loadSavedQuotes() {
        if let data = UserDefaults.standard.data(forKey: quoteStorageKey),
           let decoded = try? JSONDecoder().decode([SavedQuote].self, from: data) {
            savedQuotes = decoded
        }
    }

    private func saveSavedQuotes() {
        if let encoded = try? JSONEncoder().encode(savedQuotes) {
            UserDefaults.standard.set(encoded, forKey: quoteStorageKey)
        }
    }

    private func applyFallbackQuote() {
        let fallback = fallbackQuotes[activeQuoteTheme]?.randomElement()
            ?? fallbackQuotes["Focus"]?.randomElement()
            ?? ("Momentum creates clarity.", "Zenpane")

        quote = "“\(fallback.0)”"
        author = fallback.1
    }

    private let fallbackQuotes: [String: [(String, String)]] = [
        "Focus": [
            ("Progress comes from protecting what matters most.", "Zenpane"),
            ("Finish the next important thing before starting a new one.", "Zenpane"),
            ("Clarity is built by choosing fewer priorities, not more.", "Zenpane")
        ],
        "Calm": [
            ("A quieter plan is still a strong plan.", "Zenpane"),
            ("Steady work beats frantic work.", "Zenpane"),
            ("Protect your attention and the day gets easier.", "Zenpane")
        ],
        "Momentum": [
            ("Small completions create large momentum.", "Zenpane"),
            ("Start moving and the next step gets obvious.", "Zenpane"),
            ("Consistency compounds faster than intensity.", "Zenpane")
        ]
    ]
}
private extension TodoPriority {
    var sortOrder: Int {
        switch self {
        case .high:
            return 0
        case .medium:
            return 1
        case .low:
            return 2
        }
    }
}

private extension Calendar {
    func endOfDay(for date: Date) -> Date {
        let start = startOfDay(for: date)
        return self.date(byAdding: DateComponents(day: 1, second: -1), to: start) ?? date
    }
}
