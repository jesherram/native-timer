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

## License

MIT
