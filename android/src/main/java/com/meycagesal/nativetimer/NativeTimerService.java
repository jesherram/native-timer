package com.meycagesal.nativetimer;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.graphics.drawable.GradientDrawable;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.util.Log;
import android.widget.RemoteViews;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;

import androidx.core.app.NotificationCompat;

// Para formatear fechas
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public class NativeTimerService extends Service {
    
    private static final String TAG = "NativeTimerService";
    private static final String CHANNEL_ID = "work_session_channel"; // ✅ Usar el mismo canal que Capacitor
    private static final int NOTIFICATION_ID = 1001;
    
    private static boolean serviceRunning = false;
    private static boolean notificationDismissed = false; // Track si usuario descartó notificación
    private static boolean appInForeground = true; // Track si app está en primer plano
    private static NativeTimerService instance;
    
    private Handler handler;
    private Runnable updateRunnable;
    private long startTime;
    private String startTimeFormatted;
    private String currentTitle = "Timer activo";
    private String currentBody = "00:00:00";
    private String currentPrimaryColor = "#0045a5"; // Color por defecto

    // Static methods para el plugin
    public static boolean isRunning() {
        return serviceRunning;
    }
    
    public static long getElapsedTime() {
        if (!serviceRunning || instance == null) {
            return 0;
        }
        return System.currentTimeMillis() - instance.startTime;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        Log.d(TAG, "Service created");
        instance = this;
        handler = new Handler(Looper.getMainLooper());
        // ✅ Canal ya creado por Capacitor, no necesitamos crearlo aquí
        Log.d(TAG, "Using notification channel created by Capacitor: " + CHANNEL_ID);
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.d(TAG, "Service onStartCommand");
        
        if (intent == null) {
            return START_STICKY;
        }
        
        String action = intent.getStringExtra("action");
        
        if ("START_TIMER".equals(action)) {
            // Solo actualizar startTime si no está ya ejecutándose el servicio
            if (!serviceRunning) {
                startTime = intent.getLongExtra("startTime", System.currentTimeMillis());
                // 🆕 Formatear la fecha de inicio
                startTimeFormatted = formatStartTime(startTime);
                Log.d(TAG, "Starting timer with new startTime: " + startTime + " (" + startTimeFormatted + ")");
            } else {
                Log.d(TAG, "Service already running, keeping existing startTime: " + startTime + " (" + startTimeFormatted + ")");
            }
            
            currentTitle = intent.getStringExtra("title");
            currentBody = intent.getStringExtra("body");
            currentPrimaryColor = intent.getStringExtra("primaryColor");
            
            if (currentTitle == null) currentTitle = "Timer activo";
            if (currentBody == null) currentBody = "00:00:00";
            if (currentPrimaryColor == null) currentPrimaryColor = "#0045a5";
            
            Log.d(TAG, "Starting timer with primary color: " + currentPrimaryColor);
            
            startTimerUpdates();
            
        } else if ("UPDATE_NOTIFICATION".equals(action)) {
            currentTitle = intent.getStringExtra("title");
            
            if (currentTitle == null) currentTitle = "Timer activo";
            
            // Calcular el tiempo transcurrido basado en nuestro startTime interno
            if (serviceRunning && startTime > 0) {
                long elapsed = System.currentTimeMillis() - startTime;
                currentBody = formatTime(elapsed);
                Log.d(TAG, "UPDATE_NOTIFICATION: calculated time = " + currentBody + " (startTime=" + startTime + ", elapsed=" + elapsed + "ms)");
            } else {
                currentBody = "00:00:00";
                Log.d(TAG, "UPDATE_NOTIFICATION: service not running or invalid startTime");
            }
            
            updateNotification(currentTitle, currentBody);
            
        } else if ("STOP_TIMER".equals(action)) {
            stopTimerUpdates();
            stopSelf();
            return START_NOT_STICKY;
        }
        
        return START_STICKY;
    }

    private void startTimerUpdates() {
        Log.d(TAG, "Starting timer updates");
        serviceRunning = true;
        
        // Crear la notificación inicial
        Notification notification = createNotification(currentTitle, currentBody);
        startForeground(NOTIFICATION_ID, notification);
        
        // Configurar las actualizaciones periódicas
        updateRunnable = new Runnable() {
            @Override
            public void run() {
                if (serviceRunning) {
                    // Calcular tiempo transcurrido usando timestamps (siempre necesario)
                    long elapsed = System.currentTimeMillis() - startTime;
                    String formattedTime = formatTime(elapsed);
                    
                    // 🆕 Solo actualizar si la notificación no ha sido descartada
                    if (!notificationDismissed) {
                        // Verificar que la notificación siga existiendo
                        ensureNotificationExists();
                        
                        Log.d(TAG, "Timer update: " + formattedTime + " (dismissed: " + notificationDismissed + ", foreground: " + appInForeground + ")");
                        
                        // Actualizar la notificación
                        updateNotification(currentTitle, formattedTime);
                    } else {
                        Log.d(TAG, "Notification dismissed - skipping update and notification recreation");
                    }
                    
                    // Notificar al plugin (si está disponible)
                    NativeTimerPlugin.notifyTimerUpdate(elapsed, formattedTime);
                    
                    // 🆕 Programar siguiente actualización con intervalo adaptativo
                    long updateInterval = getUpdateInterval();
                    handler.postDelayed(this, updateInterval);
                }
            }
        };
        
        // Iniciar las actualizaciones inmediatamente
        handler.post(updateRunnable);
    }
    
    /**
     * ⚡ Intervalo de actualización simplificado
     */
    private long getUpdateInterval() {
        // Intervalo simple cada 30 segundos
        return 30 * 1000; // 30 segundos
    }

    private void stopTimerUpdates() {
        Log.d(TAG, "Stopping timer updates");
        serviceRunning = false;
        
        if (handler != null && updateRunnable != null) {
            handler.removeCallbacks(updateRunnable);
        }
        
        stopForeground(true);
    }

    // ✅ Canal de notificación eliminado - ahora usa el de Capacitor

    private Notification createNotification(String title, String body) {
        Log.d(TAG, "🔔 Creating notification");
        
        // Intentar crear notificación personalizada primero
        try {
            return createCustomNotification(title, body);
        } catch (Exception e) {
            Log.w(TAG, "⚠️ Custom notification failed, using simple fallback", e);
            return createSimpleNotification(title, body);
        }
    }

    /**
     * 🎨 Crear notificación personalizada con vista custom
     */
    private Notification createCustomNotification(String title, String body) {
        Log.d(TAG, "🔔 Creating CUSTOM timer notification");
        
        // 🔗 Intent usando deep link para clock-in
        Intent notificationIntent = new Intent(Intent.ACTION_VIEW);
        notificationIntent.setData(android.net.Uri.parse("https://developjesushr.com/clock-in"));
        notificationIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        
        // 🔍 Debug logs para verificar Intent
        Log.d(TAG, "🔗 Intent using deep link: https://developjesushr.com/clock-in");
        Log.d(TAG, "🎯 Intent Action: " + notificationIntent.getAction());
        Log.d(TAG, "🎯 Intent Data: " + notificationIntent.getData());
        
        PendingIntent pendingIntent = PendingIntent.getActivity(
            this, 
            1001, 
            notificationIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
        );

        // Crear vista personalizada
        RemoteViews compactView = createCompactNotificationView();
        RemoteViews expandedView = createExpandedNotificationView();
        
        // ⏱️ CREAR NOTIFICACIÓN CON VISTA PERSONALIZADA
        NotificationCompat.Builder builder = new NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("⏰ JORNADA ACTIVA")
                .setContentText("Timer en progreso") 
                .setSmallIcon(android.R.drawable.ic_menu_agenda)
                .setColor(parseColor(currentPrimaryColor))
                .setColorized(true)
                .setContentIntent(pendingIntent)
                .setCustomContentView(compactView)          // Vista compacta (colapsada)
                .setCustomBigContentView(expandedView)      // Vista expandida (desplegada)
                .setStyle(new NotificationCompat.DecoratedCustomViewStyle())
                .setOngoing(true)
                .setAutoCancel(false)
                .setSilent(true)
                .setOnlyAlertOnce(true)
                .setShowWhen(true)
                .setWhen(startTime)
                .setUsesChronometer(true)    // ⭐ El timer se actualiza automáticamente
                .setChronometerCountDown(false)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setCategory(NotificationCompat.CATEGORY_SERVICE)
                .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
                .setDeleteIntent(null);

        // 🔒 CONFIGURACIÓN ADICIONAL PARA PANTALLA DE BLOQUEO
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            builder.setPublicVersion(builder.build());
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            builder.setBadgeIconType(NotificationCompat.BADGE_ICON_SMALL);
            builder.setChannelId(CHANNEL_ID);
        }
        
        Log.d(TAG, "✅ Custom timer notification created");
        return builder.build();
    }

    /**
     * 📱 Crear notificación simple como fallback
     */
    private Notification createSimpleNotification(String title, String body) {
        Log.d(TAG, "🔔 Creating SIMPLE chronometer notification (fallback)");
        
        // 🔗 Intent usando deep link para clock-in
        Intent notificationIntent = new Intent(Intent.ACTION_VIEW);
        notificationIntent.setData(android.net.Uri.parse("https://developjesushr.com/clock-in"));
        notificationIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        
        // 🔍 Debug logs para verificar Intent
        Log.d(TAG, "🔗 Intent using deep link: https://developjesushr.com/clock-in");
        Log.d(TAG, "🎯 Intent Action: " + notificationIntent.getAction());
        Log.d(TAG, "🎯 Intent Data: " + notificationIntent.getData());
        
        PendingIntent pendingIntent = PendingIntent.getActivity(
            this, 
            1002, 
            notificationIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
        );

        // 🎨 Formatear tiempo de inicio para mostrar
        String startTimeText = "Inicio: " + formatStartTime(startTime);
        
        // ⏱️ CREAR NOTIFICACIÓN SIMPLE CON CHRONOMETER (como iOS)
        NotificationCompat.Builder builder = new NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("⏰ JORNADA ACTIVA")
                .setContentText(startTimeText) // Timer aparece automáticamente antes del texto por chronometer
                .setSmallIcon(android.R.drawable.ic_menu_agenda) // 📅 Icono de agenda/horario
                .setColor(parseColor(currentPrimaryColor))
                .setColorized(true)
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .setAutoCancel(false)
                .setSilent(true)
                .setOnlyAlertOnce(true) // 🔇 Solo alertar una vez, no en actualizaciones posteriores
                .setShowWhen(true)           // 🆕 Mostrar tiempo
                .setWhen(startTime)          // 🆕 Tiempo de referencia
                .setUsesChronometer(true)    // 🆕 ¡CHRONOMETER! Como iOS - aparece antes del texto
                .setChronometerCountDown(false) // Contar hacia arriba
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC) // 🔒 Visible en pantalla de bloqueo
                .setPriority(NotificationCompat.PRIORITY_HIGH) // 🔒 Alta prioridad SOLO para creación inicial
                .setCategory(NotificationCompat.CATEGORY_SERVICE)
                .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
                .setDeleteIntent(null);

        // 🔒 CONFIGURACIÓN ADICIONAL PARA PANTALLA DE BLOQUEO
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            // Android 5.0+ - Configuración específica para pantalla de bloqueo
            builder.setPublicVersion(builder.build()); // Versión pública para pantalla de bloqueo
        }
        
        // 🔒 Para Android 8.0+ - Asegurar que aparezca en pantalla de bloqueo
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            builder.setBadgeIconType(NotificationCompat.BADGE_ICON_SMALL);
            builder.setChannelId(CHANNEL_ID);
        }
        
        Log.d(TAG, "✅ Simple chronometer notification created");
        return builder.build();
    }

    /**
     * 📱 Crear vista compacta para notificación colapsada
     */
    private RemoteViews createCompactNotificationView() {
        RemoteViews compactView = new RemoteViews(getPackageName(), R.layout.notification_timer_compact);
        
        try {
            // Configurar timer actual en la vista compacta
            long elapsedTimeMs = System.currentTimeMillis() - startTime;
            String currentTime = formatTime(elapsedTimeMs);
            compactView.setTextViewText(R.id.timer_compact, currentTime);
            
            Log.d(TAG, "✅ Compact view configured with timer: " + currentTime);
            
        } catch (Exception e) {
            Log.e(TAG, "❌ Error configuring compact view", e);
        }
        
        return compactView;
    }

    /**
     * 🎨 Crear vista expandida para notificación desplegada
     */
    private RemoteViews createExpandedNotificationView() {
        RemoteViews expandedView = new RemoteViews(getPackageName(), R.layout.notification_timer);
        
        try {
            // Configurar tiempo de inicio
            String startTimeText = "Inicio: " + formatStartTime(startTime);
            expandedView.setTextViewText(R.id.start_time, startTimeText);
            
            // Configurar timer actual (grande)
            long elapsedTimeMs = System.currentTimeMillis() - startTime;
            String currentTime = formatTime(elapsedTimeMs);
            expandedView.setTextViewText(R.id.timer_display, currentTime);
            
            // Configurar barra de progreso
            int elapsedMinutes = (int) (elapsedTimeMs / (1000 * 60));
            int maxMinutes = 8 * 60; // 8 horas máximo
            int progress = Math.min(elapsedMinutes, maxMinutes);
            
            expandedView.setProgressBar(R.id.progress_bar, maxMinutes, progress, false);
            
            Log.d(TAG, "✅ Expanded view configured with timer: " + currentTime);
            
        } catch (Exception e) {
            Log.e(TAG, "❌ Error configuring expanded view", e);
        }
        
        return expandedView;
    }

    /**
     * ⚡ Actualización SIMPLIFICADA
     */
    private void updateNotification(String title, String body) {
        if (!serviceRunning) {
            return;
        }
        
        Log.d(TAG, "📝 Updating notification");
        
        // Calcular tiempo transcurrido
        long elapsed = System.currentTimeMillis() - startTime;
        String formattedTime = formatTime(elapsed);
        
        // Solo actualizar si la notificación no ha sido descartada
        if (!notificationDismissed) {
            // Verificar que la notificación siga existiendo
            ensureNotificationExists();
            
            // Crear notificación simple actualizada
            Notification notification = createNotification(title, formattedTime);
            
            // Actualizar notificación
            NotificationManager manager = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
            if (manager != null) {
                manager.notify(NOTIFICATION_ID, notification);
            }
        }
        
        // Notificar al plugin
        NativeTimerPlugin.notifyTimerUpdate(elapsed, formattedTime);
    }

    /**
     * Verifica si la notificación está visible y la recrea si es necesario
     */
    private void ensureNotificationExists() {
        NotificationManager manager = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
        if (manager != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // En versiones modernas de Android, las notificaciones ongoing no se pueden eliminar
            // pero añadimos esta verificación por si acaso
            boolean hasActiveNotifications = false;
            try {
                android.service.notification.StatusBarNotification[] notifications = manager.getActiveNotifications();
                for (android.service.notification.StatusBarNotification notification : notifications) {
                    if (notification.getId() == NOTIFICATION_ID) {
                        hasActiveNotifications = true;
                        break;
                    }
                }
            } catch (Exception e) {
                Log.w(TAG, "Error checking active notifications", e);
            }
            
            if (!hasActiveNotifications && serviceRunning) {
                Log.w(TAG, "🚫 Notification was dismissed by user");
                
                // 🆕 Marcar que la notificación fue descartada
                notificationDismissed = true;
                
                // NO recrear automáticamente - respetar la decisión del usuario
                Log.i(TAG, "Notification will remain dismissed until user reopens app");
            }
        }
    }

    /**
     * Convierte un color hex string a int para Android
     */
    private int parseColor(String hexColor) {
        try {
            // Asegurar que tiene el formato correcto
            if (hexColor.startsWith("#")) {
                return android.graphics.Color.parseColor(hexColor);
            } else {
                return android.graphics.Color.parseColor("#" + hexColor);
            }
        } catch (Exception e) {
            Log.w(TAG, "Error parsing color: " + hexColor + ", using default", e);
            return 0xFF0045a5; // Color por defecto (azul Marmoles)
        }
    }

    /**
     * Formatea el tiempo en milisegundos a "X h Y min" (formato legible)
     */
    private String formatTime(long timeInMillis) {
        long totalSeconds = timeInMillis / 1000;
        long hours = totalSeconds / 3600;
        long minutes = (totalSeconds % 3600) / 60;
        
        if (hours > 0) {
            if (minutes > 0) {
                return String.format("%d h %d min", hours, minutes);
            } else {
                return String.format("%d h", hours);
            }
        } else {
            if (minutes > 0) {
                return String.format("%d min", minutes);
            } else {
                return "0 min";
            }
        }
    }

    /**
     * 🆕 Formatea la fecha de inicio para mostrar en la notificación
     * Formato: "DD de mes HH:MM"
     */
    private String formatStartTime(long timestamp) {
        try {
            Date date = new Date(timestamp);
            SimpleDateFormat formatter = new SimpleDateFormat("dd 'de' MMMM HH:mm", new Locale("es", "ES"));
            return formatter.format(date);
        } catch (Exception e) {
            Log.e(TAG, "Error formatting start time", e);
            // Fallback simple
            Date date = new Date(timestamp);
            SimpleDateFormat formatter = new SimpleDateFormat("dd/MM HH:mm", Locale.getDefault());
            return formatter.format(date);
        }
    }

    @Override
    public void onDestroy() {
        Log.d(TAG, "Service destroyed");
        serviceRunning = false;
        instance = null;
        
        if (handler != null && updateRunnable != null) {
            handler.removeCallbacks(updateRunnable);
        }
        
        super.onDestroy();
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null; // No binding
    }
    
    // 🆕 Métodos para controlar el estado de la app
    public static void setAppForegroundState(boolean inForeground) {
        appInForeground = inForeground;
        Log.d(TAG, "App foreground state changed: " + inForeground);
        
        // Si la app vuelve a primer plano y la notificación fue descartada, recrearla
        if (inForeground && notificationDismissed && serviceRunning && instance != null) {
            Log.i(TAG, "App returned to foreground, recreating dismissed notification");
            notificationDismissed = false; // Reset del flag
            
            // Recrear notificación
            long elapsed = System.currentTimeMillis() - instance.startTime;
            String formattedTime = instance.formatTime(elapsed);
            instance.updateNotification(instance.currentTitle, formattedTime);
        }
    }
    
    public static void resetNotificationDismissedState() {
        notificationDismissed = false;
        Log.d(TAG, "Notification dismissed state reset");
    }
}
