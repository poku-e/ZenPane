# Zenpane

Zenpane is a macOS personal dashboard built with SwiftUI. It combines task planning, weather, notes, and motivational context into a single glassmorphic workspace designed for day-to-day personal use.

The app is intentionally lightweight: one primary dashboard window, local persistence through `UserDefaults`/`AppStorage`, and a compact native macOS surface that can stay open throughout the day. It is structured as a personal command center rather than a traditional multi-window productivity suite.

## Overview

Zenpane is designed around one idea: reduce friction between planning and execution. Instead of switching between separate apps for todos, notes, weather, and reminders, the dashboard keeps the most useful daily context visible at once.

Core goals:

- Provide a fast, always-available desktop dashboard for daily planning
- Keep the UI visually calm with a glassmorphic macOS presentation
- Persist personal data locally without requiring account setup
- Surface useful context like weather and motivation without overcomplicating the app
- Sync created tasks into Apple Reminders so the dashboard can coexist with native Apple workflows

## Current Feature Set

### Dashboard Workspace

The main window is a resizable, rounded glass panel.

- Responsive multi-column dashboard layout
- Scrollable content area when the window is smaller than the ideal layout
- Hidden system scroll indicators for a cleaner presentation
- Personalized greeting based on time of day and configured display name
- “Today” strip that highlights focus items, overdue work, and quick actions
- Summary metric cards for active queue, upcoming work, completed items, and saved quotes
- Header settings button that opens the Settings window directly
- Menu bar status item for quick dashboard access

### Todo Planning

Zenpane’s todo system is the primary planning surface.

- Create tasks with title, priority, optional due date, and automatic pinning for high-priority items
- Edit tasks inline
- Mark tasks complete/incomplete
- Delete tasks
- Clear all completed tasks
- Filter tasks by `Today`, `Upcoming`, and `Completed`
- Sort by pinned state, priority, due date, and creation time
- Surface top focus tasks in the “Today” strip
- Persist tasks locally

### Apple Reminders Integration

Todos can mirror into the native Apple Reminders app through `EventKit`.

- Creating a Zenpane task creates a Reminder
- Editing a task updates its Reminder
- Completing a task marks the Reminder complete
- Deleting a task removes the Reminder
- Clearing completed tasks removes any linked completed reminders
- Existing todo items keep a stored reminder identifier so sync updates the same Reminder instead of duplicating

If Reminders access is denied or unavailable, todos still work locally and the app continues without failing.

### Notes

The notes column is split into two sections for different use cases.

- Pinned notes for stable information you want to keep visible
- Scratchpad for temporary notes and quick thinking
- Local persistence through `AppStorage`
- Simple “last saved” status feedback based on recent edits

### Motivation

The quote panel provides lightweight contextual motivation.

- Pulls quotes from `zenquotes.io`
- Falls back to local quote themes when the network request fails
- Supports quote theme preferences (`Focus`, `Calm`, `Momentum`)
- Save quotes into a local personal quote library
- Keyboard shortcut support for refresh/save actions

### Weather

The weather panel provides current conditions and short-range forecast context.

- Fetches data from the US National Weather Service (`weather.gov`)
- Uses stored city/latitude/longitude in app settings
- Shows current condition headline
- Shows secondary forecast context
- Shows a short multi-period forecast
- Handles common network and unsupported-location failure states gracefully

### Preferences

The app includes a macOS Settings scene for lightweight customization.

- Set display name for personalized greeting
- Choose appearance mode (`System`, `Light`, `Dark`)
- Set preferred quote theme
- Use current macOS location to populate weather city and coordinates automatically
- Review current resolved weather city and coordinates

## Technology Stack

- Language: Swift
- UI: SwiftUI
- Platform: macOS
- Native frameworks:
  - `SwiftUI`
  - `AppKit`
  - `EventKit`
  - `CoreLocation`
  - `Combine`
- Persistence:
  - `UserDefaults`
  - `@AppStorage`

## Project Structure

High-level file responsibilities:

- `Zenpane/Zenpane/ZenpaneApp.swift`
  - App entry point and Settings scene
- `Zenpane/Zenpane/AppDelegate.swift`
  - App lifecycle, dashboard window launch, menu bar item
- `Zenpane/Zenpane/DashboardWindow.swift`
  - Custom `NSWindow` configuration and visibility toggling
- `Zenpane/Zenpane/DashboardView.swift`
  - Main dashboard composition and responsive layout logic
- `Zenpane/Zenpane/DashboardViewModel.swift`
  - Core application state, networking, persistence, and Reminders sync
- `Zenpane/Zenpane/TodoListView.swift`
  - Task planning UI
- `Zenpane/Zenpane/NotesView.swift`
  - Notes UI
- `Zenpane/Zenpane/QuoteCardView.swift`
  - Quote panel UI
- `Zenpane/Zenpane/WeatherCardView.swift`
  - Weather panel UI
- `Zenpane/Zenpane/PreferencesView.swift`
  - Settings UI
- `Zenpane/Zenpane/AppSettings.swift`
  - Shared app-level settings wrapper
- `Zenpane/Zenpane/VisualEffectBlur.swift`
  - AppKit-backed blur view bridge for the glassmorphic effect

## Architecture Notes

Zenpane uses a straightforward local-state architecture.

- `DashboardViewModel` is the central state container for the dashboard
- `@Published` properties drive the SwiftUI dashboard views
- Todo, weather, and quote state all flow from the view model
- Small settings are stored in `AppSettings` using `@AppStorage`
- View structs are mostly presentation-focused, with lightweight UI-only state

This keeps the app easy to modify without introducing a heavier architecture prematurely.

## Data Persistence

Zenpane stores user data locally on the machine.

Persisted items include:

- Todos
- Saved quotes
- Pinned notes
- Scratchpad notes
- Display name
- Weather preferences
- Preferred quote theme
- Preferred appearance mode

Storage is currently implemented through `UserDefaults` and `AppStorage`, which keeps the app simple but also means:

- Data is local to the current user/account on the current Mac
- There is no cloud sync built into Zenpane itself
- There is no explicit export/import flow yet

## Permissions

Zenpane currently uses two system permission domains.

### Apple Reminders Permissions

Zenpane requires permission to access Reminders if you want todo synchronization.

Required configuration:

- `NSRemindersUsageDescription` is included in `Info.plist`
- `NSRemindersFullAccessUsageDescription` is included in `Info.plist`
- `NSRemindersWriteOnlyAccessUsageDescription` is included in `Info.plist`
- On first access, macOS should prompt for Reminders permission
- The app requests full access because it needs to create, update, complete, and delete the same reminder records later

Important runtime note:

- If the app target is sandboxed, you may also need to enable the Reminders entitlement in Xcode under Signing & Capabilities (`Personal Information > Reminders`)

Without that entitlement, Reminders access can still fail even if the usage description exists.

### Location Permissions

Zenpane can use macOS Location Services to configure weather automatically.

Required configuration:

- `NSLocationUsageDescription` is included in `Info.plist`
- The user must allow location access when prompted

Behavior:

- The app requests the current location
- It reverse-geocodes that location into a city name
- It saves the resulting city, latitude, and longitude into app settings for weather lookups

## External Services

Zenpane currently uses two external data sources.

### ZenQuotes

- Endpoint: `https://zenquotes.io/api/random`
- Purpose: motivational quote retrieval
- Behavior: falls back to local quotes if unavailable

### Weather.gov

- Endpoint family: `https://api.weather.gov/...`
- Purpose: current and short-term forecast data
- Constraint: intended for US locations
- Behavior: uses the saved latitude/longitude to resolve forecast endpoints

## Running the App

### Requirements

- macOS
- Xcode with SwiftUI/macOS development support

### Open in Xcode

1. Open the project/workspace in Xcode.
2. Select the Zenpane target/scheme.
3. Build and run on macOS.

### First Launch Expectations

On first launch, you should expect:

- The dashboard window to open centered on screen
- A menu bar item labeled `Zenpane`
- Weather and quote data to begin loading automatically
- A Reminders permission request if a task is created and Reminders access has not yet been granted
- A Location Services permission request if the user chooses `Use Current Location` in Settings

## How Todo/Reminder Sync Works

The todo system stores a local `reminderIdentifier` for each task.

Behavior summary:

1. A new todo is created locally.
2. Zenpane requests Reminders access if needed.
3. A corresponding `EKReminder` is created or updated.
4. The reminder’s identifier is stored on the todo.
5. Future edits update the same reminder record.
6. Completing or deleting the todo updates or removes that reminder.

Design choice:

- The app does not currently import existing Apple Reminders into Zenpane.
- Sync is one-way from Zenpane to Apple Reminders.

## Keyboard Shortcuts

Current shortcuts implemented in the UI:

- `Command-Return`
  - Add a new todo from quick capture
- `Shift-Command-K`
  - Clear completed tasks
- `Command-D`
  - Save the current quote
- `Command-R`
  - Refresh the current quote
- `Shift-Command-R`
  - Refresh dashboard data from the quick actions card

Note: overlapping shortcuts may conflict depending on focus and responder chain. If shortcut behavior needs to be hardened, the commands layer should be centralized later.

## Design Direction

Zenpane intentionally uses a macOS glassmorphic style rather than a dense utility UI.

Design characteristics:

- Rounded resizable window
- Native visual effect blur
- Layered material cards
- Persistent overview layout
- Strong emphasis on ambient daily context

This makes the app feel closer to a personal desktop console than a traditional list manager.

## Known Limitations

Current limitations worth noting:

- No import from Apple Reminders back into Zenpane
- No calendar integration yet
- No iCloud or multi-device sync for local data
- Weather is geared toward US locations through Weather.gov
- Persistence is simple and local, not database-backed
- The dashboard uses scrolling for smaller window sizes instead of a full breakpoint-driven layout collapse
- Shortcut handling is view-local rather than globally coordinated
- The app currently relies on macOS Settings/entitlement configuration for Reminders to work reliably during development

## Future Improvement Ideas

Natural next steps for the app:

- Two-column/one-column responsive breakpoints instead of relying on horizontal scroll
- Calendar integration for a real agenda strip
- Better reminder/calendar selection instead of always using the default reminders list
- Import and reconciliation from Apple Reminders
- Search across tasks and notes
- Rich text or structured notes
- Data export/import
- Better analytics for completed work and planning trends
- Tests around `DashboardViewModel` persistence and Reminders sync

## Development Notes

If you modify the todo model in the future, keep backward compatibility in mind. The app already supports decoding older persisted todo data by defaulting missing fields, which helps avoid breaking existing local data.

For Reminders integration specifically:

- Be conservative with permission failures
- Never block local todo creation on EventKit access
- Persist reminder identifiers so updates remain idempotent
- Expect sandbox and entitlement issues during local development
- Keep the full-access Reminders usage description aligned with the EventKit API being requested

For location integration:

- Keep Core Location requests user-initiated where possible
- Treat reverse geocoding failures as non-fatal and retain the coordinates
- Preserve the stored city/coordinates so weather can keep working after the initial location lookup

## License / Ownership

No license file is currently included in this repository. If this project will be shared or distributed, add an explicit license and ownership terms.
