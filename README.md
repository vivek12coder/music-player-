# PulsePlay (music_player)

Android-first Flutter music player with smart shuffle, background playback, and local library management.

## Features

- Local music library browsing using `on_audio_query`
- Background playback and media controls with `audio_service`
- Audio engine powered by `just_audio`
- Smart shuffle and recommendation-focused modules
- Playlist management and persistent local storage with `hive_ce`
- App architecture based on Riverpod + GoRouter

## Tech Stack

- Flutter (Dart SDK `>=3.4.0 <4.0.0`)
- State management: `flutter_riverpod`
- Navigation: `go_router`
- Audio: `just_audio`, `audio_service`, `audio_session`
- Storage: `hive_ce`, `hive_ce_flutter`
- Permissions: `permission_handler`

## Project Structure

```text
lib/
	app/
		app.dart
		bootstrap.dart
		router/
		theme/
	core/
		constants/
		contracts/
		logging/
		models/
		providers/
		services/
		utils/
		widgets/
	features/
		home/
		library/
		player/
		playlists/
		recommendations/
		settings/
```

## Prerequisites

- Flutter SDK installed and available in `PATH`
- Android SDK + emulator/device (primary target)
- JDK compatible with your Flutter/Android toolchain

Check your environment:

```bash
flutter doctor
```

## Getting Started

1. Install dependencies:

```bash
flutter pub get
```

2. Run the app:

```bash
flutter run
```

## Testing

Run all tests:

```bash
flutter test
```

Integration tests (if configured device/emulator is available):

```bash
flutter test integration_test
```

## Build

Debug APK:

```bash
flutter build apk --debug
```

Release APK:

```bash
flutter build apk --release
```

## Permissions

This app queries and plays local audio files. Ensure storage/media permissions are correctly handled for your Android API level.

## Notes

- `.gitignore` is configured to exclude Flutter, build, and platform-generated files.
- iOS folders exist, but the project is currently Android-first by design.