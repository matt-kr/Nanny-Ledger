# Nanny Ledger

> One-tap nightly logging for night nanny shifts with instant Week-to-Date payment notes.

## Overview

**Nanny Ledger** is an iOS app designed to simplify tracking night nanny hours and generating payment notes. Built for busy parents who need a quick, reliable way to log shifts and calculate weekly payments.

## Key Features

### ✨ Core Features (MVP)
- **One-Tap Logging**: "Log Tonight" button creates a shift for today with smart defaults
- **Smart Defaults**: Different default hours per weekday (e.g., Friday 21:00–07:00, others 22:00–08:00)
- **Week-to-Date Notes**: Automatic note generation with date compression
  - Example: `Night nanny dates: Oct 5–9, 11 (22:00–08:00) — 5 nights, ~40.00h, $1,400.00`
- **Flexible Management**: Add, edit, or delete shifts with custom times
- **Auto-Calculations**: Overnight duration handling, quarter-hour rounding
- **Easy Sharing**: Copy to clipboard or share via Messages/Email

### 🎯 Smart Features
- **Date Compression**: Consecutive dates shown as ranges (Oct 5–9 instead of Oct 5, 6, 7, 8, 9)
- **Uniform Hours Detection**: Automatically appends time range when all shifts match
- **Configurable Week Start**: Choose Sunday or Monday as week start
- **Custom Rate**: Set hourly rate (default $35/hour)

## Tech Stack

- **iOS 18+** (SwiftUI, SwiftData)
- **Architecture**: MVVM with services layer
- **Storage**: Local-first with SwiftData
- **Future**: CloudKit sync & sharing for household collaboration

## Project Structure

```
Nanny Ledger/
├── Models/
│   ├── Shift.swift              # SwiftData model for shifts
│   └── AppSettings.swift        # User settings and defaults
├── Views/
│   ├── HomeView.swift          # Main screen with prominent "Log Tonight"
│   ├── ShiftRowView.swift      # Individual shift display
│   ├── AddShiftView.swift      # Manual shift entry
│   └── SettingsView.swift      # App configuration
├── Services/
│   ├── DateCompression.swift   # Date range compression logic
│   └── NoteGenerator.swift     # WTD note formatting
├── Extensions/
│   └── Date+Extensions.swift   # Date utilities
└── NannyLedgerApp.swift        # App entry point
```

## Usage

### Quick Log
1. Tap **"Log Tonight"** to record tonight's shift with default hours
2. Or tap **"Log Last Night"** if you forgot yesterday

### Custom Entry
1. Tap **"Add Specific Night"**
2. Select date and customize start/end times
3. Tap **"Add"**

### Generate Payment Note
1. View Week-to-Date summary at top of screen
2. Tap **"Copy Week"** to copy note to clipboard
3. Or tap **"Share Week"** to send via Messages/Email
4. Paste into payment app (Venmo, Zelle, etc.)

### Settings
- Adjust hourly rate
- Set default hours per weekday
- Choose week start day (Sunday/Monday)
- Toggle totals in notes

## Development

### Requirements
- Xcode 15+
- iOS 18.0+ deployment target
- Swift 5.9+

### Build & Run
1. Open `Nanny Ledger.xcodeproj`
2. Select target device/simulator (iOS 18+)
3. Build and run (⌘R)

### Testing
- Run unit tests: ⌘U
- UI tests available in `Nanny LedgerUITests/`

## Roadmap

### Post-MVP Features
- [ ] **CloudKit Sync**: Household sharing for multiple devices
- [ ] **Apple Watch App**: Quick log from wrist, WTD complications
- [ ] **Widgets**: Home screen quick logging
- [ ] **Siri Shortcuts**: "Hey Siri, log tonight"
- [ ] **Export Options**: CSV/PDF for tax records
- [ ] **Nightly Rate Mode**: Flat rate per shift option

## Architecture Decisions

- **Date Storage**: Dates stored as start-of-day for the evening shift began
- **Overnight Calculation**: Automatically handles shifts that cross midnight
- **Hour Precision**: Rounded to nearest 0.25h (15 min) for standard billing
- **Week Start**: Configurable (Sunday default for weekly payroll)

## Contributing

This is a personal project, but suggestions and feedback are welcome! Open an issue or submit a PR.

## License

All rights reserved. Personal use project.

---

**Built with ❤️ for busy parents everywhere**
