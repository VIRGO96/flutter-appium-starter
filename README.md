# Flutter Appium Integration Test App

A minimal Flutter app demonstrating end-to-end UI test automation using [Appium Flutter Integration Driver](https://github.com/AppiumTestDistribution/appium-flutter-integration-driver) and WebdriverIO.

Built as a reference implementation for QA automation pipelines targeting Flutter Android apps.

---

## What's Inside

- **Login screen** with email/password validation and error handling
- **Home screen** shown after successful login
- **Widget keys** on all interactive elements for reliable Appium targeting
- **`appium_flutter_server`** embedded in the APK for Flutter-aware automation
- **WebdriverIO test script** for the full login flow

---

## Project Structure

```
lib/
├── main.dart                        # App entry point
├── models/
│   └── dashboard_item.dart          # Sample data model
├── providers/
│   └── auth_provider.dart           # Auth state (Provider)
├── router/
│   └── app_router.dart              # GoRouter navigation
├── screens/
│   ├── login_screen.dart            # Login UI
│   ├── home_screen.dart             # Home screen
│   └── dashboard_screen.dart        # Dashboard with sample items
└── widgets/
    └── dashboard_card.dart          # Reusable card widget

integration_test/
└── appium_test.dart                 # Appium entry point

test_login.js                        # WebdriverIO test script
```

---

## Test Credentials

```
Email:    test@example.com
Password: password123
```

---

## Prerequisites

| Tool | Version |
|------|---------|
| Flutter SDK | >=3.0.0 |
| Node.js | >=18 |
| Android Studio + Emulator | Latest |
| Appium | v3.x |

---

## Setup

### 1. Install Flutter dependencies

```bash
flutter pub get
```

### 2. Install Appium and drivers

```bash
npm install -g appium
appium driver install uiautomator2
appium driver install --source=npm appium-flutter-integration-driver
```

### 3. Install test script dependencies

```bash
npm install webdriverio
```

### 4. Bootstrap platform files (first time only)

```bash
bash setup.sh
```

---

## Running Tests

### 1. Start an Android emulator

```bash
emulator -avd <avd-name> -gpu swiftshader_indirect &
```

List available emulators:
```bash
flutter emulators
```

### 2. Build the profile APK

```bash
flutter build apk --profile --target=integration_test/appium_test.dart
```

### 3. Start Appium (Terminal 1)

```bash
appium
```

### 4. Run the test (Terminal 2)

```bash
node test_login.js
```

Appium installs and launches the APK automatically. No need to run `flutter run`.

---

## Widget Keys

All testable elements have explicit `Key()` values:

| Key | Widget |
|-----|--------|
| `email_input` | Email text field |
| `password_input` | Password text field |
| `login_button` | Sign In button |
| `error_message` | Error container (invalid login) |
| `home_screen` | Home screen scaffold |

In your test script, find elements using:

```js
async function byKey(driver, keyName) {
  const el = await driver.findElement('-flutter key', keyName);
  return driver.$(el);
}
```

---

## Appium Capabilities

```json
{
  "platformName": "Android",
  "appium:automationName": "FlutterIntegration",
  "appium:app": "/path/to/build/app/outputs/flutter-apk/app-profile.apk",
  "appium:deviceName": "emulator-5554",
  "appium:newCommandTimeout": 120
}
```

> **Important:** `automationName` must be `FlutterIntegration` — not `Flutter`. The old `Flutter` driver uses the deprecated Dart Observatory protocol and will fail.

---

## Tech Stack

- [Flutter](https://flutter.dev) — UI framework
- [Provider](https://pub.dev/packages/provider) — state management
- [GoRouter](https://pub.dev/packages/go_router) — navigation
- [shared_preferences](https://pub.dev/packages/shared_preferences) — session persistence
- [appium_flutter_server](https://pub.dev/packages/appium_flutter_server) — Appium integration
- [Appium](https://appium.io) v3 with [appium-flutter-integration-driver](https://github.com/AppiumTestDistribution/appium-flutter-integration-driver)
- [WebdriverIO](https://webdriver.io) — test runner

---

## License

MIT
