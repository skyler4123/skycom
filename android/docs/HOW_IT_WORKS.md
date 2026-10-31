# How the Skycom Android app works

> **Audience:** a developer who knows Rails but has never used Hotwire Native
> or Android. Read this before changing anything under `android/`.
>
> **Status:** development shell for the existing mobile web surface. Two
> activities: an unauthenticated sign-in gate and an authenticated five-tab
> shell. All tenant pages are company-scoped.

---

## 0. TL;DR

- `android/` is a **native Android shell** built with **Hotwire Native Android 1.3.2**.
- It does **not** reimplement the UI natively. It opens the existing Rails
  mobile pages (`/mobile/*`) in a WebView.
- Native parts: the bottom tab bar, one navigation stack per tab, the system
  back button, pull-to-refresh, the error/retry screen, and the WebView version
  check.
- Web parts: sign-in, home, employee info, attendance month, payroll, and the
  attendance-request form — all rendered by Rails + Turbo.
- Start URL: `${BASE_URL}/mobile/sign_in`, default
  `http://10.88.0.2:3000/mobile/sign_in`.
- Signed-out visitors stay in `SignInActivity`, which has **no bottom tabs**.
- After sign-in, Rails redirects to
  `/mobile/companies/<company_id>/home`; the app stores that id and starts
  `MainActivity`, which builds company-scoped tab roots.
- Build with `./gradlew :app:assembleDebug`. **Build ≠ install**: use Android
  Studio's **Run** button (or `adb install`) to put it on a device.

---

## Contents

- [0. TL;DR](#0-tldr)
- [1. Mental model](#1-mental-model)
- [2. Stack and versions](#2-stack-and-versions)
- [3. File map](#3-file-map)
- [4. Startup sequence](#4-startup-sequence)
- [5. The five tabs](#5-the-five-tabs)
- [6. Path configuration](#6-path-configuration)
- [7. Networking](#7-networking)
- [8. Authentication and cookies](#8-authentication-and-cookies)
- [9. Navigation lifecycle](#9-navigation-lifecycle)
- [10. Debugging](#10-debugging)
- [11. Build and run](#11-build-and-run)
- [12. Troubleshooting](#12-troubleshooting)
- [13. How to extend the app](#13-how-to-extend-the-app)
- [14. Limitations and next steps](#14-limitations-and-next-steps)
- [15. Decision log](#15-decision-log)
- [16. Glossary](#16-glossary)
- [17. Verification checklist](#17-verification-checklist)

---

## 1. Mental model

This app is a **WebView with a native navigation skeleton**. The HTML, CSS,
forms, authentication, and business data all still come from Rails. Hotwire
Native adds:

1. a native tab bar,
2. a native back stack per tab,
3. native pull-to-refresh,
4. a native error/retry screen,
5. a WebView version check.

```
┌──────────────────────────── Android app ─────────────────────────────┐
│ SignInActivity : HotwireActivity     (no bottom navigation)          │
│   └─ NavigatorHost "sign_in" → WebView → /mobile/sign_in             │
│        └─ on company redirect: persist company id → start MainActivity│
│                                                                      │
│ MainActivity : HotwireActivity                                       │
│   ├─ NavigatorHost "home"        → /mobile/companies/<id>/home       │
│   ├─ NavigatorHost "notifications" → /mobile/companies/<id>/notifications
│   ├─ NavigatorHost "employee"    → /mobile/companies/<id>/employee   │
│   ├─ NavigatorHost "attendance"  → /mobile/companies/<id>/attendance_month
│   ├─ NavigatorHost "operations"  → /mobile/companies/<id>/operations │
│   └─ BottomNavigationView (Hidden until a company page loads)        │
│                                                                      │
│ SkycomApplication                                                    │
│   ├─ SkycomWebFragment (reports final WebView URL/errors)            │
│   └─ Hotwire.loadPathConfiguration(asset + remote JSON)              │
└──────────────────────────────────────────────────────────────────────┘
                                   │ HTTP
                                   ▼
┌──────────────────────────── Rails app ───────────────────────────────┐
│ /mobile/sign_in, /mobile/companies/:company_id/...                   │
│ Mobile::Companies::BaseController → layout "mobile" → ERB + Turbo    │
│ /configurations/android_v1.json (static path configuration)          │
└──────────────────────────────────────────────────────────────────────┘
```

### What Hotwire Native is

Hotwire Native is a framework that wraps a WebView in a native navigation
stack. It lets a server-rendered web app feel native without rewriting every
screen. It is the Android counterpart to Turbo Native/iOS.

### What it is not

- It is not a native UI toolkit.
- It is not a REST/JSON client; the server still returns HTML.
- It does not replace Rails, Turbo, or the existing mobile views.

---

## 2. Stack and versions

| Piece | Version | Why |
|---|---|---|
| Kotlin | 2.3.0 | Hotwire Native 1.3.2 is compiled with Kotlin 2.3.0 metadata. Kotlin 2.0 fails with an incompatible-metadata error. |
| Android Gradle Plugin | 8.7.3 | Already used by the generated project; supports compileSdk 35. |
| Gradle | 8.9 | Matches the wrapper and AGP. |
| Java | 17 | Required by Hotwire Native and AGP. Android Studio's bundled JBR 21 works. |
| compileSdk / targetSdk | 35 | Hotwire Native 1.3.2 is built against 35; AndroidX dependencies also expect modern SDKs. |
| minSdk | 28 | Minimum supported by Hotwire Native. |
| Hotwire Native | `dev.hotwire:core:1.3.2`, `dev.hotwire:navigation-fragments:1.3.2` | Native navigation + WebView plumbing. |
| Material Components | 1.12.0 | `BottomNavigationView`, AppCompat/Material theme. |
| ConstraintLayout | 2.2.1 | Lays out five overlapping `NavigatorHost` fragments above the tab bar. |
| Rails | 8.1.4 | Existing app. |
| Turbo | turbo-rails 2.0.23, importmap | Drives links/forms inside the WebView. |

**Why Kotlin 2.3.0 is not optional:** Kotlin embeds a metadata version in
compiled classes. A Kotlin 2.0 compiler refuses classes compiled by Kotlin 2.3
with an error like *"Class '…' was compiled with an incompatible version of
Kotlin"*. The fix is to compile the app with the same (or newer) Kotlin minor
version as the library.

---

## 3. File map

### 3.1 Gradle / project configuration

| File | Purpose |
|---|---|
| `android/settings.gradle.kts` | Plugin repositories, dependency repositories, project name, `include(":app")`. |
| `android/build.gradle.kts` | Declares the Android and Kotlin plugins for all modules (`apply false`). |
| `android/app/build.gradle.kts` | The app module: `BASE_URL`, SDK levels, Java/Kotlin target, Compose→Views switch, dependencies, OkHttp packaging exclude. |
| `android/gradle/libs.versions.toml` | Version catalog; the single place to bump Kotlin, Hotwire Native, Material, etc. |
| `android/gradle.properties` | AndroidX, non-transitive R classes, Kotlin code style, JVM args. |
| `android/gradle/wrapper/gradle-wrapper.properties` | Pins Gradle 8.9. |
| `android/local.properties` | Local SDK path (`sdk.dir`). Not committed. |

### 3.2 Manifest

| File | Purpose |
|---|---|
| `android/app/src/main/AndroidManifest.xml` | `INTERNET` permission, application class, Material theme, `SignInActivity` as the launcher, orientation/keyboard handling, predictive back. |
| `android/app/src/debug/AndroidManifest.xml` | Adds `android:usesCleartextTraffic="true"` **for debug builds only**, so the app can talk to `http://10.88.0.2:3000`. Release builds do not get this. |

### 3.3 Kotlin

| File | Purpose |
|---|---|
| `android/app/src/main/java/com/example/skycomandroid/SkycomApplication.kt` | Runs before any Activity. Enables WebView debugging in debug, sets Hotwire log level, and loads the path configuration from the bundled asset + remote URL. |
| `android/app/src/main/java/com/example/skycomandroid/SignInActivity.kt` | Unauthenticated gate. Loads `/mobile/sign_in`, has no bottom tabs, stores the company id from the post-login redirect, and starts `MainActivity`. |
| `android/app/src/main/java/com/example/skycomandroid/MainActivity.kt` | Authenticated shell. Builds five `HotwireBottomTab`s (Home, Notifications, Profile, Attendance, Operations) from the stored company id, wires the `HotwireBottomNavigationController`, clears the Profile stack when leaving the tab or backgrounding, and returns to sign-in on auth loss. |
| `android/app/src/main/java/com/example/skycomandroid/SkycomWebFragment.kt` | Custom `HotwireWebFragment` that reports the final WebView URL and HTTP errors to the active activity. |
| `android/app/src/main/java/com/example/skycomandroid/CompanyStore.kt` | `SharedPreferences` wrapper for the last company id. |
| `android/app/src/main/java/com/example/skycomandroid/CompanyUrl.kt` | Parses `/mobile/companies/<uuid>/...`, `/mobile/sign_in`, and `/mobile/home`. |
| `android/app/src/main/java/com/example/skycomandroid/MobileWebListener.kt` | URL/error callback contract shared by both activities. |
| `android/app/src/main/java/com/example/skycomandroid/MainActivityViewModel.kt` | Keeps `selectedTabIndex` across Activity recreation/process recreation. |

### 3.4 Layout and resources

| File | Purpose |
|---|---|
| `android/app/src/main/res/layout/activity_main.xml` | `ConstraintLayout` root (`@id/root`), five `FragmentContainerView`s with `android:name="dev.hotwire.navigation.navigator.NavigatorHost"`, and a `BottomNavigationView` (`@id/bottom_nav`). |
| `android/app/src/main/res/values/strings.xml` | App name (`Skycom`) and tab titles. |
| `android/app/src/main/res/values/themes.xml` | `Theme.SkycomAndroid`, parent `Theme.MaterialComponents.DayNight.NoActionBar`. Transparent system bars. |
| `android/app/src/main/res/values/colors.xml` | Skycom green (`#16A34A`), dark green, white. |
| `android/app/src/main/res/drawable/ic_tab_home.xml` | House icon. |
| `android/app/src/main/res/drawable/ic_tab_employee.xml` | Person icon. |
| `android/app/src/main/res/drawable/ic_tab_attendance.xml` | Calendar icon. |
| `android/app/src/main/res/drawable/ic_tab_operations.xml` | Grid icon. |
| `android/app/src/main/res/drawable/ic_tab_requests.xml` | Assignment icon. |

The icons are plain 24dp vector drawables. `BottomNavigationView` applies its
own tint (`itemIconTint`), so the `fillColor` inside the vector is only a base
color.

### 3.5 Assets

| File | Purpose |
|---|---|
| `android/app/src/main/assets/json/path-configuration.json` | Bundled copy of the path configuration. Loaded immediately at startup, so the app can work offline or when the server is unreachable. |

### 3.6 Rails side

| File | Purpose |
|---|---|
| `config/routes.rb` | `namespace :mobile` routes: `sign_in`, `sign_out`, the no-employee `home` fallback, and `/mobile/companies/:company_id/{home,employee,attendance_month,operations,payroll,payroll/unlock,attendances,attendance_requests}`. |
| `app/controllers/mobile/base_controller.rb` | `layout "mobile"`; **overrides `authenticate`** to redirect to `mobile_sign_in_path` instead of the marketing root. |
| `app/controllers/mobile/sessions_controller.rb` | Mobile sign-in/sign-out. Skips `authenticate` for `new`/`create`; creates a `Session`, sets cookies, and redirects to the employee's company home (or the no-employee fallback). |
| `app/controllers/mobile/home_controller.rb` | No-employee fallback; redirects employees to their company-scoped home. |
| `app/controllers/mobile/companies/base_controller.rb` | Resolves `@employee` through `current_user.employees.find_by!(company_id:)`; non-members get `404`. |
| `app/controllers/mobile/companies/*_controller.rb` | Company-scoped home, notifications, profile, attendance, operations, payroll/unlock, check-in, and request actions. |
| `app/views/layouts/mobile.html.erb` | Mobile HTML shell: viewport meta, CSRF/CSP tags, stylesheet, importmap/Turbo. |
| `app/views/mobile/**` | The HTML pages rendered inside the WebView. |
| `public/configurations/android_v1.json` | Remote path configuration served by Rails as a static file. |

### 3.7 Documentation

| File | Purpose |
|---|---|
| `android/README.md` | Quick start, host override, tab table, emulator networking. |
| `android/docs/HOW_IT_WORKS.md` | This file. |

---

## 4. Startup sequence

This is what happens from tapping the **Skycom** icon to seeing the sign-in
page or the home dashboard.

### 4.1 `SkycomApplication.onCreate()`

Runs before any Activity.

```kotlin
Hotwire.config.webViewDebuggingEnabled = BuildConfig.DEBUG
Hotwire.config.logger.logLevel =
    if (BuildConfig.DEBUG) HotwireLogLevel.DEBUG else HotwireLogLevel.NONE

Hotwire.loadPathConfiguration(
    context = this,
    location = PathConfiguration.Location(
        assetFilePath = "json/path-configuration.json",
        remoteFileUrl = "${BuildConfig.BASE_URL}/configurations/android_v1.json"
    )
)
```

What each line does:

- **WebView debugging** lets you inspect the WebView from desktop Chrome
  (`chrome://inspect`) in debug builds. It is disabled in release.
- **Log level** prints Hotwire navigation/visit logs in debug, silent in
  release.
- **Path configuration** tells Hotwire Native how to present URLs. The bundled
  asset loads immediately; the remote copy is fetched asynchronously and cached
  for the next launch. See §6.

### 4.2 `SignInActivity.onCreate()` — no tabs

The launcher is `SignInActivity`, not `MainActivity`. It loads
`${BuildConfig.BASE_URL}/mobile/sign_in` in a single full-screen `NavigatorHost`
and has no `BottomNavigationView`.

1. `enableEdgeToEdge()` lets the page draw behind the system bars.
2. `super.onCreate()` creates a `HotwireActivityDelegate` with one navigator
   configuration (`sign_in_navigator_host`).
3. If `CompanyStore` already has a company id, the activity immediately starts
   `MainActivity` and finishes. `MainActivity` validates the session by loading
   the company home; if Rails redirects to sign-in, it returns here.
4. Otherwise it inflates `activity_sign_in.xml` and the WebView loads
   `/mobile/sign_in`.
5. `SkycomWebFragment` reports the final WebView URL. When it becomes
   `/mobile/companies/<uuid>/...`, `SignInActivity`:
   - writes the company id to `SharedPreferences`;
   - starts `MainActivity` with that id;
   - finishes, so the sign-in WebView is not left underneath the tabs.

### 4.3 `MainActivity.onCreate()` — authenticated shell

`MainActivity` is only started with a stored company id.

```kotlin
companyId = intent.getStringExtra(EXTRA_COMPANY_ID) ?: CompanyStore.read(this)

enableEdgeToEdge()
super.onCreate(savedInstanceState)

setContentView(R.layout.activity_main)
findViewById<View>(R.id.root).applyDefaultImeWindowInsets()

bottomNavigationController = HotwireBottomNavigationController(
    activity = this,
    view = findViewById<BottomNavigationView>(R.id.bottom_nav),
    lazyLoadTabs = true,
    initialVisibility = HotwireBottomNavigationController.Visibility.HIDDEN
)
bottomNavigationController.view.visibility = View.GONE
bottomNavigationController.load(buildTabs(companyId), viewModel.selectedTabIndex)
```

What happens under the hood:

1. `super.onCreate()` calls `HotwireActivity.onCreate()`, which creates a
   `HotwireActivityDelegate`.
2. The delegate's initializer calls `navigatorConfigurations().first()`. The
   list is built from the stored company id.
3. `setContentView(...)` inflates the five `NavigatorHost` fragments.
4. The bottom navigation starts hidden. `SkycomWebFragment` reports a
   company-scoped URL after the first page loads, and the bar becomes visible.
5. `HotwireBottomNavigationController.load(...)` marks the hosts lazy, builds
   the menu, selects Home, and applies insets.
6. If the URL becomes `/mobile/sign_in`, `/mobile/home`, or a `404`,
   `MainActivity` clears the stored id and starts `SignInActivity` with
   `CLEAR_TASK`, so no authenticated tab stack survives sign-out.

### 4.4 Signing in

1. The user enters email/password and submits the `form_tag` to
   `/mobile/sign_in` (POST).
2. `Mobile::SessionsController#create` calls
   `User.authenticate_by(email:, password:)`.
3. On success it creates a `Session`, stores the token in a signed HttpOnly
   cookie, sets `is_signed_in` + `client_cache_version`, and redirects to the
   employee's company home, e.g. `/mobile/companies/<uuid>/home`.
4. `SkycomWebFragment` reads the final WebView URL, `SignInActivity` stores the
   company id, and `MainActivity` starts with company-scoped tabs.
5. The WebView keeps the session cookies (Android `CookieManager`); every later
   request is authenticated.

On failure it renders `:new` with HTTP 422; Turbo displays the response with
the "Invalid email or password" alert.

### 4.5 Signing out

`button_to "Sign Out", mobile_sign_out_path, method: :delete` sends a DELETE via
Turbo. `Mobile::SessionsController#destroy` destroys the session, clears
cookies, and redirects to `/mobile/sign_in`. `MainActivity` observes that URL,
clears the stored company id, and returns to `SignInActivity` with a cleared
task.

---

## 5. The five tabs

| Tab | Title string | Host ID | Start location |
|---|---|---|---|
| Home | `tab_home` | `home_navigator_host` | `/mobile/companies/<id>/home` |
| Notifications | `tab_notifications` | `notifications_navigator_host` | `/mobile/companies/<id>/notifications` |
| Profile | `tab_profile` | `employee_navigator_host` | `/mobile/companies/<id>/employee` |
| Attendance | `tab_attendance` | `attendance_navigator_host` | `/mobile/companies/<id>/attendance_month` |
| Operations | `tab_operations` | `operations_navigator_host` | `/mobile/companies/<id>/operations` |

`<id>` is the UUID extracted from the post-login redirect and stored in
`CompanyStore`. The bar is hidden on `SignInActivity`; it appears in
`MainActivity` only after a company-scoped page loads.

Payroll is not a tab. It is pushed onto the Profile stack from the Profile page
and sits behind `/payroll/unlock`. The shell clears the Profile stack when the
user leaves the tab or backgrounds the app, so returning cannot reveal an
already-open payroll screen without a fresh password entry. **Check In** is a
POST action (`/mobile/companies/<id>/attendances`), not a page, so it stays a
button on the Home page rather than a tab.

### 5.1 How a tab is defined

Each tab is a `HotwireBottomTab`:

```kotlin
HotwireBottomTab(
    title = getString(R.string.tab_home),
    iconResId = R.drawable.ic_tab_home,
    configuration = NavigatorConfiguration(
        name = "home",
        navigatorHostId = R.id.home_navigator_host,
        startLocation = "${BuildConfig.BASE_URL}/mobile/companies/$companyId/home"
    )
)
```

`MainActivity.buildTabs(companyId)` returns the list. The same list is used
twice:

- `navigatorConfigurations()` returns the configs for the delegate.
- `bottomNavigationController.load(buildTabs(companyId), ...)` renders the
  menu and switches hosts.

The `navigatorHostId` must match a `FragmentContainerView` ID in
`activity_main.xml`. If they do not match, navigation will crash or show a
blank host.

### 5.2 What happens when you tap a tab

`HotwireBottomNavigationController`:

1. calls `activity.delegate.setCurrentNavigator(tab.configuration)`,
2. hides every other `NavigatorHost` view,
3. shows the selected host,
4. updates the back-button callback to that tab's `Navigator`.

Each tab has its own navigation graph/back stack. Navigating inside one tab
does not affect the others.

### 5.3 Lazy loading

`lazyLoadTabs = true` means:

- the initially selected tab (Home) loads immediately,
- every other tab loads the first time it is selected.

This avoids opening five WebViews at launch. It also means the first tap on a
tab can take a moment while its WebView starts and loads the page.

### 5.4 Reselecting a tab

`clearNavigationOnTabReselection` defaults to `true` in
`HotwireBottomNavigationController`. Tapping the already-active tab calls
`clearAll()` on that tab's navigator, returning it to its start location. This
is the standard "tap Home again to go back to the top" behavior.

### 5.5 The Back button

`HotwireActivityDelegate` installs an `OnBackPressedCallback`. Pressing Back
pops the current tab's navigator. At the root of the Home tab, Back exits the
app/task as usual.

### 5.6 Selected tab index

`MainActivityViewModel.selectedTabIndex` stores the index. `load(...)` restores
it, and the tab-selection listener updates it. The manifest also declares
`android:configChanges="orientation|screenSize"`, so rotation does not recreate
the Activity; the ViewModel covers Activity recreation within the same process.
A full process death resets the selection to Home (index 0).

### 5.7 Visibility of the bottom bar

`HotwireBottomNavigationController` uses `Visibility.DEFAULT`:

- visible on normal pages,
- hidden when the keyboard is open,
- hidden when a modal screen is presented.

It also applies bottom system-bar insets so the bar does not overlap the
gesture/navigation bar.

---

## 6. Path configuration

### 6.1 What it is

Path configuration is a JSON file that tells Hotwire Native **how to present a
URL**:

- which fragment/destination to use,
- whether the screen is in the normal stack or a modal,
- whether pull-to-refresh is enabled,
- arbitrary custom properties for native screens.

### 6.2 Where it lives

Two copies, intentionally:

1. **Bundled:** `android/app/src/main/assets/json/path-configuration.json`
   — available immediately, even offline.
2. **Remote:** `public/configurations/android_v1.json`
   — served by Rails; fetched at startup and cached for future launches.

Loading order in `Hotwire.loadPathConfiguration`:

1. bundled asset (immediate),
2. cached remote copy from a previous successful download (if any),
3. fresh remote copy (downloaded asynchronously; replaces the cache when it
   succeeds).

If the remote file is unreachable, the bundled/cached copy still works.

### 6.3 Current rules

```json
{
  "settings": {},
  "rules": [
    {
      "patterns": [".*"],
      "properties": {
        "context": "default",
        "uri": "hotwire://fragment/web",
        "pull_to_refresh_enabled": true
      }
    },
    {
      "patterns": ["/mobile/sign_in$", "/new$"],
      "properties": {
        "pull_to_refresh_enabled": false
      }
    }
  ]
}
```

Explanation:

- **`.*`** matches every URL. It uses the built-in web fragment
  (`hotwire://fragment/web`), opens in the current tab's stack
  (`context: "default"`), and enables pull-to-refresh.
- **`/mobile/sign_in$`** disables pull-to-refresh on the sign-in page (so a
  downward gesture cannot clear the form).
- **`/new$`** disables pull-to-refresh on the attendance-request form
  (`/mobile/companies/<id>/attendance_requests/new`).

Rules are applied in order; a later matching rule can override properties from
an earlier one. That is why the catch-all rule comes first and the specific
overrides come after.

`hotwire://fragment/web` is the library's built-in web fragment. A custom URI
(such as `hotwire://fragment/web/modal/sheet`) only works if the app registers
a matching fragment destination — this app does not, yet. That is why the form
is not presented as a bottom sheet in this pass.

### 6.4 Changing the path configuration

1. Edit **both** files:
   - `android/app/src/main/assets/json/path-configuration.json`
   - `public/configurations/android_v1.json`
2. Rebuild/reinstall the app for the bundled asset change.
3. The remote copy is cached by Hotwire Native and by Rails' static-file
   cache headers. To force a refresh, clear the app's storage
   (`adb shell pm clear com.example.skycomandroid`) and relaunch.
4. Verify the remote file is reachable:
   `curl http://10.88.0.2:3000/configurations/android_v1.json`.

Rails serves `public/` files with `cache-control: public, max-age=2 days` in
development (see `config/environments/development.rb`), so aggressive caching is
possible. The Hotwire library also keeps its own cached copy.

### 6.5 Why a static file instead of a controller

The path configuration does not need authentication, database access, or a
Rails controller. A static `public/configurations/android_v1.json` is simpler,
avoids CSRF/auth concerns, and is exactly how the Hotwire Native docs recommend
serving it. In production the web server must serve `public/` (Rails' default
static-file middleware handles development).

---

## 7. Networking

### 7.1 `BASE_URL`

`android/app/build.gradle.kts`:

```kotlin
val skycomBaseUrl = providers.gradleProperty("skycomBaseUrl")
    .getOrElse("http://10.88.0.2:3000")
    .trimEnd('/')

android {
    defaultConfig {
        buildConfigField("String", "BASE_URL", "\"$skycomBaseUrl\"")
    }
}
```

`BuildConfig.BASE_URL` is generated at build time. Change it without editing
Kotlin:

```bash
./gradlew :app:assembleDebug -PskycomBaseUrl=http://10.0.2.2:3000
```

The value is used for:

- `SignInActivity`'s start location:
  `"${BuildConfig.BASE_URL}/mobile/sign_in"`,
- `MainActivity`'s company-scoped tab roots:
  `"${BuildConfig.BASE_URL}/mobile/companies/<company_id>/..."`,
- the remote path configuration:
  `"${BuildConfig.BASE_URL}/configurations/android_v1.json"`.

No trailing slash is stored (`trimEnd('/')`), so paths can be appended safely.

### 7.2 Why `10.88.0.2`

In this development environment, `10.88.0.2` is the dev machine/container's
`eth0` address. Rails binds to `0.0.0.0:3000` via `Procfile.dev`
(`bin/rails server -b 0.0.0.0`), so the app can reach it from the emulator or a
device on the same network.

Standard Android emulators map the host loopback to `10.0.2.2`. If
`10.88.0.2` is not routable from your emulator:

```bash
adb reverse tcp:3000 tcp:3000
./gradlew :app:assembleDebug -PskycomBaseUrl=http://127.0.0.1:3000
```

For a physical device, use the host's LAN IP (for example
`http://192.168.1.50:3000`), not `127.0.0.1`.

### 7.3 Cleartext HTTP

Android blocks cleartext HTTP by default on modern target SDKs. Debug builds
merge `android/app/src/debug/AndroidManifest.xml`, which sets:

```xml
<application android:usesCleartextTraffic="true" />
```

Release builds do **not** get this attribute. If you ship a release build, the
server must be HTTPS.

The debug setting allows cleartext to **any** host, not just `10.88.0.2`. If you
want tighter security, replace it with a `network_security_config.xml` that
allowlists only the dev host.

### 7.4 The Rails server

The app needs Rails running:

```bash
bin/dev
```

`bin/dev` starts:

- `web`: `bin/rails server -b 0.0.0.0` on port 3000,
- `css`: Tailwind watcher,
- `job`: Solid Queue worker.

If the app shows a native error screen, check that the server is running and
reachable at the URL in `BuildConfig.BASE_URL`.

---

## 8. Authentication and cookies

### 8.1 The Rails auth flow

`ApplicationController` includes `ApplicationController::AuthenticationConcern`
and runs `before_action :authenticate`. The concern's default behavior is:

```ruby
def authenticate
  redirect_to main_app.root_path if !is_signed_in?
end
```

The marketing homepage (`/`) is not the mobile app. `Mobile::BaseController`
overrides it:

```ruby
private

def authenticate
  redirect_to mobile_sign_in_path unless is_signed_in?
end
```

Why this was necessary:

- The Android shell now starts on `/mobile/sign_in` in `SignInActivity` and has
  no bottom tabs until authentication.
- If a signed-in user opens `/mobile/home` without an employee record, it
  renders the no-employee fallback instead of redirecting to `/`.
- `Mobile::Companies::BaseController` inherits this override, so an expired
  session on any company-scoped page redirects to mobile sign-in.

`Mobile::SessionsController` skips `authenticate` for `new`/`create`, so the
override does not create a redirect loop.

### 8.2 Session and cookies

`Mobile::SessionsController#create`:

1. `User.authenticate_by(email:, password:)`.
2. Creates a `Session` with a random `single_access_token`.
3. `update_cookie(session:, user:)`:
   - `cookies.signed[:session_token]` (HttpOnly, 1-day expiry),
   - `cookies[:is_signed_in]`,
   - `cookies[:client_cache_version]`.
4. Redirects to the employee's company home
   (`/mobile/companies/<uuid>/home`), or to `/mobile/home` when there is no
   employee record.
5. `SignInActivity` stores the company id and starts `MainActivity`.

`ApplicationController` resolves the session on every request via
`cookies.signed[:session_token]` and `Current.session_id` / `Current.user_id`.

The WebView stores cookies through Android's `CookieManager`. Hotwire Native
keeps the native cookie store and the WebView in sync, so sign-in, navigation,
and sign-out work like a browser.

### 8.3 Sign-out

`Mobile::SessionsController#destroy`:

- destroys `current_session`,
- `cookies.clear`,
- redirects to `/mobile/sign_in`.

### 8.4 `allow_browser :modern`

`ApplicationController` has `allow_browser versions: :modern` (Rails 8). It
returns HTTP 406 for old browsers/WebViews. The app's WebView must be roughly
Chrome 120+.

- The API 36 emulator image has a modern WebView and passes.
- An old device WebView gets `public/406-unsupported-browser.html`.
- Hotwire Native's `WebViewVersionCompatibility` dialog warns the user to
  update the WebView.

### 8.5 Clearing the session

To reset the app's cookies and cached path configuration:

```bash
adb shell pm clear com.example.skycomandroid
```

Or Android Settings → Apps → Skycom → Storage → Clear storage.

---

## 9. Navigation lifecycle

### 9.1 First launch

```
Application.onCreate
  → load path configuration (asset + remote)
SignInActivity.onCreate
  → HotwireActivityDelegate (one navigator: /mobile/sign_in)
  → inflate activity_sign_in (no bottom nav)
  → WebView loads /mobile/sign_in
  → user signs in
  → Rails redirects to /mobile/companies/<uuid>/home
  → SkycomWebFragment reports the URL
  → CompanyStore.write(company_id)
  → start MainActivity, finish SignInActivity
MainActivity.onCreate
  → HotwireActivityDelegate (reads buildTabs(company_id))
  → inflate layout (5 NavigatorHosts, tab bar hidden)
  → create HotwireBottomNavigationController
  → load(buildTabs(company_id), selectedTabIndex = 0)
  → Home Navigator loads /mobile/companies/<uuid>/home
  → company URL observed → show tab bar
```

### 9.2 Tab switch

```
tap Operations
  → BottomNavigationView listener
  → if leaving Profile: clear the Profile Navigator to its root
  → controller.switchTab(operations)
  → delegate.setCurrentNavigator(operations.configuration)
  → hide all hosts except operations_navigator_host
  → back callback targets the Operations Navigator
  → if first visit: Operations Navigator loads /mobile/companies/<id>/operations
```

Payroll is a stack page inside Profile:

```
tap Payroll on Profile
  → push /mobile/companies/<id>/payroll/unlock inside the Profile Navigator
  → enter password → POST /payroll/unlock
  → redirect to /mobile/companies/<id>/payroll
  → leaving Profile tab / backgrounding clears the stack back to Profile
```

### 9.3 Back

```
system Back
  → HotwireActivityDelegate.OnBackPressedCallback
  → currentNavigator.pop()
  → previous page in the current tab (Turbo visit)
```

At the root of the current tab, the callback can't pop, so Android's default
back behavior applies (leave the app/task).

### 9.4 Pull-to-refresh

The WebView fragment supports pull-to-refresh when the path configuration sets
`pull_to_refresh_enabled: true`. Our config enables it everywhere except
`/mobile/sign_in` and paths ending in `/new`.

### 9.5 Modals and the keyboard

The controller listens to navigation destination changes and IME visibility:

- keyboard visible → bottom bar hides,
- modal destination → bottom bar hides,
- keyboard closed / normal destination → bottom bar returns.

`applyDefaultImeWindowInsets` + `android:windowSoftInputMode="adjustResize"` keep
the WebView content above the keyboard.

---

## 10. Debugging

### 10.1 Inspect the WebView (Chrome DevTools)

`SkycomApplication` sets `Hotwire.config.webViewDebuggingEnabled =
BuildConfig.DEBUG`. In a debug build:

1. Connect the device/emulator.
2. Open Chrome on your computer.
3. Go to `chrome://inspect`.
4. Find the app's WebView and click **Inspect**.

This shows the DOM, console, network requests, and cookies for the Rails page.
It is the fastest way to debug HTML/Turbo/JS issues.

### 10.2 Hotwire logs

Debug builds set `HotwireLogLevel.DEBUG`. Filter logcat:

```bash
adb logcat -s Hotwire:V
```

You will see navigation/visit logs (URLs, path-configuration decisions,
fragment destinations).

### 10.3 Android crash logs

```bash
adb logcat -s AndroidRuntime:E
# or
adb logcat | grep -E "FATAL EXCEPTION|com.example.skycomandroid"
```

### 10.4 Rails logs

`bin/dev` prints the Rails log to the terminal, or read
`log/development.log`. Every WebView navigation appears as a normal Rails
request. This is how you confirm the app is hitting `/mobile/*` and what
redirects happen.

### 10.5 Screenshots

```bash
adb exec-out screencap -p > /tmp/skycom.png
```

Useful for confirming the tab bar, sign-in page, and native error screens.

### 10.6 Check the current URL

- The Hotwire debug log prints visit URLs.
- Chrome DevTools shows the current page.
- Rails logs show the request path.

### 10.7 Clear app state

```bash
adb shell pm clear com.example.skycomandroid
```

This removes cookies, cached path configuration, and the WebView's state. Use
it after changing `BASE_URL`, path configuration, or test users.

---

## 11. Build and run

### 11.1 Android Studio: Run vs Build

This is the most common confusion:

| Action | What it does |
|---|---|
| **Build → Make Project** / `assembleDebug` | Compiles the APK. Does **not** install or launch it. |
| **Run → Run 'app'** (Shift+F10) | Builds, installs on the selected device, and launches `SignInActivity`. |
| **Apply Changes** | Pushes code/resource changes to the running app (limited). |

If you only run `assembleDebug`, the APK exists at
`android/app/build/outputs/apk/debug/app-debug.apk`, but nothing is on the
device. That is why the app can be "missing" after a successful build.

### 11.2 The launcher icon

The app label is **Skycom** (`strings.xml`). On Android 13+ new installs go to
the **app drawer** (swipe up), not automatically to the home screen. Search for
"Skycom" there. Long-press → drag to add a home-screen shortcut.

### 11.3 Command line

```bash
cd android

# Build only
JAVA_HOME=/path/to/android-studio/jbr ./gradlew :app:assembleDebug

# Install (device/emulator must be running and authorized)
adb install -r app/build/outputs/apk/debug/app-debug.apk

# Launch
adb shell am start -n com.example.skycomandroid/.SignInActivity

# Build + install in one Gradle task
JAVA_HOME=/path/to/android-studio/jbr ./gradlew :app:installDebug
```

`JAVA_HOME` must point to a JDK 17+ (Android Studio's bundled JBR works:
`~/android-studio/jbr`).

### 11.4 Check the device

```bash
adb devices
```

Expected:

```
List of devices attached
emulator-5554   device
```

- `offline` → the emulator is still booting or crashed.
- `unauthorized` → accept the "Allow USB debugging" dialog (or wipe/cold boot
  the AVD).
- no devices → start an emulator or connect a phone.

If multiple devices are attached, target one with `adb -s <serial> ...`.

### 11.5 Host override

```bash
./gradlew :app:assembleDebug -PskycomBaseUrl=http://10.0.2.2:3000
```

Or, from Android Studio, add the property to the Gradle command line in the
run configuration, or edit the default in `app/build.gradle.kts`.

---

## 12. Troubleshooting

### 12.1 Build succeeds, but there is no app

**Cause:** `assembleDebug` only builds. It does not install.

**Fix:** use Android Studio **Run**, or `adb install -r ...`, then
`adb shell am start ...`. The app is called **Skycom** and lives in the app
drawer, not necessarily on the home screen.

### 12.2 Run does nothing / "No target device"

**Cause:** no emulator/device, or the emulator is offline/unauthorized.

**Fix:**

```bash
adb devices
```

Start the emulator from Android Studio's Device Manager. If it says
`unauthorized`, accept the debugging dialog; if it stays unauthorized, wipe the
AVD data and cold boot it.

### 12.3 The emulator is running, but I can't see its window

Android Studio launches the emulator with `-qt-hide-window` and embeds the
display in **View → Tool Windows → Running Devices**. Look there, not for a
separate emulator window.

### 12.4 Emulator cycles offline/unauthorized

Common causes:

- Two emulator processes are using the same AVD (for example, one started from
  Android Studio and one from a terminal/container).
- The AVD's data/ADB keys are stale or corrupted.
- The emulator crashed during boot.

Fixes, in order:

1. Make sure only one emulator is running for that AVD.
2. Device Manager → **Wipe Data**, then **Cold Boot Now**.
3. When the "Allow USB debugging?" dialog appears, tap **Allow**.
4. If it still fails:
   ```bash
   adb kill-server
   # back up first if you care about other devices:
   rm -f ~/.android/adbkey ~/.android/adbkey.pub
   adb start-server
   ```
   Then cold boot the emulator again.

### 12.5 App opens the marketing homepage instead of mobile sign-in

**Cause:** an old version of `Mobile::BaseController` that redirected to
`main_app.root_path`.

**Fix:** ensure this override exists and the Rails server reloaded:

```ruby
def authenticate
  redirect_to mobile_sign_in_path unless is_signed_in?
end
```

Check with:

```bash
curl -I http://10.88.0.2:3000/mobile/home
# expect: location: http://10.88.0.2:3000/mobile/sign_in
```

### 12.6 Blank/white screen

Possible causes:

- Rails is not running (`bin/dev`).
- The device cannot reach `BASE_URL` (wrong host/port).
- Cleartext HTTP is blocked (running a release build, or the debug manifest did
  not merge).

Fixes:

```bash
curl http://10.88.0.2:3000/up          # from the machine running Rails
adb reverse tcp:3000 tcp:3000          # emulator fallback
./gradlew :app:assembleDebug -PskycomBaseUrl=http://127.0.0.1:3000
```

Check `adb logcat` / Rails logs for the request.

### 12.7 `406 Not Acceptable` / "unsupported browser"

**Cause:** Rails `allow_browser versions: :modern` blocked an old WebView.

**Fix:** update Android System WebView / Chrome on the device, or use a modern
emulator image. Hotwire Native also shows an "update WebView" dialog.

### 12.8 The path configuration did not change

**Cause:** the remote config is cached, and/or the bundled asset was not
rebuilt.

**Fix:**

- edit both JSON files,
- rebuild/reinstall for the bundled copy,
- `adb shell pm clear com.example.skycomandroid` to drop the cached remote copy,
- relaunch.

### 12.9 Duplicate `META-INF/versions/9/OSGI-INF/MANIFEST.MF`

**Cause:** OkHttp 5 and jspecify both ship that file; AGP's Java-resource merge
fails.

**Fix:** the app's `packaging` block excludes it:

```kotlin
packaging {
    resources {
        excludes += "META-INF/versions/9/OSGI-INF/MANIFEST.MF"
    }
}
```

If a dependency update reintroduces a different duplicate, add the new path
there.

### 12.10 Kotlin metadata error

Example:

> Class '…' was compiled with an incompatible version of Kotlin. The binary
> version of its metadata is 2.3.0, expected version is 2.0.0.

**Cause:** the app is compiled with Kotlin 2.0.0 while Hotwire Native 1.3.2 was
compiled with Kotlin 2.3.0.

**Fix:** keep `kotlin = "2.3.0"` (or newer compatible) in
`android/gradle/libs.versions.toml`.

### 12.11 `compileSdk` errors

Hotwire Native 1.3.2 and modern AndroidX expect a current SDK. Keep
`compileSdk = 35` (and `targetSdk = 35`). Platform 35 must be installed in the
Android SDK.

### 12.12 Theme crash at launch

`HotwireActivity` extends `AppCompatActivity`, so the Activity theme must be an
AppCompat/Material theme. `Theme.SkycomAndroid` inherits
`Theme.MaterialComponents.DayNight.NoActionBar`. Do not switch it to a plain
`android:Theme.*` theme.

### 12.13 `INSTALL_FAILED_UPDATE_INCOMPATIBLE`

**Cause:** an existing install was signed with a different debug key.

**Fix:**

```bash
adb uninstall com.example.skycomandroid
adb install -r android/app/build/outputs/apk/debug/app-debug.apk
```

### 12.14 `CLEARTEXT communication not permitted`

**Cause:** release build, or the debug manifest was not merged.

**Fix:** run a debug build (`assembleDebug`/Run), and confirm the merged
manifest contains `android:usesCleartextTraffic="true"`.

### 12.15 The container cannot see the host emulator

This dev environment may run inside a distrobox/container while Android Studio
runs on the host. They can have separate ADB servers. The container's
`adb devices` may be empty even when the host's emulator is running. In that
case, deploy from Android Studio on the host instead of running `adb` in the
container.

Also: do not run the same AVD from both the host and the container at the same
time. That can produce this unauthorized/offline loop; it is what we observed
during development.

---

## 13. How to extend the app

### 13.1 Add a bottom tab

1. Add a `FragmentContainerView` to `activity_main.xml`:
   ```xml
   <androidx.fragment.app.FragmentContainerView
       android:id="@+id/reports_navigator_host"
       android:name="dev.hotwire.navigation.navigator.NavigatorHost"
       android:layout_width="match_parent"
       android:layout_height="0dp"
       app:defaultNavHost="false"
       app:layout_constraintBottom_toTopOf="@id/bottom_nav"
       app:layout_constraintTop_toTopOf="parent" />
   ```
2. Add a `HotwireBottomTab` in `MainActivity.buildTabs(companyId)` with the
   title, icon, host ID, and company-scoped URL path.
3. Add the title to `strings.xml` and a vector icon to `res/drawable/`.
4. Add the Rails route/controller/view under `namespace :mobile` (use the
   `/mobile/companies/:company_id/*` scope for tenant pages).
5. If the page needs different presentation (modal, no pull-to-refresh), update
   both path-configuration JSON files.
6. Rebuild. The controller/delegate need no changes.

Bottom navigation supports 3–5 items comfortably; stay within that range.

### 13.2 Present a page as a modal

1. Register a fragment destination in `SkycomApplication` (a custom web
   fragment that uses the modal/sheet presentation).
2. Add a path-configuration rule with `"context": "modal"` and the matching
   `"uri"`.
3. Test the dismiss gesture and keyboard behavior.

The current app has no custom destinations, so only `"context": "default"` is
used.

### 13.3 Add a native screen

1. Create a Fragment.
2. Register it with `Hotwire.registerFragmentDestinations(MyFragment::class)`
   in `SkycomApplication`.
3. Add a path rule whose `uri` points at the new destination
   (`hotwire://fragment/my-screen`).
4. Add the page/URL on the Rails side if the screen is reachable from a web
   link.

Native screens are useful for camera, biometrics, file upload, or anything the
WebView cannot do well.

### 13.4 Add a bridge component

Bridge components let web pages call native code (and vice versa). They require:

- a native component class registered with
  `Hotwire.registerBridgeComponents(...)`,
- a web-side Stimulus controller built with the Hotwire Native bridge JS
  library,
- the web page to include the bridge component markup.

**This repo does not currently include the web-side bridge JS package.** That is
a separate piece of work; do not assume a bridge exists just because the native
library supports it.

### 13.5 Add a deep link

1. Add an `<intent-filter>` for the scheme/host to `SignInActivity` (or to
   `MainActivity` only after a company id/session is available) in the
   manifest.
2. Route the incoming URL to the right tab/navigator (for example, through a
   `NavigatorConfiguration` or `controller.route(url)`).
3. Add any path-configuration rules the URL needs.

Not implemented today; the only intent filter is MAIN/LAUNCHER.

### 13.6 Add runtime server selection

`BASE_URL` is compile-time. A future settings screen could store a host in
SharedPreferences and pass it to `NavigatorConfiguration`/path configuration at
runtime. Not implemented today; use `-PskycomBaseUrl` and rebuild.

### 13.7 Localization

Native strings (`strings.xml`) are English only. The web translation system is
separate (`app/javascript/controllers/helpers/dictionary.js` + `translate()`).
If the native tab labels need Vietnamese, add `res/values-vi/strings.xml` with
the translated tab titles. This is not set up yet.

---

## 14. Limitations and next steps

- **Package name:** `com.example.skycomandroid` is an Android Studio
  placeholder. Rename `namespace` + `applicationId` (and the Kotlin package)
  before publishing. The adb launch command changes too.
- **No signing/release config:** release builds are not ready for distribution;
  add a keystore, signing config, R8/ProGuard rules, and HTTPS.
- **No push notifications, deep links, widgets, or app shortcuts.**
- **No bridge components or native screens** yet.
- **No Android UI tests/CI:** only unit tests for URL parsing exist; the Rails
  mobile feature specs cover the web pages.
- **Stored company id:** `MainActivity` trusts the last stored company id for
  routing. The server still authorizes every request; an invalid/stale id gets
  a `404` and returns the app to sign-in.
- **Company switching:** not built yet. The stored id is the last company used;
  a future picker would update it and rebuild the tab roots.
- **English-only native labels.**
- **Duplicated navigation:** the mobile home page still links to
  Profile/Attendance/Requests, and the detail pages still have "Back to Home"
  links. With tabs, those links navigate inside the active tab instead of
  switching tabs. It works, but a future polish pass should make the web home a
  dashboard that does not duplicate the tabs. Payroll is intentionally excluded
  from Home quick actions.
- **Path-config caching:** editing the remote JSON does not always take effect
  immediately; clear app data or wait for the cache.
- **Backup:** `android:allowBackup="true"` may include WebView cookies in device
  backups. Consider `false` for production.
- **Debug cleartext:** allowed for any host in debug. Use a network security
  config if that matters.

---

## 15. Decision log

| Decision | Why |
|---|---|
| Hotwire Native instead of a native rewrite | Reuses the existing Rails mobile pages/Turbo; no duplicate UI. |
| Five bottom tabs | Mirrors the five mobile destinations; Check In is an action, not a page. |
| One `NavigatorHost` per tab | Each tab keeps its own back stack and WebView state. |
| Lazy tab loading | Avoids loading five WebViews at launch. |
| Auth gate with no tabs | `SignInActivity` loads `/mobile/sign_in`; `MainActivity` is created only after Rails redirects to a company page. |
| Company-scoped URLs | Tenant pages live at `/mobile/companies/:company_id/*`; the server enforces membership on every request. |
| Store the company id in `SharedPreferences` | Lets the authenticated shell build company-scoped tab roots without a `current` redirect; cleared on sign-out/auth loss. |
| Custom `SkycomWebFragment` | Reports final WebView URLs and HTTP errors to the activities so tabs hide on sign-in and auth loss returns to the gate. |
| Static path configuration | No auth/database needed; works offline with the bundled copy. |
| Kotlin 2.3.0 / compileSdk 35 / Java 17 | Required by Hotwire Native 1.3.2 and modern AndroidX. |
| Remove Compose | The generated project was a Compose "Hello Android" sample; Hotwire navigation is Fragment/View-based. Compose can be added later for native screens. |
| `BuildConfig.BASE_URL` from a Gradle property | One place to change hosts; no Kotlin edits. |
| Cleartext HTTP debug-only | Keeps release builds safe while allowing the dev server. |
| No bridge/native screens in this pass | Keep the first working shell small; add them when a real feature needs them. |

---

## 16. Glossary

| Term | Meaning |
|---|---|
| **Hotwire Native** | Native wrapper around a WebView with native navigation. The Android library is `dev.hotwire:core` + `navigation-fragments`. |
| **Turbo** | The web-side library that makes links/forms navigate without full page reloads. Already part of the Rails app. |
| **Navigator** | Hotwire's per-tab navigation controller; owns a back stack of destinations. |
| **NavigatorHost** | A `FragmentContainerView` that hosts a `Navigator`. The layout has five, one per tab. |
| **NavigatorConfiguration** | The `name`/`navigatorHostId`/`startLocation` triple that tells Hotwire which host to use and where to start. |
| **Path configuration** | JSON rules that map URLs to fragments/contexts/pull-to-refresh settings. |
| **Bridge component** | A native component callable from web JS (not used yet). |
| **WebView** | Android's embedded browser; renders the Rails HTML. |
| **AVD** | Android Virtual Device (emulator). |
| **BuildConfig** | Generated Java class holding build-time constants such as `BASE_URL` and `DEBUG`. |
| **Gradle property** | A build-time key/value passed with `-Pname=value` (e.g. `-PskycomBaseUrl=...`). |
| **`bin/dev`** | Foreman process that starts Rails, Tailwind, and the job worker. |

---

## 17. Verification checklist

Run these after changing the Android shell or the mobile Rails pages.

### 17.1 Rails

```bash
bundle exec parallel_rspec -n 14 \
  spec/features/mobile \
  spec/requests/mobile \
  spec/helpers/mobile_helper_spec.rb
```

Expected: all examples pass.

Manual:

```bash
curl -I http://10.88.0.2:3000/mobile/home
# expect 302 -> /mobile/sign_in
curl -I http://10.88.0.2:3000/mobile/companies/00000000-0000-0000-0000-000000000000/home
# expect 302 -> /mobile/sign_in (signed out)
curl http://10.88.0.2:3000/configurations/android_v1.json
# expect 200 JSON
```

### 17.2 Android build and unit tests

```bash
cd android
JAVA_HOME=/path/to/android-studio/jbr ./gradlew :app:assembleDebug
JAVA_HOME=/path/to/android-studio/jbr ./gradlew :app:testDebugUnitTest
```

Expected: `BUILD SUCCESSFUL`.

### 17.3 Lint

```bash
cd android
JAVA_HOME=/path/to/android-studio/jbr ./gradlew :app:lintDebug
```

Expected: `0 errors` (warnings about newer dependency versions are fine).

### 17.4 Device smoke test

1. Start Rails (`bin/dev`) and the emulator/device.
2. Confirm `adb devices` shows `device`, not `offline`/`unauthorized`.
3. Run the `app` configuration in Android Studio (or install the APK).
4. Open **Skycom** from the app drawer.
5. Confirm the sign-in page has **no bottom tabs**.
6. Sign in; confirm the bottom tabs appear and the URL is
   `/mobile/companies/<company_id>/home` (not a `current` alias).
7. Check each tab: Home, Notifications, Profile, Attendance, Operations; every
   URL is company-scoped.
8. Open Profile → Payroll, confirm the password gate, then verify returning to
   Profile and reopening Payroll asks for the password again.
9. Check Back navigation inside a tab.
10. Pull to refresh on a normal page (should refresh) and on the sign-in/new
    form (should be disabled).
11. Sign out; confirm the tabs disappear and the app returns to
    `/mobile/sign_in`.
12. Relaunch while signed in: the app should go straight to the stored company
    tabs. Relaunch while signed out: sign-in only, no tabs.

If something fails, use §12 and the logs in §10 before changing code.
