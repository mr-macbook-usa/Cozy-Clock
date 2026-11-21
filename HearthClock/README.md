# Hearth Clock

A cozy, dark-by-default clock for iPhone built on iOS 26 Liquid Glass.

## Set up in Xcode (about two minutes)

1. Xcode 26 or later: File > New > Project > iOS > App. Name it `HearthClock`, Interface: SwiftUI, Language: Swift.
2. Set the iOS Deployment Target to 26.0 (Project > HearthClock target > General).
3. Delete the generated `HearthClockApp.swift` and `ContentView.swift`.
4. Drag all `.swift` files plus `day-sky.jpg` and `night-sky.jpg` from this folder into the project navigator (tick "Copy items if needed" and the app target). Do not add this README.
5. Add the location permission text: select the HearthClock target > Info tab > Custom iOS Target Properties, hover any row and click +, choose **Privacy - Location When In Use Usage Description**, and set the value to something like `Hearth Clock uses your approximate location to match the sky to your real sunrise and sunset.`
6. Pick your iPhone or a simulator and press Run. Tap **Allow While Using App** when asked about location.

Location is only used to work out sunrise and sunset on the device, at reduced (about 1 km) accuracy, and is never sent anywhere.
If you say no, the sun and sky simply follow 7 AM to 6 PM. The photo picker runs out of process, so it needs no permission.
To try other places in the Simulator, use Features > Location.

## What's inside

- `ContentView.swift`: layout, the glass dock, the Zen toggle (top left), and the Backgrounds sheet with photo upload.
- `ClockCard.swift`: the glass clock slab, seconds bar, and the Zen breathing dot and pulsing border.
- `PuppyView.swift`: the golden retriever puppy, drawn with SwiftUI Canvas so it stays sharp at any size.
- `BackgroundView.swift`: drifting colour glow, photo backgrounds, the day and night sky photos, and the sun (up from your real sunrise to sunset). The moon is up from sunset to sunrise, drawn in its real current phase in `MoonView.swift`.
- `Solar.swift`: on-device sunrise and sunset maths, the day and night schedule (`SkyClock`), and the location helper.
- `Theme.swift`: palettes, the Zen palette, and photo storage.

Everything is stored on the device. Tapping Zen fades the dock away, switches to a sage and sand palette,
slows the background, and shows the puppy napping on the clock's border while a dot guides a 4-second
in, 4-second out breath.
