# @jesushr0013/native-timer

A Capacitor 8+ plugin for **work shift time tracking** (jornada laboral) with **Android Foreground Service** and **iOS Live Activities** (Dynamic Island + Lock Screen).

The widget displays a live "Jornada Activa" (Active Shift) timer designed specifically for tracking work hours.

---

## Table of Contents

- [Features](#features)
- [Architecture (v8.2.0+)](#architecture-v820)
- [Requirements](#requirements)
- [Installation (New Project)](#installation-new-project)
- [iOS Setup](#ios-setup)
- [Android Setup](#android-setup)
- [Usage](#usage)
- [API Reference](#api-reference)
- [Upgrading from v8.1.x to v8.2.0](#upgrading-from-v81x-to-v820)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## Features

- **Android**: Persistent foreground service with notification for shift tracking
- **iOS**: Live Activities with Dynamic Island and Lock Screen widget showing "⚡ Jornada Activa" (iOS 16.2+)
- **iOS**: Compatible with iOS 15+ — SwiftUI is **completely isolated** in a separate target, so there is **no crash on iOS 16**
- Background-safe timer that survives app suspension — ideal for long work shifts
- Customizable primary color for notifications and widgets
- Smart notification management (foreground/background aware)

---

## Architecture (v8.2.0+)

Starting from v8.2.0, the iOS code is split into **3 independent targets** to prevent the main app from linking SwiftUI/SwiftUICore:

```
ios/
├── Core/                          ← NativeTimerCore target
│   ├── NativeTimerManager.swift       (timer logic, ActivityKit management)
│   └── WorkSessionTimerAttributes.swift (ActivityAttributes model)
├── Plugin/                        ← Jesushr0013NativeTimer target
│   └── NativeTimerPlugin.swift        (Capacitor bridge)
└── LiveActivities/                ← NativeTimerLiveActivities target
    └── NativeTimerWidget.swift        (SwiftUI widget for Dynamic Island)
```

| Target | SwiftUI? | What it does |
|--------|----------|--------------|
| **NativeTimerCore** | **No** | Timer logic, notification management, `WorkSessionTimerAttributes` model, `NativeTimerManager` class. Safe on iOS 15+. |
| **Jesushr0013NativeTimer** | **No** | Capacitor plugin bridge (`NativeTimerPlugin`). Depends on Core. Auto-discovered by Capacitor. Safe on iOS 15+. |
| **NativeTimerLiveActivities** | **Yes** | SwiftUI widget for Dynamic Island and Lock Screen. Depends on Core. Only loaded in Widget Extension target. |

> **Why this matters:** In previous versions, the widget's `import SwiftUI` lived in the same target as the plugin, causing `SwiftUICore` to be linked into the main app binary. On iOS 16.0–16.0.x, `SwiftUICore.framework` doesn't exist as a standalone framework, causing an immediate crash at launch. This architecture completely eliminates that problem.

---

## Requirements

| Platform | Minimum Version |
|----------|----------------|
| Capacitor | 8.0.0+ |
| iOS | 15.0+ (Live Activities require 16.2+) |
| Android | API 26+ (Android 8.0) |
| Xcode | 16+ |
| Node.js | 18+ |

---

## Installation (New Project)

### Step 1: Install the npm package

```bash
npm install @jesushr0013/native-timer
```

### Step 2: Sync with native platforms

```bash
npx cap sync
```

This will:
- Copy the plugin to `node_modules/`
- Update `ios/App/Podfile` with the plugin's pod dependency
- Run `pod install` in the `ios/` folder
- Copy plugin files to the Android project

---

## iOS Setup

### Step 1: Verify pod installation

After `npx cap sync`, verify that the plugin was installed correctly:

```bash
cd ios
pod install
cd ..
```

You should see `Jesushr0013NativeTimer` in the pod list. This pod includes **only** `Core/` + `Plugin/` — **no SwiftUI**.

### Step 2: Enable Live Activities in Info.plist

Open `ios/App/App/Info.plist` and add:

```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

Or in Xcode: open Info.plist → add row → key `NSSupportsLiveActivities` → type `Boolean` → value `YES`.

### Step 3: Add Widget Extension (required for Live Activities)

Live Activities need a **Widget Extension** target in your Xcode project:

1. Open `ios/App/App.xcworkspace` in Xcode
2. File → New → Target → **Widget Extension**
3. Name it (e.g. `TimerWidgetExtension`)
4. Uncheck "Include Configuration App Intent" (not needed)
5. Click Finish

### Step 4: Add NativeTimerKit to Widget Extension

#### Option A: CocoaPods (recommended for Capacitor projects)

Edit your `ios/App/Podfile` and add a target block for the Widget Extension:

```ruby
target 'App' do
  capacitor_pods
  # ... your existing pods
end

# Add this new block:
target 'TimerWidgetExtension' do
  pod 'NativeTimerKit'
end
```

Then reinstall pods:

```bash
cd ios
pod install
cd ..
```

#### Option B: Swift Package Manager

1. In Xcode: File → Add Package Dependencies
2. Enter: `https://github.com/jesherram/native-timer.git`
3. Select version `8.2.0` or higher
4. Add `NativeTimerLiveActivities` library to your **Widget Extension** target

### Step 5: Write the Widget Extension code

Replace the auto-generated Widget Extension code with:

```swift
import WidgetKit
import SwiftUI
import ActivityKit

// CocoaPods imports:
import MeycagesalNativeTimer   // provides WorkSessionTimerAttributes + NativeTimerManager
import NativeTimerKit           // provides NativeTimerWidget (pre-built UI)

// If using SPM instead, replace the imports above with:
// import NativeTimerCore
// import NativeTimerLiveActivities

@main
struct TimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            NativeTimerWidget()
        }
    }
}
```

That's it! The `NativeTimerWidget` comes pre-built with:
- Lock Screen banner with gradient background
- Dynamic Island (expanded, compact, and minimal views)
- Live timer counter using SwiftUI `.timer` style
- Customizable accent color via `primaryColor`

#### Optional: Build your own custom widget

If you want to customize the widget UI, use `WorkSessionTimerAttributes` directly:

```swift
import ActivityKit
import SwiftUI
import WidgetKit
import MeycagesalNativeTimer  // or NativeTimerCore for SPM

@available(iOS 16.1, *)
struct MyCustomTimerWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkSessionTimerAttributes.self) { context in
            // Lock Screen UI
            VStack {
                Text(context.state.title)
                Text(context.state.elapsedTime)
                    .font(.title.bold())
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.elapsedTime)
                        .font(.title2.bold())
                }
            } compactLeading: {
                Image(systemName: "timer")
            } compactTrailing: {
                Text(context.state.elapsedTime)
                    .font(.caption2)
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }
}
```

**Available fields in `context.state`:**

| Field | Type | Description |
|-------|------|-------------|
| `title` | `String` | Session name |
| `elapsedTime` | `String` | Formatted elapsed time (e.g. `"1 h 30 min"`) |
| `status` | `String` | Session status (e.g. `"active"`) |
| `startTime` | `String` | ISO 8601 start date |
| `primaryColor` | `String` | Hex color (e.g. `"#0045a5"`) |

### Step 6: No SwiftUICore workaround needed

> **v8.2.0+:** Previous versions required adding `-weak_framework SwiftUICore` to the App target's linker flags. **This is no longer necessary.** The plugin target does not link SwiftUI at all.
>
> If you have this flag from a previous version, you can safely **remove it** from the App target. Keep it **only** in the Widget Extension target (the `NativeTimerKit` pod handles this automatically).

---

## Android Setup

### Step 1: Permissions

Make sure your `android/app/src/main/AndroidManifest.xml` includes:

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### Step 2: That's it

The plugin automatically registers the foreground service and notification channel. No additional native code is needed.

---

## Usage

### Import

```typescript
import { NativeTimer } from '@jesushr0013/native-timer';
```

### Basic Timer

```typescript
// Start a work shift timer
await NativeTimer.startTimer({
  startTime: Date.now(),           // timestamp in ms
  title: 'Jornada Activa',         // Android notification title
  body: 'Timer en marcha...',      // Android notification body
  primaryColor: '#0045a5',         // optional: accent color
});

// Check if running
const { isRunning } = await NativeTimer.isTimerRunning();

// Get elapsed time in milliseconds
const { elapsedTime } = await NativeTimer.getElapsedTime();

// Update the Android notification text
await NativeTimer.updateNotification({
  title: 'Jornada Activa',
  body: '2h 30min transcurridos',
});

// Stop everything
await NativeTimer.stopTimer();
```

### Live Activities (iOS 16.2+ only)

```typescript
// 1. Check if Live Activities are available
const { available } = await NativeTimer.areLiveActivitiesAvailable();

if (available) {
  // 2. Start a Live Activity (shows in Dynamic Island + Lock Screen)
  const { activityId } = await NativeTimer.startLiveActivity({
    title: 'Jornada Laboral',
    startTime: new Date().toISOString(),   // ISO 8601 format
    elapsedTime: '0 h 0 min',             // formatted string
    status: 'active',
    primaryColor: '#0045a5',               // optional
  });

  // 3. Update the Live Activity periodically
  await NativeTimer.updateLiveActivity({
    activityId: activityId!,
    elapsedTime: '1 h 30 min',
    status: 'active',
  });

  // 4. Stop the Live Activity when the shift ends
  await NativeTimer.stopLiveActivity({ activityId: activityId! });
}

// Or stop ALL Live Activities at once (useful for cleanup)
await NativeTimer.stopAllLiveActivities();
```

### Smart Foreground/Background Management

```typescript
import { App } from '@capacitor/app';

// Tell the plugin when the app goes to foreground/background
// This controls whether local notifications are shown
// (only shown in background to avoid bothering the user)
App.addListener('appStateChange', ({ isActive }) => {
  NativeTimer.setAppForegroundState({ inForeground: isActive });
});

// Reset the "notification dismissed" state when reopening the app
await NativeTimer.resetNotificationState();
```

### Timer Update Listener

```typescript
// Listen for periodic updates (every ~30 seconds)
const listener = await NativeTimer.addListener('timerUpdate', (data) => {
  console.log('Elapsed:', data.elapsedTime, 'ms');
  console.log('Formatted:', data.formattedTime);
});

// Clean up when done
await NativeTimer.removeAllListeners();
```

### Complete Example

```typescript
import { NativeTimer } from '@jesushr0013/native-timer';
import { App } from '@capacitor/app';
import { Capacitor } from '@capacitor/core';

let currentActivityId: string | null = null;

// --- Start shift ---
async function startShift() {
  const now = Date.now();
  const color = '#0045a5';

  // Start the native timer (Android foreground service + iOS timer)
  await NativeTimer.startTimer({
    startTime: now,
    title: 'Jornada Activa',
    body: 'Registrando tu jornada laboral...',
    primaryColor: color,
  });

  // On iOS, also start a Live Activity
  if (Capacitor.getPlatform() === 'ios') {
    const { available } = await NativeTimer.areLiveActivitiesAvailable();
    if (available) {
      const { activityId } = await NativeTimer.startLiveActivity({
        title: 'Jornada Laboral',
        startTime: new Date(now).toISOString(),
        elapsedTime: '0 h 0 min',
        status: 'active',
        primaryColor: color,
      });
      currentActivityId = activityId ?? null;
    }
  }
}

// --- Stop shift ---
async function stopShift() {
  await NativeTimer.stopTimer();

  if (currentActivityId) {
    await NativeTimer.stopLiveActivity({ activityId: currentActivityId });
    currentActivityId = null;
  }
}

// --- Foreground/background awareness ---
App.addListener('appStateChange', ({ isActive }) => {
  NativeTimer.setAppForegroundState({ inForeground: isActive });
  if (isActive) {
    NativeTimer.resetNotificationState();
  }
});
```

---

## API Reference

### `startTimer(options)`

Starts the native timer. On Android, creates a Foreground Service with a persistent notification. On iOS, prepares the internal timer for Live Activities.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `startTime` | `number` | Yes | Timestamp in milliseconds (e.g. `Date.now()`) |
| `title` | `string` | Yes | Notification title (Android only) |
| `body` | `string` | Yes | Notification body (Android only) |
| `primaryColor` | `string` | No | Hex color (e.g. `"#0045a5"`) for notification and widget accent |

**Returns:** `Promise<{ success: boolean }>`

---

### `stopTimer()`

Stops the timer, cancels the Foreground Service (Android), and removes all pending notifications.

**Returns:** `Promise<{ success: boolean }>`

---

### `updateNotification(options)`

Updates the Android notification text. On iOS, use `updateLiveActivity()` instead.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | `string` | Yes | New notification title |
| `body` | `string` | Yes | New notification body |

**Returns:** `Promise<{ success: boolean }>`

---

### `isTimerRunning()`

Checks if a timer is currently active.

**Returns:** `Promise<{ isRunning: boolean }>`

---

### `getElapsedTime()`

Gets the elapsed time since the timer was started.

**Returns:** `Promise<{ elapsedTime: number }>` — time in milliseconds

---

### `setAppForegroundState(options)`

Tells the plugin whether the app is in the foreground or background. Controls whether local notifications are displayed (only shown in background).

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `inForeground` | `boolean` | Yes | `true` if the app is visible, `false` if backgrounded |

**Returns:** `Promise<{ success: boolean }>`

---

### `resetNotificationState()`

Resets the internal "notification dismissed" state. Call this when reopening the app so notifications can be shown again in background.

**Returns:** `Promise<{ success: boolean }>`

---

### `areLiveActivitiesAvailable()` *(iOS only)*

Checks if the device supports Live Activities (requires iOS 16.2+ and user permission).

**Returns:** `Promise<{ available: boolean }>`

---

### `startLiveActivity(options)` *(iOS only)*

Starts a Live Activity showing the shift timer on Dynamic Island (iPhone 14 Pro+) and Lock Screen.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | `string` | Yes | Session name |
| `startTime` | `string` | Yes | Start date/time in ISO 8601 format |
| `elapsedTime` | `string` | Yes | Formatted elapsed time (e.g. `"1 h 30 min"`) |
| `status` | `string` | Yes | Session status (e.g. `"active"`, `"paused"`) |
| `primaryColor` | `string` | No | Hex color for the widget (default: `"#0045a5"`) |

**Returns:** `Promise<{ success: boolean; activityId?: string }>`

---

### `updateLiveActivity(options)` *(iOS only)*

Updates an existing Live Activity with new elapsed time and status.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `activityId` | `string` | Yes | ID returned by `startLiveActivity` |
| `elapsedTime` | `string` | Yes | Updated elapsed time (e.g. `"2 h 15 min"`) |
| `status` | `string` | Yes | Current status (e.g. `"active"`) |

**Returns:** `Promise<{ success: boolean }>`

---

### `stopLiveActivity(options)` *(iOS only)*

Stops a specific Live Activity and removes it from Dynamic Island and Lock Screen.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `activityId` | `string` | Yes | ID returned by `startLiveActivity` |

**Returns:** `Promise<{ success: boolean }>`

---

### `stopAllLiveActivities()` *(iOS only)*

Stops **all** active Live Activities from this plugin. Useful for cleanup on logout or shift end.

**Returns:** `Promise<{ success: boolean }>`

---

### `addListener('timerUpdate', callback)`

Listens for periodic timer updates (~30 seconds).

```typescript
const listener = await NativeTimer.addListener('timerUpdate', (data) => {
  console.log(data.elapsedTime);    // number (ms)
  console.log(data.formattedTime);  // string
});
```

---

### `removeAllListeners()`

Removes all registered listeners.

**Returns:** `Promise<void>`

---

## Upgrading from v8.1.x to v8.2.0

### What changed

The iOS code was split from 1 target into 3 separate targets. The main plugin **no longer links SwiftUI**, completely fixing the `SwiftUICore` crash on iOS 16.

### Step-by-step upgrade

```bash
# 1. Update the plugin
npm install @jesushr0013/native-timer@8.2.0

# 2. Remove local patches (if you had modified the plugin's Swift files locally)
#    Only needed if you used patch-package:
rm patches/@jesushr0013+native-timer+*.patch    # skip if you don't have patches

# 3. Sync Capacitor
npx cap sync ios

# 4. Reinstall pods from scratch (important: pod paths changed)
cd ios
pod deintegrate
pod install --repo-update
cd ..
```

Then in **Xcode**:

5. **Remove the old linker flag** (if you had it):
   - Select your **App** target → Build Settings → Other Linker Flags
   - **Remove** `-weak_framework SwiftUICore`
   - This flag is no longer needed in the App target

6. **Clean and rebuild**:
   - Product → Clean Build Folder (`Cmd+Shift+K`)
   - Build (`Cmd+B`)

7. **Test on iOS 16 simulator** — the app should launch without any `SwiftUICore` crash.

### Breaking changes for Widget Extension users

If your Widget Extension was importing files from the old `LiveActivitiesKit` directory:

| Before (v8.1.x) | After (v8.2.0) |
|------------------|----------------|
| Files in `ios/LiveActivitiesKit/` | Files split into `ios/Core/` + `ios/LiveActivities/` |
| Single target compiled everything together | 3 separate targets |
| `import MeycagesalNativeTimer` (CocoaPods) | `import MeycagesalNativeTimer` + `import NativeTimerKit` (CocoaPods) |
| N/A (SPM) | `import NativeTimerCore` + `import NativeTimerLiveActivities` (SPM) |

---

## Troubleshooting

### `SwiftUICore not available` crash on iOS 16

**Cause:** You are using a version < 8.2.0, or pods were not reinstalled after upgrading.

**Fix:**
```bash
npm install @jesushr0013/native-timer@8.2.0
npx cap sync ios
cd ios && pod deintegrate && pod install --repo-update && cd ..
```

### Live Activities not appearing

1. Check that `NSSupportsLiveActivities` is `true` in `Info.plist`
2. Check that the Widget Extension target has `NativeTimerKit` (CocoaPods) or `NativeTimerLiveActivities` (SPM)
3. Check that the device is running iOS 16.2+
4. Check that Live Activities are enabled in Settings → Your App → Live Activities

### Pod install fails with "Unable to find a specification for NativeTimerKit"

Run with `--repo-update` to refresh the pod specs cache:

```bash
cd ios
pod install --repo-update
cd ..
```

### Widget Extension shows blank / doesn't load

Make sure your Widget Extension's `@main` bundle includes the widget:

```swift
@main
struct TimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            NativeTimerWidget()
        }
    }
}
```

---

## License

MIT
