import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject private var settings: AppSettings

    private let quoteThemes = ["Focus", "Calm", "Momentum"]

    var body: some View {
        Form {
            Section("Profile") {
                TextField("Display Name", text: $settings.userDisplayName)
                    .textFieldStyle(.roundedBorder)
            }

            Section("Motivation") {
                Picker("Quote Theme", selection: $settings.preferredQuoteTheme) {
                    ForEach(quoteThemes, id: \.self) { theme in
                        Text(theme).tag(theme)
                    }
                }
            }

            Section("Weather") {
                HStack {
                    TextField("City", text: $settings.weatherCity)
                        .textFieldStyle(.roundedBorder)
                    TextField("Lat", value: $settings.weatherLatitude, format: .number)
                        .frame(width: 100)
                        .textFieldStyle(.roundedBorder)
                    TextField("Lon", value: $settings.weatherLongitude, format: .number)
                        .frame(width: 100)
                        .textFieldStyle(.roundedBorder)
                }
                Text("Weather data is provided by Weather.gov and supports US coordinates.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(minWidth: 460)
    }
}

#Preview {
    PreferencesView()
        .environmentObject(AppSettings())
}
