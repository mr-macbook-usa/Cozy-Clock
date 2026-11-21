import SwiftUI
import PhotosUI

struct ContentView: View {
    @AppStorage("palette") private var paletteRaw = Palette.dusk.rawValue
    @AppStorage("usePhoto") private var usePhoto = false
    @AppStorage("autoSky") private var autoSky = true
    @AppStorage("hour12") private var hour12 = true
    @AppStorage("showSeconds") private var showSeconds = true
    @AppStorage("nightDim") private var nightDim = false
    @AppStorage("zen") private var zen = false

    @State private var photo: UIImage? = PhotoStore.load()
    @State private var showBackgrounds = false
    @State private var location = LocationProvider()
    @Environment(\.scenePhase) private var scenePhase

    private var palette: Palette { Palette(rawValue: paletteRaw) ?? .dusk }
    private var accent: Color { zen ? Theme.zen.accent : palette.theme.accent }

    var body: some View {
        ZStack {
            BackgroundView(palette: palette, photo: usePhoto ? photo : nil, autoSky: autoSky, zen: zen, coordinate: location.coordinate)
            SunView(zen: zen, coordinate: location.coordinate)
            MoonView(zen: zen, coordinate: location.coordinate)

            VStack(spacing: 16) {
                topBar
                Spacer(minLength: 0)
                ClockCard(zen: zen, hour12: hour12, showSeconds: showSeconds, accent: accent)
                Spacer(minLength: 0)
                dock
                    .opacity(zen ? 0 : 1)
                    .offset(y: zen ? 24 : 0)
                    .allowsHitTesting(!zen)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            Color.black
                .opacity(nightDim ? 0.5 : 0)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .tint(accent)
        .animation(.smooth(duration: 0.8), value: zen)
        .animation(.easeInOut(duration: 0.5), value: nightDim)
        .sensoryFeedback(.impact(weight: .light), trigger: zen)
        .sheet(isPresented: $showBackgrounds) {
            BackgroundsSheet(
                paletteRaw: $paletteRaw, usePhoto: $usePhoto, autoSky: $autoSky, photo: $photo,
                coordinate: location.coordinate, locationDenied: location.denied
            )
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            location.refresh()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { location.refresh() }
        }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack {
            Button {
                zen.toggle()
            } label: {
                Label("Zen", systemImage: zen ? "leaf.fill" : "leaf")
                    .font(.subheadline.weight(.bold))
                    .padding(.horizontal, 4)
            }
            .buttonStyle(.glass)
            .accessibilityLabel(zen ? "Turn off Zen mode" : "Turn on Zen mode")

            Spacer()

            TimelineView(.everyMinute) { context in
                Text(context.date, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .glassEffect(.regular, in: .capsule)
            }
        }
    }

    // MARK: Dock

    private var dock: some View {
        GlassEffectContainer {
            HStack(spacing: 4) {
                dockButton("Backgrounds", "photo", active: showBackgrounds) { showBackgrounds = true }
                dockButton(hour12 ? "12-hour" : "24-hour", "clock", active: !hour12) { hour12.toggle() }
                dockButton("Seconds", "waveform.path.ecg", active: showSeconds) { showSeconds.toggle() }
                dockButton("Night dim", "moon.fill", active: nightDim) { nightDim.toggle() }
            }
            .padding(8)
            .glassEffect(.regular, in: .rect(cornerRadius: 34))
        }
    }

    private func dockButton(_ title: String, _ icon: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.title3)
                Text(title).font(.caption2.weight(.bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundStyle(active ? accent : Color.white.opacity(0.7))
            .background {
                if active {
                    RoundedRectangle(cornerRadius: 26).fill(.white.opacity(0.13))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Backgrounds sheet

struct BackgroundsSheet: View {
    @Binding var paletteRaw: String
    @Binding var usePhoto: Bool
    @Binding var autoSky: Bool
    @Binding var photo: UIImage?
    let coordinate: Coordinate?
    let locationDenied: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var pickerItem: PhotosPickerItem?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    Button {
                        autoSky = true
                        usePhoto = false
                    } label: {
                        tile(selected: autoSky && !usePhoto, accent: .white) {
                            if let img = SkyClock.state(at: .now, coordinate: coordinate).isDay ? SkyImages.day : SkyImages.night {
                                Color.clear.overlay { Image(uiImage: img).resizable().scaledToFill() }.clipped()
                            } else {
                                Color.blue.opacity(0.4)
                            }
                        } label: {
                            Text("Sky")
                        }
                    }
                    .buttonStyle(.plain)

                    ForEach(Palette.allCases) { p in
                        Button {
                            paletteRaw = p.rawValue
                            autoSky = false
                            usePhoto = false
                        } label: {
                            tile(selected: !usePhoto && !autoSky && paletteRaw == p.rawValue, accent: p.theme.accent) {
                                LinearGradient(
                                    colors: [p.theme.a, p.theme.b, p.theme.c],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            } label: {
                                Text(p.title)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        tile(selected: usePhoto && photo != nil, accent: .white) {
                            if let photo {
                                Color.clear.overlay { Image(uiImage: photo).resizable().scaledToFill() }.clipped()
                            } else {
                                Color.white.opacity(0.08)
                                    .overlay { Image(systemName: "photo.badge.plus").font(.title2) }
                            }
                        } label: {
                            Text(photo == nil ? "Add photo" : "Your photo")
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)

                if photo != nil {
                    Button("Remove my photo", role: .destructive) {
                        PhotoStore.remove()
                        autoSky = true
                        photo = nil
                        usePhoto = false
                    }
                    .font(.subheadline)
                    .padding(.bottom, 8)
                }

                Text(sunNote)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                Text("Photos stay on this device. A dark tint keeps the time easy to read.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }
            .navigationTitle("Backgrounds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    let small = image.downscaled(maxDimension: 2000)
                    PhotoStore.save(small)
                    photo = small
                    usePhoto = true
                    autoSky = false
                }
                pickerItem = nil
            }
        }
    }

    /// Today's sunrise and sunset, or why the sky is following 7 AM to 6 PM instead.
    private var sunNote: String {
        guard let coordinate else {
            return locationDenied
                ? "Location is off, so the sun and sky follow 7 AM to 6 PM. Turn on Location for Hearth Clock in Settings to match your real sunrise and sunset."
                : "The sun and sky follow 7 AM to 6 PM until Hearth Clock can use your location."
        }
        switch Solar.events(on: .now, at: coordinate) {
        case .alwaysUp:
            return "The sun stays up all day today where you are."
        case .alwaysDown:
            return "The sun stays down all day today where you are."
        case let .normal(rise, set):
            let r = rise.formatted(date: .omitted, time: .shortened)
            let s = set.formatted(date: .omitted, time: .shortened)
            return "Sunrise \(r) · Sunset \(s) today, based on your location."
        }
    }

    private func tile<Fill: View, Label: View>(
        selected: Bool,
        accent: Color,
        @ViewBuilder fill: () -> Fill,
        @ViewBuilder label: () -> Label
    ) -> some View {
        fill()
            .aspectRatio(1 / 1.1, contentMode: .fit)
            .overlay(alignment: .bottomLeading) {
                label()
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.6), radius: 4)
                    .padding(10)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(selected ? accent : .white.opacity(0.16), lineWidth: selected ? 2.5 : 1)
            }
    }
}

#Preview {
    ContentView()
}
