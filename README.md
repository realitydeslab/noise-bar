# NoiseBar

Minimal ambient-sound + Pomodoro app for macOS (menu bar) and iOS (app + Home Screen widget).

Sounds and icons originally from the [Noisekun](https://github.com/mateusfg7/Noisekun) project.

## Build

Requires Xcode 15+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
xcodegen
open NoiseBar.xcodeproj
```

Three targets:

- **NoiseBar-macOS** — menu bar app (no dock icon, `LSUIElement`). Uses `MenuBarExtra`. macOS 14+.
- **NoiseBar-iOS** — iOS app with sound grid and Pomodoro sheet. iOS 17+. Requires background audio entitlement.
- **NoiseBarWidget** — Home Screen widget extension (bundled with the iOS app).

Shared code lives in `Shared/`. Audio (`.m4a`) and icons (`.png`) are in `Shared/Resources/`.

## Features

- 18 looping ambient sounds (rain, fire, brown noise, …)
- Pomodoro timer with configurable work/break sounds and durations (1, 2, 5, 10, 15, 25 min)
- Loop toggle for indefinite cycling
- MM:SS countdown in the macOS menu bar
- Launch at login on macOS (via `SMAppService`)
- Home Screen widget showing currently playing sound or Pomodoro phase
