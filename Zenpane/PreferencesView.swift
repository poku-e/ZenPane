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

            Section("Appearance") {
                Picker("Mode", selection: Binding(
                    get: { settings.preferredAppearance },
                    set: { settings.preferredAppearance = $0 }
                )) {
                    ForEach(AppAppearance.allCases) { appearance in
                        Text(appearance.title).tag(appearance)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Motivation") {
                Picker("Quote Theme", selection: $settings.preferredQuoteTheme) {
                    ForEach(quoteThemes, id: \.self) { theme in
                        Text(theme).tag(theme)
                    }
                }
            }

            Section("Weather") {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Current Weather Location")
                            .font(.subheadline.weight(.semibold))

                        Text(settings.weatherCity)
                            .font(.body)

                        Text(
                            "\(settings.weatherLatitude.formatted(.number.precision(.fractionLength(4)))), " +
                            "\(settings.weatherLongitude.formatted(.number.precision(.fractionLength(4))))"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button(settings.isUpdatingLocation ? "Locating..." : "Use Current Location") {
                        settings.requestCurrentLocation()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(settings.isUpdatingLocation)
                }

                Text(settings.locationStatusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Weather uses macOS Location Services to populate your current city and coordinates automatically.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(minWidth: 460)
        .preferredColorScheme(settings.preferredAppearance.colorScheme)
    }
}

#Preview {
    PreferencesView()
        .environmentObject(AppSettings())
}
