# @jesushr0013/native-timer

A Capacitor 8+ plugin for **work shift time tracking** (jornada laboral) with **Android Foreground Service** and **iOS Live Activities** (Dynamic Island + Lock Screen).

The widget displays a live "Jornada Activa" (Active Shift) timer designed specifically for tracking work hours.

## Features

- **Android**: Persistent foreground service with notification for shift tracking
- **iOS**: Live Activities with Dynamic Island and Lock Screen widget showing "Jornada Activa" (iOS 16.2+)
- **iOS**: Compatible with iOS 16.x and 17+ (SwiftUICore weak-linked)
- Background-safe timer that survives app suspension — ideal for long work shifts
- Customizable primary color for notifications and widgets
- Smart notification management (foreground/background aware)

## Requirements

| Platform | Minimum Version |
|----------|----------------|
| Capacitor | 8.0.0+ |
| iOS | 16.0+ (Live Activities require 16.2+) |
| Android | API 26+ (Android 8.0) |
| Xcode | 16+ |

## Installation

```bash
npm install @jesushr0013/native-timer
npx cap sync
```

## iOS Setup

### 1. Add Widget Extension

In Xcode, add a **Widget Extension** target to your project for Live Activities support.

### 2. Fix SwiftUICore for iOS 16.x

If you compile with Xcode 16+, you **must** add this linker flag to both your App target and Widget Extension target in Xcode:

**Build Settings → Other Linker Flags:**
```
-weak_framework SwiftUICore
```

This prevents a crash on iOS 16.x where `SwiftUICore.framework` doesn't exist as a standalone framework.

### 3. Entitlements

Add the `Push Notifications` capability and enable `Supports Live Activities` in your `Info.plist`:

```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

## Android Setup

The plugin automatically manages a Foreground Service. Make sure your `AndroidManifest.xml` includes:

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

## Usage

```typescript
import { NativeTimer } from '@jesushr0013/native-timer';

// Start a timer
// Note: title/body are for the Android notification only.
// The iOS widget always shows "⚡ Jornada Activa" as the title.
await NativeTimer.startTimer({
  startTime: Date.now(),
  title: 'Jornada Activa',
  body: 'Timer en marcha...',
  primaryColor: '#0045a5', // optional — widget & notification accent color
});

// Check if timer is running
const { isRunning } = await NativeTimer.isTimerRunning();

// Get elapsed time (ms)
const { elapsedTime } = await NativeTimer.getElapsedTime();

// Update notification text
await NativeTimer.updateNotification({
  title: 'Still working',
  body: '2h 30min elapsed',
});

// Stop the timer
await NativeTimer.stopTimer();
```

### Live Activities (iOS only)

```typescript
// Check availability
const { available } = await NativeTimer.areLiveActivitiesAvailable();

if (available) {
  // Start Live Activity
  const { activityId } = await NativeTimer.startLiveActivity({
    title: 'Work Session',
    startTime: new Date().toISOString(),
    elapsedTime: '0 h 0 min',
    status: 'active',
    primaryColor: '#0045a5',
  });

  // Update Live Activity
  await NativeTimer.updateLiveActivity({
    activityId: activityId!,
    elapsedTime: '1 h 30 min',
    status: 'active',
  });

  // Stop Live Activity
  await NativeTimer.stopLiveActivity({ activityId: activityId! });

  // Or stop all at once
  await NativeTimer.stopAllLiveActivities();
}
```

### Foreground State Management

```typescript
// Tell the plugin when your app goes to background/foreground
// to manage notifications intelligently
App.addListener('appStateChange', ({ isActive }) => {
  NativeTimer.setAppForegroundState({ inForeground: isActive });
});

// Reset notification dismissed state
await NativeTimer.resetNotificationState();
```

### Event Listener

```typescript
// Listen for periodic timer updates
const listener = await NativeTimer.addListener('timerUpdate', (data) => {
  console.log('Elapsed:', data.elapsedTime, 'ms');
  console.log('Formatted:', data.formattedTime);
});

// Remove all listeners
await NativeTimer.removeAllListeners();
```

## API

| Method | Description |
|--------|-------------|
| `startTimer(options)` | Start the native timer |
| `stopTimer()` | Stop the timer and remove notifications |
| `updateNotification(options)` | Update notification title/body |
| `isTimerRunning()` | Check if timer is active |
| `getElapsedTime()` | Get elapsed time in milliseconds |
| `setAppForegroundState(options)` | Set app foreground/background state |
| `resetNotificationState()` | Reset notification dismiss state |
| `areLiveActivitiesAvailable()` | Check Live Activities support (iOS) |
| `startLiveActivity(options)` | Start a Live Activity (iOS) |
| `updateLiveActivity(options)` | Update a Live Activity (iOS) |
| `stopLiveActivity(options)` | Stop a Live Activity (iOS) |
| `stopAllLiveActivities()` | Stop all Live Activities (iOS) |

## License

MIT
