# Nirapod Flutter

Android taxpayer client for the Nirapod Spring Boot API.

| Android flavor | Backend | Run |
| --- | --- | --- |
| `live` (default) | Render demo | `flutter run --flavor live` |
| `local` | Spring Boot on the emulator host, port 8080 | `flutter run --flavor local` |

For a physical phone, start the backend on your PC, connect both devices to the same LAN and use the PC's address. Replace the example address in the following command.

```sh
flutter run --flavor local --dart-define=LOCAL_API_ORIGIN=http://192.168.1.20:8080
```

The two variants have separate application IDs and session storage. Sign in with a taxpayer account from the selected backend. The demo buttons fill the email field. Enter the password configured for that backend.

Run `flutter test` for the app and API regression tests. Build an installable preview with `flutter build apk --debug --flavor live` or `flutter build apk --debug --flavor local`.

For a signed release, configure `ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` and `ANDROID_KEY_PASSWORD` in your build environment and run `flutter build appbundle --release --flavor live`.
