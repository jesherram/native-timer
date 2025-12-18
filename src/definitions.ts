export interface NativeTimerPlugin {
  /**
   * Inicia el timer nativo con foreground service (Android) o Live Activity (iOS)
   */
  startTimer(options: {
    startTime: number;
    title: string;
    body: string;
    primaryColor?: string;
  }): Promise<{ success: boolean }>;

  /**
   * Detiene el timer nativo
   */
  stopTimer(): Promise<{ success: boolean }>;

  /**
   * Actualiza la notificación del timer (Android) o Live Activity (iOS)
   */
  updateNotification(options: {
    title: string;
    body: string;
  }): Promise<{ success: boolean }>;

  /**
   * Verifica si el timer está activo
   */
  isTimerRunning(): Promise<{ isRunning: boolean }>;

  /**
   * Obtiene el tiempo transcurrido desde el inicio
   */
  getElapsedTime(): Promise<{ elapsedTime: number }>;

  /**
   * Configura el estado de primer plano de la app para el manejo inteligente de notificaciones
   */
  setAppForegroundState(options: { inForeground: boolean }): Promise<{ success: boolean }>;

  /**
   * Resetea el estado de descarte de notificación (útil al abrir la app)
   */
  resetNotificationState(): Promise<{ success: boolean }>;

  /**
   * iOS: Verifica si Live Activities están disponibles (iOS 16.2+)
   */
  areLiveActivitiesAvailable(): Promise<{ available: boolean }>;

  /**
   * iOS: Inicia una Live Activity para mostrar el timer en Dynamic Island y Lock Screen
   */
  startLiveActivity(options: {
    title: string;
    startTime: string;
    elapsedTime: string;
    status: string;
    primaryColor?: string;
  }): Promise<{ success: boolean; activityId?: string }>;

  /**
   * iOS: Actualiza una Live Activity existente
   */
  updateLiveActivity(options: {
    activityId: string;
    elapsedTime: string;
    status: string;
  }): Promise<{ success: boolean }>;

  /**
   * iOS: Detiene una Live Activity
   */
  stopLiveActivity(options: { activityId: string }): Promise<{ success: boolean }>;

  /**
   * iOS: Detiene todas las Live Activities activas
   */
  stopAllLiveActivities(): Promise<{ success: boolean }>;

  /**
   * Escucha los eventos del timer (cada 30 segundos)
   */
  addListener(
    eventName: 'timerUpdate',
    listenerFunc: (data: { elapsedTime: number; formattedTime: string }) => void,
  ): Promise<any>;

  /**
   * Remueve todos los listeners
   */
  removeAllListeners(): Promise<void>;
}
