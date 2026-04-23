package com.meycagesal.nativetimer;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.Log;

import androidx.core.app.NotificationManagerCompat;
import androidx.core.content.ContextCompat;

@CapacitorPlugin(name = "NativeTimer")
public class NativeTimerPlugin extends Plugin {
    
    private static final String TAG = "NativeTimerPlugin";

    @PluginMethod
    public void startTimer(PluginCall call) {
        Log.d(TAG, "startTimer called");

        if (!hasNotificationPermission()) {
            Log.w(TAG, "startTimer blocked: notification permission not granted");
            JSObject result = new JSObject();
            result.put("success", false);
            result.put("error", "notification_permission_required");
            call.resolve(result);
            return;
        }

        Long startTime = call.getLong("startTime");
        String title = call.getString("title", "Timer activo");
        String body = call.getString("body", "00:00:00");
        String primaryColor = call.getString("primaryColor", "#0045a5"); // Color por defecto
        
        if (startTime == null) {
            startTime = System.currentTimeMillis();
        }

        Log.d(TAG, "Starting timer with color: " + primaryColor);

        try {
            Intent serviceIntent = new Intent(getContext(), NativeTimerService.class);
            serviceIntent.putExtra("startTime", startTime);
            serviceIntent.putExtra("title", title);
            serviceIntent.putExtra("body", body);
            serviceIntent.putExtra("primaryColor", primaryColor);
            serviceIntent.putExtra("action", "START_TIMER");
            
            getContext().startForegroundService(serviceIntent);
            
            JSObject result = new JSObject();
            result.put("success", true);
            call.resolve(result);
        } catch (Exception e) {
            Log.e(TAG, "Error starting timer service", e);
            JSObject result = new JSObject();
            result.put("success", false);
            result.put("error", e.getMessage());
            call.resolve(result);
        }
    }

    @PluginMethod
    public void stopTimer(PluginCall call) {
        Log.d(TAG, "stopTimer called");
        
        try {
            Intent serviceIntent = new Intent(getContext(), NativeTimerService.class);
            serviceIntent.putExtra("action", "STOP_TIMER");
            getContext().stopService(serviceIntent);
            
            JSObject result = new JSObject();
            result.put("success", true);
            call.resolve(result);
        } catch (Exception e) {
            Log.e(TAG, "Error stopping timer service", e);
            JSObject result = new JSObject();
            result.put("success", false);
            result.put("error", e.getMessage());
            call.resolve(result);
        }
    }

    @PluginMethod
    public void updateNotification(PluginCall call) {
        Log.d(TAG, "updateNotification called");
        
        String title = call.getString("title", "Timer activo");
        // Ya no necesitamos el body desde TypeScript, el servicio lo calculará
        
        try {
            Intent serviceIntent = new Intent(getContext(), NativeTimerService.class);
            serviceIntent.putExtra("action", "UPDATE_NOTIFICATION");
            serviceIntent.putExtra("title", title);
            // No pasamos body, el servicio calculará el tiempo internamente
            getContext().startService(serviceIntent);
            
            JSObject result = new JSObject();
            result.put("success", true);
            call.resolve(result);
        } catch (Exception e) {
            Log.e(TAG, "Error updating notification", e);
            JSObject result = new JSObject();
            result.put("success", false);
            result.put("error", e.getMessage());
            call.resolve(result);
        }
    }

    @PluginMethod
    public void isTimerRunning(PluginCall call) {
        Log.d(TAG, "isTimerRunning called");
        
        // Esta información se puede obtener desde SharedPreferences
        // que el servicio puede actualizar
        JSObject result = new JSObject();
        result.put("isRunning", NativeTimerService.isRunning());
        call.resolve(result);
    }

    @PluginMethod
    public void getElapsedTime(PluginCall call) {
        Log.d(TAG, "getElapsedTime called");
        
        long elapsedTime = NativeTimerService.getElapsedTime();
        
        JSObject result = new JSObject();
        result.put("elapsedTime", elapsedTime);
        call.resolve(result);
    }
    
    @PluginMethod
    public void setAppForegroundState(PluginCall call) {
        Boolean inForeground = call.getBoolean("inForeground", true);
        Log.d(TAG, "Setting app foreground state: " + inForeground);
        
        NativeTimerService.setAppForegroundState(inForeground);
        
        JSObject result = new JSObject();
        result.put("success", true);
        call.resolve(result);
    }
    
    @PluginMethod
    public void resetNotificationState(PluginCall call) {
        Log.d(TAG, "Resetting notification dismissed state");
        
        NativeTimerService.resetNotificationDismissedState();
        
        JSObject result = new JSObject();
        result.put("success", true);
        call.resolve(result);
    }

    /**
     * Método llamado desde el servicio para notificar actualizaciones
     */
    public static void notifyTimerUpdate(long elapsedTime, String formattedTime) {
        // Implementar notificación a los listeners si es necesario
        // Por ahora el servicio maneja todo de forma independiente
        Log.d("NativeTimerPlugin", "Timer update: " + formattedTime + " (" + elapsedTime + "ms)");
    }

    /**
     * Comprueba si la app tiene permiso de notificaciones.
     * En API < 33 siempre es true (no existe POST_NOTIFICATIONS).
     * En API >= 33 valida el permiso runtime Y el estado del canal.
     */
    private boolean hasNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            boolean permissionGranted = ContextCompat.checkSelfPermission(
                    getContext(), Manifest.permission.POST_NOTIFICATIONS)
                    == PackageManager.PERMISSION_GRANTED;
            boolean notificationsEnabled = NotificationManagerCompat.from(getContext()).areNotificationsEnabled();
            Log.d(TAG, "hasNotificationPermission: permissionGranted=" + permissionGranted
                    + ", notificationsEnabled=" + notificationsEnabled);
            return permissionGranted && notificationsEnabled;
        }
        // API < 33: POST_NOTIFICATIONS no existe, siempre permitido
        return true;
    }
}
