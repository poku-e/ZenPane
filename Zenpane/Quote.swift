//
//  DashboardViewModel.swift
//  Zenpane
//
//  Created by Corey Richardson on 11/1/25.
//

import Foundation
import Combine

// MARK: - Models
struct Quote: Codable {
    let content: String
    let author: String
}

struct Todo: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var completed: Bool

    init(id: UUID = UUID(), title: String, completed: Bool = false) {
        self.id = id
        self.title = title
        self.completed = completed
    }
}

// MARK: - ViewModel
@MainActor
class DashboardViewModel: ObservableObject {
    @Published var quote: String = "Loading quote..."
    @Published var author: String = ""
    @Published var weather: String = "Fetching weather..."
    @Published var todos: [Todo] = []

    private let quoteURL = URL(string: "https://api.quotable.io/random")!
    private let openWeatherKey = "<YOUR_OPENWEATHERMAP_API_KEY>" // Replace with real key
    private let city = "Orlando"

    // MARK: - Public Methods
    func loadData() {
        fetchQuote()
        fetchWeather()
        loadTodos()
    }

    // MARK: - Quotes
    func fetchQuote() {
        let urls = [
            URL(string: "https://api.quotable.io/random")!,
            URL(string: "https://zenquotes.io/api/random")!
        ]

        for url in urls {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data = data else { return }

                if url.absoluteString.contains("quotable") {
                    if let result = try? JSONDecoder().decode(Quote.self, from: data) {
                        DispatchQueue.main.async {
                            self.quote = "“\(result.content)”"
                            self.author = result.author
                        }
                        return
                    }
                } else if let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                          let item = array.first,
                          let quote = item["q"] as? String,
                          let author = item["a"] as? String {
                    DispatchQueue.main.async {
                        self.quote = "“\(quote)”"
                        self.author = author
                    }
                    return
                }
            }.resume()
        }
    }

    // MARK: - Weather
    func fetchWeather() {
        guard openWeatherKey != "<YOUR_OPENWEATHERMAP_API_KEY>",
              let url = URL(string:
                "https://api.openweathermap.org/data/2.5/weather?q=\(city)&appid=\(openWeatherKey)&units=imperial")
        else {
            DispatchQueue.main.async {
                self.weather = "⚠️ Missing API Key"
            }
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let main = json["main"] as? [String: Any],
                  let temp = main["temp"] as? Double,
                  let weatherArray = json["weather"] as? [[String: Any]],
                  let condition = weatherArray.first?["main"] as? String
            else {
                DispatchQueue.main.async {
                    self.weather = "Weather unavailable"
                }
                return
            }

            DispatchQueue.main.async {
                self.weather = String(format: "%.0f°F — %@", temp, condition)
            }
        }.resume()
    }

    // MARK: - Todos
    func loadTodos() {
        if let data = UserDefaults.standard.data(forKey: "todos"),
           let decoded = try? JSONDecoder().decode([Todo].self, from: data) {
            todos = decoded
        }
    }

    func saveTodos() {
        if let encoded = try? JSONEncoder().encode(todos) {
            UserDefaults.standard.set(encoded, forKey: "todos")
        }
    }

    func addTodo(title: String) {
        todos.append(Todo(title: title))
        saveTodos()
    }

    func toggleTodo(at index: Int) {
        todos[index].completed.toggle()
        saveTodos()
    }

    func removeTodo(at index: Int) {
        todos.remove(at: index)
        saveTodos()
    }
}
