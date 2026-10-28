# Skycom Android

Hybrid Android app for Skycom, built with [Hotwire Native Android](https://native.hotwired.dev/android/getting-started).

## What it is

This is a **Hotwire Native shell**, not a native rewrite. It opens the existing
Rails mobile pages in a WebView and adds the native bottom tabs, per-tab back
stacks, pull-to-refresh, and an error/retry screen.

Tenant pages are scoped to `/mobile/companies/:company_id/*`. The app has two
activities:

- `SignInActivity` — launcher, no tabs; loads `/mobile/sign_in`, stores the
  company id from the post-login redirect, then starts `MainActivity`.
- `MainActivity` — authenticated shell; builds the five tabs from the stored
  company id.

- **Deep architecture and onboarding doc:** [`docs/HOW_IT_WORKS.md`](docs/HOW_IT_WORKS.md)
- Native entry point: `app/src/main/java/com/example/skycomandroid/SignInActivity.kt`
- Authenticated shell: `app/src/main/java/com/example/skycomandroid/MainActivity.kt`
- Startup and path configuration: `app/src/main/java/com/example/skycomandroid/SkycomApplication.kt`
- Tabs: five `HotwireBottomTab`s in `MainActivity.buildTabs()`

## Requirements

- Android Studio (bundled JBR works) or JDK 17+
- Android SDK platform 35
- Rails dev server running from the repository root (`bin/dev`)

## Configuration

| Setting | Default | Override |
|---|---|---|
| Base URL | `http://10.88.0.2:3000` | `-PskycomBaseUrl=http://10.0.2.2:3000` |
| Sign-in location | `${BASE_URL}/mobile/sign_in` | `SignInActivity.navigatorConfigurations()` |
| Stored company id | `SharedPreferences` key `company_id` | cleared on sign-out / auth loss |
| Path configuration | bundled `assets/json/path-configuration.json` + `${BASE_URL}/configurations/android_v1.json` | see `SkycomApplication.kt` |

Plain HTTP is allowed in **debug builds only** (`app/src/debug/AndroidManifest.xml`). Release builds require HTTPS.

## Run

From Android Studio, open the `android/` directory and run the `app` configuration.

> **Build ≠ install.** `assembleDebug` only compiles the APK; it does not install
> or launch it. Use Android Studio's **Run** button (or `adb install`) to put it
> on a device. After installing, find **Skycom** in the app drawer (new apps are
> not automatically added to the home screen).

Or from the command line:

```bash
# Build
JAVA_HOME=/path/to/android-studio/jbr ./gradlew :app:assembleDebug

# Install (emulator/device must be running)
adb install -r app/build/outputs/apk/debug/app-debug.apk
adb shell am start -n com.example.skycomandroid/.SignInActivity
```

To point the app at a different host without editing Kotlin:

```bash
./gradlew :app:assembleDebug -PskycomBaseUrl=http://10.0.2.2:3000
```

## Emulator networking

The default host is the dev machine's LAN address (`10.88.0.2:3000`), so it also works from a physical device on the same network.

If the emulator cannot reach that address, forward the Rails port and rebuild against loopback:

```bash
adb reverse tcp:3000 tcp:3000
./gradlew :app:assembleDebug -PskycomBaseUrl=http://127.0.0.1:3000
```

## Tabs

The bottom navigation mirrors the mobile web surface. Roots are built from the
stored company id; the tab bar is hidden on sign-in.

| Tab | Web path |
|---|---|
| Home | `/mobile/companies/<company_id>/home` |
| Employee | `/mobile/companies/<company_id>/employee` |
| Attendance | `/mobile/companies/<company_id>/attendance_month` |
| Payroll | `/mobile/companies/<company_id>/payroll` |
| Requests | `/mobile/companies/<company_id>/attendance_requests/new` |

Each tab owns a `NavigatorHost` and keeps its own back stack. Tabs are loaded lazily on first selection.

## Troubleshooting

See [`docs/HOW_IT_WORKS.md` §12](docs/HOW_IT_WORKS.md#12-troubleshooting) for the
issues hit during development: emulator offline/unauthorized, the hidden emulator
window (`-qt-hide-window`), 406 on an old WebView, blank page/server unreachable,
stale path configuration, the OkHttp OSGI manifest, Kotlin metadata, and
cleartext HTTP.

Quick checks:

```bash
# A device must be authorized and online
adb devices

# Signed-out mobile home must redirect to mobile sign-in
curl -I http://10.88.0.2:3000/mobile/home

# Signed-in tenant page requires a real company uuid; expect 302 to sign-in when signed out
curl -I http://10.88.0.2:3000/mobile/companies/00000000-0000-0000-0000-000000000000/home

# Path configuration must be reachable
curl http://10.88.0.2:3000/configurations/android_v1.json
```
