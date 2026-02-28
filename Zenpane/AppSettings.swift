import SwiftUI
import Combine

@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("userDisplayName") var userDisplayName: String = "Will"
    @AppStorage("weatherCity") var weatherCity: String = "Coshocton"
    @AppStorage("weatherLatitude") var weatherLatitude: Double = 40.272015
    @AppStorage("weatherLongitude") var weatherLongitude: Double = -81.859573
    @AppStorage("preferredQuoteTheme") var preferredQuoteTheme: String = "Focus"
}
