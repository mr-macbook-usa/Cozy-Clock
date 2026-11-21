import Foundation
import CoreLocation
import Observation

/// A rough location (rounded to about 1 km). Saved on the device only.
struct Coordinate: Equatable, Codable, Sendable {
    var latitude: Double
    var longitude: Double
}

/// Sunrise and sunset for one day, or a polar day or night when the sun never sets or never rises.
enum SunEvents: Equatable {
    case normal(rise: Date, set: Date)
    case alwaysUp
    case alwaysDown
}

/// Real sunrise and sunset, worked out on the device with the NOAA sunrise equation (about a minute of accuracy).
enum Solar {
    static func events(on day: Date, at c: Coordinate, calendar: Calendar = .current) -> SunEvents {
        let rad = Double.pi / 180
        let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: day) ?? day
        let jd = noon.timeIntervalSince1970 / 86_400 + 2_440_587.5
        let js = (jd - 2_451_545 + c.longitude / 360).rounded() - c.longitude / 360
        let m = (357.5291 + 0.98560028 * js).truncatingRemainder(dividingBy: 360) * rad
        let center = 1.9148 * sin(m) + 0.02 * sin(2 * m) + 0.0003 * sin(3 * m)
        let lambda = (m / rad + center + 180 + 102.9372).truncatingRemainder(dividingBy: 360) * rad
        let transit = 2_451_545 + js + 0.0053 * sin(m) - 0.0069 * sin(2 * lambda)
        let sinDec = sin(lambda) * sin(23.4397 * rad)
        let cosDec = cos(asin(sinDec))
        let cosW = (sin(-0.833 * rad) - sin(c.latitude * rad) * sinDec) / (cos(c.latitude * rad) * cosDec)
        if cosW < -1 { return .alwaysUp }
        if cosW > 1 { return .alwaysDown }
        let w = acos(cosW) / rad / 360
        func date(_ julian: Double) -> Date { Date(timeIntervalSince1970: (julian - 2_440_587.5) * 86_400) }
        return .normal(rise: date(transit - w), set: date(transit + w))
    }
}

/// Where we are in the sky: day or night, and how far (0 to 1) across the sun's or the moon's arc.
struct SkyState: Equatable {
    let isDay: Bool
    let progress: Double
}

/// Day runs from the real sunrise to the real sunset when we know where you are, otherwise from 7 AM to 6 PM.
/// Night runs from sunset to the next sunrise.
enum SkyClock {
    static func events(on day: Date, at coordinate: Coordinate?, calendar: Calendar = .current) -> SunEvents {
        if let coordinate { return Solar.events(on: day, at: coordinate, calendar: calendar) }
        let rise = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: day) ?? day
        let set = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: day) ?? day
        return .normal(rise: rise, set: set)
    }

    static func state(at now: Date, coordinate: Coordinate?, calendar: Calendar = .current) -> SkyState {
        let today = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today.addingTimeInterval(86_400)

        switch events(on: now, at: coordinate, calendar: calendar) {
        case .alwaysUp:
            return SkyState(isDay: true, progress: fraction(now, from: today, to: tomorrow))
        case .alwaysDown:
            return SkyState(isDay: false, progress: fraction(now, from: today, to: tomorrow))
        case let .normal(rise, set):
            if now >= rise && now < set {
                return SkyState(isDay: true, progress: fraction(now, from: rise, to: set))
            }
            if now >= set {
                var nextRise = calendar.date(byAdding: .day, value: 1, to: tomorrow) ?? tomorrow
                if case let .normal(r, _) = events(on: tomorrow, at: coordinate, calendar: calendar) { nextRise = r }
                return SkyState(isDay: false, progress: fraction(now, from: set, to: nextRise))
            }
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
            var lastSet = today
            if case let .normal(_, s) = events(on: yesterday, at: coordinate, calendar: calendar) { lastSet = s }
            return SkyState(isDay: false, progress: fraction(now, from: lastSet, to: rise))
        }
    }

    private static func fraction(_ t: Date, from a: Date, to b: Date) -> Double {
        let span = max(b.timeIntervalSince(a), 1)
        return min(max(t.timeIntervalSince(a) / span, 0), 1)
    }
}

/// Asks once for your approximate location (When In Use, reduced accuracy) and remembers it on the device,
/// so the sky still matches your sunrise and sunset next time even before a fresh fix arrives.
@MainActor
@Observable
final class LocationProvider: NSObject, CLLocationManagerDelegate {
    private(set) var coordinate: Coordinate?
    private(set) var denied = false

    private let manager = CLLocationManager()
    private static let storageKey = "hearthCoordinate"

    override init() {
        super.init()
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let saved = try? JSONDecoder().decode(Coordinate.self, from: data) {
            coordinate = saved
        }
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyReduced
    }

    /// Call when the app appears or comes back to the foreground.
    func refresh() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            denied = false
            manager.requestLocation()
        default:
            denied = true
        }
    }

    private func store(_ c: Coordinate) {
        coordinate = c
        if let data = try? JSONEncoder().encode(c) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in self.refresh() }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        let c = Coordinate(
            latitude: (last.coordinate.latitude * 100).rounded() / 100,
            longitude: (last.coordinate.longitude * 100).rounded() / 100
        )
        Task { @MainActor in self.store(c) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Keep the last saved location (or the 7 AM to 6 PM fallback) and try again next time the app opens.
    }
}
