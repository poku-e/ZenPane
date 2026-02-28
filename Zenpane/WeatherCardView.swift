import SwiftUI

struct WeatherCardView: View {
    let location: String
    let headline: String
    let detail: String
    let secondaryDetail: String
    let forecast: [ForecastPeriod]
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Forecast", systemImage: "cloud.sun.fill")
                        .font(.headline)
                    Text(location.isEmpty ? "Current outdoor conditions" : location)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Refresh weather")
            }

            Text(headline)
                .font(.system(size: 28, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(detail)
                .font(.subheadline)

            Text(secondaryDetail)
                .font(.caption)
                .foregroundStyle(.secondary)

            if !forecast.isEmpty {
                VStack(spacing: 10) {
                    ForEach(forecast) { period in
                        HStack(alignment: .top, spacing: 12) {
                            Text(period.name)
                                .font(.caption.weight(.semibold))
                                .frame(width: 72, alignment: .leading)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(period.temperatureText)
                                    .font(.caption.weight(.semibold))
                                Text(period.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(12)
                .background(.thinMaterial.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Weather panel")
    }
}

#Preview {
    WeatherCardView(
        location: "Coshocton",
        headline: "72°F",
        detail: "Partly cloudy",
        secondaryDetail: "Tonight: 58°F • Calm",
        forecast: [
            ForecastPeriod(name: "Today", temperatureText: "72°F", detail: "Partly cloudy"),
            ForecastPeriod(name: "Tonight", temperatureText: "58°F", detail: "Mostly clear")
        ],
        onRefresh: {}
    )
}
