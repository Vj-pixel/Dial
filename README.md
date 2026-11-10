# Dial

A fast, lightweight radial app launcher and switcher for macOS 14+. Replaces the Dock and Cmd-Tab with a wheel menu that appears at your cursor.

## Features

- **Radial wheel** – borderless transparent overlay, smooth spring animations, vibrancy background
- **Two modes** – Pinned Apps (fixed list) or Running Apps (live Cmd-Tab replacement)
- **Instant selection** – move the mouse toward a slice, or press the number key badge shown on each icon
- **Global hotkey** – default ⌥⌘, fully configurable via Settings › Shortcut
- **Launch or switch** – brings running apps forward; launches apps that aren't open
- **Files & folders** – add any file or folder as a pinned slice
- **Menu bar icon** – quick access to Settings and Quit
- **Launch at Login** – via SMAppService
- **Light & Dark mode** – SF Symbols, vibrancy, native macOS look

## Requirements

- macOS 14 Sonoma or later
- Apple Silicon or Intel Mac
- Xcode 15+

## Build

```bash
# Install xcodegen if not already present
brew install xcodegen

# Generate the Xcode project (only needed after editing project.yml)
xcodegen generate

# Open in Xcode
open Dial.xcodeproj

# Or build from the command line
xcodebuild -project Dial.xcodeproj -scheme Dial -configuration Release build
```

The built app is in `~/Library/Developer/Xcode/DerivedData/Dial-*/Build/Products/Release/Dial.app`.

## Permissions

### Accessibility (required)

Dial uses a `CGEventTap` to listen for the global modifier-key hotkey. This requires Accessibility permission.

On first launch, if the permission is not granted, an onboarding screen opens with a direct link to **System Settings › Privacy & Security › Accessibility**. Toggle Dial on there, then relaunch.

### App Sandbox

Dial runs **without** the App Sandbox so it can observe system-wide key events and launch arbitrary apps. This is intentional and standard for utility apps of this kind.

## Architecture

| File | Role |
|------|------|
| `App/AppDelegate.swift` | App entry point, wires everything together |
| `HotkeyManager/HotkeyManager.swift` | `CGEventTap`-based global shortcut; fires `onTrigger`/`onRelease` |
| `RadialMenu/RadialMenuWindow.swift` | Full-screen `NSPanel` host for the wheel overlay |
| `RadialMenu/RadialMenuView.swift` | SwiftUI wheel, slice hit-testing, keyboard handling |
| `AppProvider/AppProvider.swift` | Supplies pinned + running `AppEntry` items; handles launch/switch |
| `Settings/SettingsStore.swift` | `UserDefaults`-backed `ObservableObject` for all prefs |
| `Settings/SettingsView.swift` | Tabbed SwiftUI settings window (General, Apps, Shortcut) |
| `Settings/AccessibilityOnboarding.swift` | First-launch Accessibility prompt |
| `MenuBar/MenuBarController.swift` | Menu bar status item |

## Usage

1. Launch Dial – it lives in the menu bar (dial icon).
2. Grant Accessibility permission when prompted.
3. Hold **⌥⌘** (Option+Command) – the wheel appears at the cursor.
4. Move toward a slice, or press its number key, to select.
5. Release the hotkey (or click) to launch/switch. Press **Escape** to dismiss.
6. Open **Settings** from the menu bar icon to add pinned apps, change the wheel size, or rebind the hotkey.

## Customising the Hotkey

Open Settings › Shortcut, click **Record**, and hold any modifier combination (⌃, ⌥, ⇧, ⌘ or combinations). Single-key shortcuts are intentionally not supported to avoid conflicts with other apps.
