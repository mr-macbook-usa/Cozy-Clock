# Cozy Clock

A cozy, dark-by-default clock with a drifting glow, a real-phase moon with today's phase shown under the date, day and night skies that follow your real sunrise and sunset, custom photo backgrounds, and a Zen breathing mode.

## Use it in your browser

**👉 [Open Hearth Clock](https://mr-macbook-usa.github.io/Cozy-Clock/)**

This link always opens the [latest release](https://github.com/mr-macbook-usa/Cozy-Clock/releases/latest). Publishing a new release updates it automatically.

Works on any phone, tablet, or computer. No install or sign-up. Your settings and any photo you add stay in your own browser.

Allow location when asked and the sun, moon, and day/night sky follow your real sunrise and sunset. Your location is only used on your device to work out those times; without it, the sky follows 7 AM to 6 PM.

Tip: on iPhone, tap Share → **Add to Home Screen** to use it like an app.

## What's in this repo

- `docs/index.html`: the web version (a single self-contained page). `.github/workflows/pages.yml` publishes it to GitHub Pages whenever a release is published.
- `HearthClock/`: the native iPhone app in SwiftUI (iOS 26). See [`HearthClock/README.md`](HearthClock/README.md) for Xcode setup.
