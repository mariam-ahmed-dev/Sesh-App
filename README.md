# SESH

SESH turns today's Ancient Egypt news into stories, context and journeys through time. **FOLLOW THE STORY.**

## Features

- onboarding with persistent completion
- responsive editorial home, discovery, map, Ask the Scribe and saved discoveries
- NewsAPI integration with deterministic offline archive fallback
- bookmark persistence, dark mode (`NIGHT ON THE NILE`) and English/Arabic locale switching
- original SESH glyph and local SVG placeholders

## Stack and architecture

Flutter, Dart, Material 3, flutter_bloc/Cubit, HTTP, SharedPreferences, url_launcher and webview_flutter. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Setup

```powershell
flutter pub get
flutter run --dart-define=NEWS_API_KEY=YOUR_KEY
```

Without a key the app uses local mock stories, so the product remains demonstrable offline. Never commit a real key; `.env.example` shows the variable name.

## Localization and themes

English and Arabic resources live in `l10n/`. The language action switches locale and direction. Light mode is Sunlit Limestone; dark mode is Night on the Nile with Ancient Egyptian Blue as the primary interactive color.

## Testing

Run `flutter analyze` and `flutter test`. The current vertical slice is intentionally dependency-light and uses mock data without requiring a network.

## Current limitations / environment notes

The map is a local discovery surface rather than a paid map SDK, Ask the Scribe is a deterministic local provider, and full generated `gen_l10n` wiring plus platform-specific WebView routing can be expanded as the historical dataset grows.

The Android debug build requires a working Android SDK and several hundred MB of free disk space for Gradle and Kotlin dependencies. In the implementation environment, `flutter analyze` and `flutter test` pass, but `flutter build apk --debug` could not finish because the system drive was full while those dependencies were being downloaded.
