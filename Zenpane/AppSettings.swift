import SwiftUI
import Combine
import CoreLocation

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

@MainActor
final class AppSettings: NSObject, ObservableObject, CLLocationManagerDelegate {
    @AppStorage("userDisplayName") var userDisplayName: String = "Will"
    @AppStorage("weatherCity") var weatherCity: String = "Coshocton"
    @AppStorage("weatherLatitude") var weatherLatitude: Double = 40.272015
    @AppStorage("weatherLongitude") var weatherLongitude: Double = -81.859573
    @AppStorage("preferredQuoteTheme") var preferredQuoteTheme: String = "Focus"
    @AppStorage("preferredAppearance") private var preferredAppearanceRawValue: String = AppAppearance.system.rawValue

    @Published var isUpdatingLocation = false
    @Published var locationStatusMessage = "Use your current location to set weather automatically."

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    var preferredAppearance: AppAppearance {
        get { AppAppearance(rawValue: preferredAppearanceRawValue) ?? .system }
        set { preferredAppearanceRawValue = newValue.rawValue }
    }

    func requestCurrentLocation() {
        guard CLLocationManager.locationServicesEnabled() else {
            locationStatusMessage = "Location Services are disabled in macOS settings."
            return
        }

        isUpdatingLocation = true
        locationStatusMessage = "Fetching current location..."

        if #available(macOS 11.0, *) {
            locationManager.requestLocation()
        } else {
            locationManager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            finishLocationUpdate(message: "Unable to determine your current location.")
            return
        }

        weatherLatitude = location.coordinate.latitude
        weatherLongitude = location.coordinate.longitude

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            Task { @MainActor in
                guard let self else { return }

                if let placemark = placemarks?.first {
                    self.weatherCity =
                        placemark.locality
                        ?? placemark.subAdministrativeArea
                        ?? placemark.administrativeArea
                        ?? "Current Location"

                    self.finishLocationUpdate(
                        message: "Weather location updated to \(self.weatherCity)."
                    )
                } else if error != nil {
                    self.weatherCity = "Current Location"
                    self.finishLocationUpdate(
                        message: "Coordinates updated, but city name could not be resolved."
                    )
                } else {
                    self.finishLocationUpdate(message: "Coordinates updated from current location.")
                }
            }
        }

        if #unavailable(macOS 11.0) {
            manager.stopUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finishLocationUpdate(message: "Location lookup failed. Check macOS Location Services permissions.")
    }

    private func finishLocationUpdate(message: String) {
        isUpdatingLocation = false
        locationStatusMessage = message
    }
}
