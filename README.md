# @jesushr0013/native-timer

A Capacitor 8+ plugin for **work shift time tracking** (jornada laboral) with **Android Foreground Service** and **iOS Live Activities** (Dynamic Island + Lock Screen).

The widget displays a live "Jornada Activa" (Active Shift) timer designed specifically for tracking work hours.

---

## Table of Contents

- [Features](#features)
- [Architecture (v8.2.1+)](#architecture-v821)
- [Requirements](#requirements)
- [Installation](#installation)
- [iOS Setup](#ios-setup)
- [Android Setup](#android-setup)
- [Usage](#usage)
- [API Reference](#api-reference)
- [Upgrading from v8.1.x to v8.2.1](#upgrading-from-v81x-to-v821)
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

## Architecture (v8.2.1+)

The iOS code is split into **2 SPM/CocoaPods targets** to prevent the main app from linking SwiftUI/SwiftUICore:

```
ios/
├── Core/                          ┐
│   ├── NativeTimerManager.swift   │  Jesushr0013NativeTimer target
│   └── WorkSessionTimerAttributes.swift  │  (NO SwiftUI — safe on iOS 15+)
├── Plugin/                        │
│   └── NativeTimerPlugin.swift    ┘
└── LiveActivities/                ← Jesushr0013NativeTimerLiveActivities target
    └── NativeTimerWidget.swift       (SwiftUI — only in Widget Extension)
```

| Target (SPM / Pod) | SwiftUI? | What it contains |
|---------------------|----------|------------------|
| **Jesushr0013NativeTimer** / `Jesushr0013NativeTimer` pod | **No** | Timer logic (`NativeTimerManager`), `WorkSessionTimerAttributes` model, Capacitor plugin bridge (`NativeTimerPlugin`). Compiles `ios/Core/` + `ios/Plugin/` together. Auto-discovered by Capacitor. Safe on iOS 15+. |
| **Jesushr0013NativeTimerLiveActivities** / `NativeTimerKit` pod | **Yes** | SwiftUI widget (`NativeTimerWidget`) for Dynamic Island + Lock Screen. Compiles `ios/LiveActivities/`. Depends on the main target. Only loaded in the Widget Extension. |

> **Why this matters:** In previous versions (≤ 8.1.x), the widget's `import SwiftUI` lived in the same compile target as the plugin, causing `SwiftUICore` to be linked into the main app binary. On iOS 16.0–16.0.x, `SwiftUICore.framework` doesn't exist as a standalone framework, causing an **immediate crash at launch**. This 2-target architecture completely eliminates that problem — SwiftUI only exists in the Widget Extension binary, never in the main app.

### How it works

1. **Main target** (`Jesushr0013NativeTimer`): Capacitor discovers this target and links it into your app. It contains the plugin bridge + timer logic + `ActivityKit` model. It does **NOT** import SwiftUI. It uses `#if canImport(ActivityKit)` guards so that ActivityKit is only used on iOS 16.1+.

2. **Widget target** (`Jesushr0013NativeTimerLiveActivities`): This target compiles separately and is only linked into your Widget Extension target. It imports SwiftUI and the main target to access `WorkSessionTimerAttributes`. It provides `NativeTimerWidget` — a ready-to-use widget with Dynamic Island + Lock Screen UI.

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

## Installation

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

You should see `Jesushr0013NativeTimer` in the pod list. This pod includes **only** `ios/Core/` + `ios/Plugin/` — **no SwiftUI**.

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
cd ios/App
pod install
cd ../..
```

#### Option B: Swift Package Manager

1. In Xcode: File → Add Package Dependencies
2. Enter: `https://github.com/jesherram/native-timer.git`
3. Select version `8.2.1` or higher
4. Add **`Jesushr0013NativeTimerLiveActivities`** library to your **Widget Extension** target
5. Add **`Jesushr0013NativeTimer`** library to your **App** target (Capacitor may do this automatically)

### Step 5: Write the Widget Extension code

Replace the auto-generated Widget Extension code with:

```swift
import WidgetKit
import SwiftUI
import ActivityKit

// CocoaPods imports:
import MeycagesalNativeTimer   // provides WorkSessionTimerAttributes
import NativeTimerKit           // provides NativeTimerWidget (pre-built UI)

// If using SPM instead, replace the imports above with:
// import Jesushr0013NativeTimer
// import Jesushr0013NativeTimerLiveActivities

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
import MeycagesalNativeTimer  // or Jesushr0013NativeTimer for SPM

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

> **v8.2.1+:** Previous versions required adding `-weak_framework SwiftUICore` to the App target's linker flags. **This is no longer necessary.** The plugin target does not link SwiftUI at all.
>
> If you have this flag from a previous version, you can safely **remove it** from the App target. The `NativeTimerKit` pod handles weak linking of SwiftUI automatically in the Widget Extension only.

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

### `hasActiveLiveActivities()` *(iOS only)*

Checks if there are currently active Live Activities from this plugin.

**Returns:** `Promise<{ hasActive: boolean }>`

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

## Upgrading from v8.1.x to v8.2.1

### What changed

The iOS code was split from **1 target** (everything together) into **2 separate targets**. The main plugin target **no longer links SwiftUI**, completely fixing the `SwiftUICore` crash on iOS 16.

| Before (v8.1.x) | After (v8.2.1) |
|------------------|----------------|
| All Swift files in `ios/LiveActivitiesKit/` | Files split into `ios/Core/` + `ios/Plugin/` + `ios/LiveActivities/` |
| Single compile target (Plugin + Widget together) | 2 targets: main (Core+Plugin) and widget (LiveActivities) |
| `import SwiftUI` linked into main app → crash on iOS 16 | SwiftUI **only** in Widget Extension binary |
| Required `-weak_framework SwiftUICore` in App target | **Not needed** — remove it from App target |

### Step-by-step upgrade

```bash
# 1. Update the plugin
npm install @jesushr0013/native-timer@8.2.1

# 2. Remove local patches (if you had modified the plugin's Swift files locally)
#    Only needed if you used patch-package:
rm patches/@jesushr0013+native-timer+*.patch    # skip if you don't have patches

# 3. Sync Capacitor
npx cap sync ios

# 4. Reinstall pods from scratch (important: pod source paths changed)
cd ios/App
pod deintegrate
pod install --repo-update
cd ../..
```

Then in **Xcode**:

5. **Remove the old linker flag** (if you had it):
   - Select your **App** target → Build Settings → Other Linker Flags
   - **Remove** `-weak_framework SwiftUICore`
   - This flag is no longer needed in the App target

6. **Update Widget Extension** (if you have one):
   - Make sure `NativeTimerKit` pod is in your Podfile for the Widget Extension target
   - Update imports if needed (see [Step 5 in iOS Setup](#step-5-write-the-widget-extension-code))

7. **Clean and rebuild**:
   - Product → Clean Build Folder (`Cmd+Shift+K`)
   - Build (`Cmd+B`)

8. **Test on iOS 16 simulator** — the app should launch without any `SwiftUICore` crash.

---

## Troubleshooting

### `SwiftUICore not available` crash on iOS 16

**Cause:** You are using a version < 8.2.1, or pods were not reinstalled after upgrading.

**Fix:**
```bash
npm install @jesushr0013/native-timer@8.2.1
npx cap sync ios
cd ios/App && pod deintegrate && pod install --repo-update && cd ../..
```

Then verify in Xcode:
- App target → Build Settings → Other Linker Flags → should **NOT** contain `-weak_framework SwiftUICore`
- Clean Build Folder → Build

### Live Activities not appearing

1. Check that `NSSupportsLiveActivities` is `true` in `Info.plist`
2. Check that the Widget Extension target has `NativeTimerKit` pod (CocoaPods) or `Jesushr0013NativeTimerLiveActivities` library (SPM)
3. Check that the device is running iOS 16.2+
4. Check that Live Activities are enabled in Settings → Your App → Live Activities
5. Make sure the Widget Extension entry point includes `NativeTimerWidget()`:
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

### Pod install fails with "Unable to find a specification for NativeTimerKit"

The `NativeTimerKit` pod is a local podspec bundled with the plugin. Run with `--repo-update`:

```bash
cd ios/App
pod install --repo-update
cd ../..
```

### Widget Extension shows blank / doesn't load

1. Make sure you imported both modules in the Widget Extension:
   ```swift
   import MeycagesalNativeTimer   // WorkSessionTimerAttributes
   import NativeTimerKit           // NativeTimerWidget
   ```
2. Make sure your `@main` bundle references `NativeTimerWidget`
3. Clean Build Folder and rebuild both the App and Widget Extension targets

### Build error: "No such module 'NativeTimerCore'"

If you upgraded from v8.2.0, the intermediate `NativeTimerCore` module was removed in v8.2.1. Update your imports:
- **SPM**: `import Jesushr0013NativeTimer` (not `import NativeTimerCore`)
- **CocoaPods**: `import MeycagesalNativeTimer` (unchanged)

---

## License

MIT
