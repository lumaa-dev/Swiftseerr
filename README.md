# [Swiftseerr](https://apps.lumaa.fr/app/swiftseerr)

A native SwiftUI client for [Seerr](https://seerr.dev), for iOS, tvOS, and macOS.

> [!NOTE] 
> This project is no longer maintained and has been archived.

## What it does

Swiftseerr connects to your own Seerr instance (self-hosted request managers that sit in front of Plex/Jellyfin/Emby libraries) and lets you browse, search, and request media from a native app instead of the web UI.

During onboarding, the app:
1. Asks for your instance's server URL and checks that it responds like a valid Seerr install.
2. Asks you to pick a sign-in provider (Jellyfin account or local Seerr account).
3. Logs in with your username and password.

Once signed in, the app lets you:
- Discover and search movies/TV shows available through your instance
- View media details, seasons/episodes, and cast/crew (person pages)
- Submit and track requests
- View your watchlist
- Manage multiple accounts/instances at once, each stored locally via SwiftData (`AuthInfo`), with one marked as default
- Switch the app icon between Jellyseerr, Overseerr, and "OverJelly" variants (iOS only)

The app runs natively on iPhone/iPad (`Swiftseerr` target), Apple TV (`SwiftseerrTV` target), and Mac (via the same iOS target, Catalyst-style window sizing).

## About [SeerrAPN](https://apps.lumaa.fr/app/swiftseerr#apn)

SeerrAPN exists in two parts:

1. **In this repo** — a Notification Service Extension (`SeerrAPN/`) embedded in the app. It intercepts incoming push notifications and downloads/attaches the poster image before the notification is displayed, so request/availability alerts show artwork.
2. **A separate backend** — [lumaa-dev/SeerrAPN](https://github.com/lumaa-dev/SeerrAPN), a standalone relay server. Swiftseerr's notification settings screen registers the device's push token and notification-type filters (pending, approved, auto-approved, denied, available) with that server, which is what actually triggers APNs pushes on behalf of your Seerr instance. *This companion project is also being archived*.

Push notifications will not work without pointing the app at a running instance of that backend.

## Tech stack

- SwiftUI for all UI
- SwiftData for on-device persistence of accounts (`AuthInfo`)
- `URLSession` for all networking against the Seerr REST API and the SeerrAPN backend
- Target deployment: iOS/tvOS/macOS 26.0, Swift 5.0

## Project structure

```
Swiftseerr.xcodeproj/   # Xcode project
Swiftseerr/             # iOS/macOS app target (Views, AppDelegate, app entry point)
SwiftseerrTV/           # tvOS app target
SeerrAPN/               # Notification Service Extension target
Shared/                 # Code shared across targets: endpoints, data models, shared views/components
```

Notable files:
- `Shared/Endpoints/` — one file per Seerr API area (Auth, Discover, Media, Person, Requests, Search, Watchlist)
- `Shared/Data/SeerSession.swift` — current session/auth state
- `Shared/Data/AuthInfo.swift` — stored account model (username, password, address, provider, default flag)
- `Swiftseerr/Data/DeeplinkManager.swift` / `Navigator.swift` — deep linking and tab navigation
- `SeerrAPN/NotificationService.swift` — the notification extension described above

## License

Licensed under Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0). See [LICENSE](LICENSE).
