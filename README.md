# @jesushr0013/native-timer

A Capacitor 8+ plugin for **work shift time tracking** (jornada laboral) with **Android Foreground Service** and **iOS Live Activities** (Dynamic Island + Lock Screen).

The widget displays a live "Jornada Activa" (Active Shift) timer designed specifically for tracking work hours.

## Features

- **Android**: Persistent foreground service with notification for shift tracking
- **iOS**: Live Activities with Dynamic Island and Lock Screen widget showing "Jornada Activa" (iOS 16.2+)
- **iOS**: Compatible with iOS 15+ (plugin) — SwiftUI isolated in separate target, no crash on iOS 16
- Background-safe timer that survives app suspension — ideal for long work shifts
- Customizable primary color for notifications and widgets
- Smart notification management (foreground/background aware)

## Architecture (v8.2.0+)

The iOS code is split into **3 independent targets** to prevent the main app from linking SwiftUI/SwiftUICore:

| Target | Contains | SwiftUI? | Purpose |
|--------|----------|----------|---------|
| `NativeTimerCore` | `NativeTimerManager`, `WorkSessionTimerAttributes` | No | Shared timer logic & ActivityKit models |
| `Jesushr0013NativeTimer` | `NativeTimerPlugin` | No | Capacitor bridge (auto-discovered) |
| `NativeTimerLiveActivities` | `NativeTimerWidget` | Yes | Widget UI for Dynamic Island & Lock Screen |

This ensures the **main app binary never links SwiftUI**, fixing the `SwiftUICore not available` crash on iOS 16.

## Requirements

| Platform | Minimum Version |
|----------|----------------|
| Capacitor | 8.0.0+ |
| iOS | 15.0+ (Live Activities require 16.2+) |
| Android | API 26+ (Android 8.0) |
| Xcode | 16+ |

## Installation

```bash
npm install @jesushr0013/native-timer
npx cap sync
```

## iOS Setup

### 1. Add Widget Extension (for Live Activities)

In Xcode, add a **Widget Extension** target to your project for Live Activities support.

#### Using CocoaPods

In your Widget Extension's `Podfile` target, add:

```ruby
target 'YourWidgetExtension' do
  pod 'NativeTimerKit'
end
```

Then run:

```bash
cd ios && pod install
```

#### Using Swift Package Manager

Add the `NativeTimerLiveActivities` product from this package to your Widget Extension target in Xcode:

1. File → Add Package Dependencies
2. Enter: `https://github.com/jesherram/native-timer.git`
3. Select version `8.2.0` or higher
4. Add `NativeTimerLiveActivities` to your **Widget Extension** target
5. Add `Jesushr0013NativeTimer` to your **App** target (if not auto-resolved by Capacitor)

### 2. Widget Extension Code

In your Widget Extension's main file:

```swift
import WidgetKit
import SwiftUI

// CocoaPods:
import MeycagesalNativeTimer  // provides WorkSessionTimerAttributes
// SPM:
// import NativeTimerCore

// If using the pre-built widget:
import NativeTimerKit  // CocoaPods
// import NativeTimerLiveActivities  // SPM

@main
struct YourWidgetBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            NativeTimerWidget()
        }
    }
}
```

Or build your own custom widget using `WorkSessionTimerAttributes`:

```swift
import ActivityKit
import SwiftUI
import WidgetKit

// CocoaPods:
import MeycagesalNativeTimer
// SPM:
// import NativeTimerCore

@available(iOS 16.1, *)
struct MyCustomTimerWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkSessionTimerAttributes.self) { context in
            // Your custom Lock Screen UI
            Text(context.state.elapsedTime)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.elapsedTime)
                }
            } compactLeading: {
                Image(systemName: "timer")
            } compactTrailing: {
                Text(context.state.elapsedTime)
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }
}
```

### 3. Entitlements

Add the `Push Notifications` capability and enable `Supports Live Activities` in your `Info.plist`:

```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

### 4. No SwiftUICore workaround needed (v8.2.0+)

Previous versions required `-weak_framework SwiftUICore` in linker flags. **This is no longer needed** — the plugin target no longer links SwiftUI at all.

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

### `startTimer(options)`

Inicia el timer nativo. En Android crea un Foreground Service con notificación persistente. En iOS prepara el timer interno para Live Activities.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `startTime` | `number` | Yes | Timestamp en milisegundos (ej: `Date.now()`) del inicio de la jornada |
| `title` | `string` | Yes | Título de la notificación (solo Android) |
| `body` | `string` | Yes | Cuerpo de la notificación (solo Android) |
| `primaryColor` | `string` | No | Color hex (ej: `#0045a5`) para la notificación Android y el widget iOS |

**Returns:** `Promise<{ success: boolean }>`

---

### `stopTimer()`

Detiene el timer, cancela el Foreground Service (Android) y elimina todas las notificaciones pendientes.

**Returns:** `Promise<{ success: boolean }>`

---

### `updateNotification(options)`

Actualiza el texto de la notificación del timer en Android. En iOS no tiene efecto visible (el widget se actualiza via `updateLiveActivity`).

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | `string` | Yes | Nuevo título de la notificación |
| `body` | `string` | Yes | Nuevo cuerpo de la notificación |

**Returns:** `Promise<{ success: boolean }>`

---

### `isTimerRunning()`

Comprueba si hay un timer activo en ejecución.

**Returns:** `Promise<{ isRunning: boolean }>`

---

### `getElapsedTime()`

Obtiene el tiempo transcurrido desde que se inició el timer.

**Returns:** `Promise<{ elapsedTime: number }>` — tiempo en milisegundos

---

### `setAppForegroundState(options)`

Indica al plugin si la app está en primer o segundo plano. Esto controla si las notificaciones locales se muestran (solo en segundo plano) para no molestar al usuario mientras usa la app.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `inForeground` | `boolean` | Yes | `true` si la app está visible, `false` si está en segundo plano |

**Returns:** `Promise<{ success: boolean }>`

---

### `resetNotificationState()`

Resetea el estado interno de "notificación descartada". Útil al volver a abrir la app para que las notificaciones puedan mostrarse de nuevo en segundo plano.

**Returns:** `Promise<{ success: boolean }>`

---

### `areLiveActivitiesAvailable()` *(iOS only)*

Verifica si el dispositivo soporta Live Activities (requiere iOS 16.2+ y que el usuario las tenga habilitadas).

**Returns:** `Promise<{ available: boolean }>`

---

### `startLiveActivity(options)` *(iOS only)*

Inicia una Live Activity que muestra el timer de jornada en la Dynamic Island (iPhone 14 Pro+) y en la pantalla de bloqueo. El widget muestra "⚡ Jornada Activa" con un contador en tiempo real.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | `string` | Yes | Nombre de la sesión (usado internamente) |
| `startTime` | `string` | Yes | Fecha/hora de inicio en formato ISO 8601 |
| `elapsedTime` | `string` | Yes | Tiempo transcurrido formateado (ej: `"1 h 30 min"`) |
| `status` | `string` | Yes | Estado de la jornada (ej: `"active"`, `"paused"`) |
| `primaryColor` | `string` | No | Color hex para el widget (default: `#0045a5`) |

**Returns:** `Promise<{ success: boolean; activityId?: string }>` — el `activityId` se usa para actualizar o detener la actividad

---

### `updateLiveActivity(options)` *(iOS only)*

Actualiza una Live Activity existente con nuevo tiempo transcurrido y estado.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `activityId` | `string` | Yes | ID devuelto por `startLiveActivity` |
| `elapsedTime` | `string` | Yes | Tiempo transcurrido actualizado (ej: `"2 h 15 min"`) |
| `status` | `string` | Yes | Estado actual (ej: `"active"`) |

**Returns:** `Promise<{ success: boolean }>`

---

### `stopLiveActivity(options)` *(iOS only)*

Detiene una Live Activity específica y la elimina de la Dynamic Island y pantalla de bloqueo.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `activityId` | `string` | Yes | ID devuelto por `startLiveActivity` |

**Returns:** `Promise<{ success: boolean }>`

---

### `stopAllLiveActivities()` *(iOS only)*

Detiene **todas** las Live Activities activas del plugin. Útil para limpieza al cerrar sesión o al detener la jornada.

**Returns:** `Promise<{ success: boolean }>`

---

### `addListener('timerUpdate', callback)`

Escucha actualizaciones periódicas del timer (cada ~30 segundos).

```typescript
const listener = await NativeTimer.addListener('timerUpdate', (data) => {
  console.log(data.elapsedTime);    // number (ms)
  console.log(data.formattedTime);  // string
});
```

---

### `removeAllListeners()`

Elimina todos los listeners registrados.

**Returns:** `Promise<void>`

## Migrating from v8.1.x to v8.2.0

### What changed

The iOS code was split into 3 separate targets. The main plugin **no longer links SwiftUI**, fixing crashes on iOS 16.

### Steps

1. **Update the plugin:**
   ```bash
   npm install @jesushr0013/native-timer@8.2.0
   ```

2. **Remove local patches** (if you had modified the plugin's Swift files in `node_modules`):
   ```bash
   # If using patch-package, delete the old patch:
   rm patches/@jesushr0013+native-timer+*.patch
   ```

3. **Sync and reinstall pods:**
   ```bash
   npx cap sync ios
   cd ios
   pod deintegrate
   pod install --repo-update
   cd ..
   ```

4. **Remove old linker flags** — In Xcode, go to your **App target** → Build Settings → Other Linker Flags and remove:
   ```
   -weak_framework SwiftUICore
   ```
   This flag is **no longer needed** in the main app target.
   
   > **Note:** Keep `-weak_framework SwiftUICore` only in your **Widget Extension** target if using `NativeTimerKit`.

5. **Clean build:**
   - Xcode → Product → Clean Build Folder (`Cmd+Shift+K`)
   - Build (`Cmd+B`)

6. **Verify on iOS 16 simulator** — The app should launch without `SwiftUICore` crash.

### Breaking changes

- The `ios/LiveActivitiesKit/` directory was renamed to `ios/Core/` + `ios/LiveActivities/`
- If your Widget Extension was importing files directly from `LiveActivitiesKit`, update imports:
  - CocoaPods: `import MeycagesalNativeTimer` (unchanged)
  - SPM: `import NativeTimerCore` (new) + `import NativeTimerLiveActivities` (new)

## License

MIT
