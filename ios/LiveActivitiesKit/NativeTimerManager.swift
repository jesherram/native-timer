import Foundation
import UserNotifications
import UIKit

#if canImport(ActivityKit)
import ActivityKit
#endif

@available(iOS 16.2, *)
public struct WorkSessionTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public let title: String
        public let elapsedTime: String
        public let status: String
        public let startTime: String
        public let primaryColor: String
        
        public init(title: String, elapsedTime: String, status: String, startTime: String, primaryColor: String = "#0045a5") {
            self.title = title
            self.elapsedTime = elapsedTime
            self.status = status
            self.startTime = startTime
            self.primaryColor = primaryColor
        }
    }
    
    public let sessionName: String
    
    public init(sessionName: String) {
        self.sessionName = sessionName
    }
}

public class NativeTimerManager {
    private var startTime: Date?
    private var timer: Timer?
    private var currentActivity: Any? // Almacena Activity<WorkSessionTimerAttributes> como Any
    private var appInForeground = true
    private var notificationDismissed = false
    
    public init() {
        // 🚫 Escuchar notificaciones de cancelación remota desde AppDelegate
        setupRemoteCancelObserver()
    }
    
    /// 🚫 Configura el observer para cancelaciones remotas via push notification
    private func setupRemoteCancelObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRemoteCancelNotification(_:)),
            name: Notification.Name("RemoteCancelTimer"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEndAllLiveActivities(_:)),
            name: Notification.Name("EndAllLiveActivities"),
            object: nil
        )
        
        print("✅ [NativeTimerManager] Observers de cancelación remota configurados")
    }
    
    /// 🚫 Maneja la cancelación remota del timer
    @objc private func handleRemoteCancelNotification(_ notification: Notification) {
        print("🚫 [NativeTimerManager] Cancelación remota recibida")
        
        let userInfo = notification.userInfo
        let cancelReason = userInfo?["cancelReason"] as? String ?? "Cancelación remota"
        
        print("Cancel Reason: \(cancelReason)")
        
        // Detener el timer
        stopTimer()
        
        // Detener Live Activities
        if #available(iOS 16.2, *) {
            Task {
                await endAllActiveLiveActivities()
            }
        }
        
        print("✅ [NativeTimerManager] Timer cancelado remotamente")
    }
    
    /// 🚫 Maneja la solicitud de terminar todas las Live Activities
    @objc private func handleEndAllLiveActivities(_ notification: Notification) {
        print("🚫 [NativeTimerManager] Solicitud de terminar todas las Live Activities")
        
        if #available(iOS 16.2, *) {
            Task {
                await endAllActiveLiveActivities()
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public func startTimer(startTime: Int, title: String, body: String, primaryColor: String?) {
        self.startTime = Date(timeIntervalSince1970: TimeInterval(startTime) / 1000)
        
        // 🛡️ PREVENCIÓN DE DUPLICADOS: Limpiar Live Activities existentes al reiniciar timer
        if #available(iOS 16.2, *), hasActiveLiveActivity() {
            print("⚠️ Timer reiniciado - limpiando Live Activities existentes...")
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                await endAllActiveLiveActivities()
                semaphore.signal()
            }
            semaphore.wait()
        }
        
        // Solicitar permisos de notificaciones
        requestNotificationPermissions()
        
        // Enviar notificación inicial solo si la app está en segundo plano
        if !appInForeground {
            sendNotification(title: title, body: body)
        }
        
        // Iniciar timer para actualizaciones
        startPeriodicUpdates()
    }
    
    public func stopTimer() {
        timer?.invalidate()
        timer = nil
        startTime = nil
        
        // Remover notificaciones
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    public func updateNotification(title: String, body: String) {
        // Solo actualizar notificación si está en segundo plano y no fue descartada
        if !appInForeground && !notificationDismissed {
            sendNotification(title: title, body: body)
        }
    }
    
    public func isTimerRunning() -> Bool {
        return startTime != nil && timer != nil
    }
    
    public func getElapsedTime() -> Int {
        guard let startTime = startTime else { return 0 }
        return Int(Date().timeIntervalSince(startTime) * 1000)
    }
    
    public func setAppForegroundState(inForeground: Bool) {
        appInForeground = inForeground
        
        if inForeground {
            // Al venir al primer plano, remover notificaciones
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            notificationDismissed = false // Resetear estado
        }
    }
    
    public func resetNotificationState() {
        notificationDismissed = false
    }
    
    // MARK: - Live Activities (iOS 16.2+)
    
    @available(iOS 16.2, *)
    public func startLiveActivity(title: String, startTime: String, elapsedTime: String, status: String, primaryColor: String = "#0045a5") throws -> String {
#if canImport(ActivityKit)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw NSError(domain: "LiveActivitiesDisabled", code: 1, userInfo: [NSLocalizedDescriptionKey: "Live Activities are not enabled"])
        }
        
        // 🛡️ PREVENCIÓN DE DUPLICADOS: Terminar cualquier Live Activity existente antes de crear una nueva
        if hasActiveLiveActivity() {
            print("⚠️ Detectada Live Activity existente, terminándola antes de crear nueva...")
            // Usar un semáforo para hacer la operación síncrona
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                await endAllActiveLiveActivities()
                semaphore.signal()
            }
            semaphore.wait()
        }
        
        let attributes = WorkSessionTimerAttributes(sessionName: title)
        let contentState = WorkSessionTimerAttributes.ContentState(
            title: title,
            elapsedTime: elapsedTime,
            status: status,
            startTime: startTime,
            primaryColor: primaryColor
        )
        
        print("🎨 NativeTimerManager creando ContentState con primaryColor: \(primaryColor)")
        
        do {
            let activity = try Activity<WorkSessionTimerAttributes>.request(
                attributes: attributes,
                contentState: contentState
            )
            
            // Almacenar la actividad como Any para evitar problemas con @available
            currentActivity = activity
            
            print("✅ Live Activity creada con ID: \(activity.id)")
            return activity.id
        } catch {
            throw error
        }
#else
        throw NSError(domain: "ActivityKitUnavailable", code: 2, userInfo: [NSLocalizedDescriptionKey: "ActivityKit not available"])
#endif
    }
    
    @available(iOS 16.2, *)
    public func updateLiveActivity(activityId: String, elapsedTime: String, status: String) async throws {
#if canImport(ActivityKit)
        guard let activity = currentActivity as? Activity<WorkSessionTimerAttributes> else {
            throw NSError(domain: "NoActiveActivity", code: 3, userInfo: [NSLocalizedDescriptionKey: "No active Live Activity found"])
        }
        
        let updatedContentState = WorkSessionTimerAttributes.ContentState(
            title: activity.attributes.sessionName,
            elapsedTime: elapsedTime,
            status: status,
            startTime: activity.contentState.startTime,
            primaryColor: activity.contentState.primaryColor
        )
        
        await activity.update(using: updatedContentState)
#else
        throw NSError(domain: "ActivityKitUnavailable", code: 2, userInfo: [NSLocalizedDescriptionKey: "ActivityKit not available"])
#endif
    }
    
    @available(iOS 16.2, *)
    public func stopLiveActivity(activityId: String) async throws {
#if canImport(ActivityKit)
        guard let activity = currentActivity as? Activity<WorkSessionTimerAttributes> else {
            throw NSError(domain: "NoActiveActivity", code: 3, userInfo: [NSLocalizedDescriptionKey: "No active Live Activity found"])
        }
        
        let finalContentState = WorkSessionTimerAttributes.ContentState(
            title: activity.attributes.sessionName,
            elapsedTime: activity.contentState.elapsedTime,
            status: "Finalizada",
            startTime: activity.contentState.startTime,
            primaryColor: activity.contentState.primaryColor
        )
        
        await activity.end(using: finalContentState, dismissalPolicy: .immediate)
        currentActivity = nil
#else
        throw NSError(domain: "ActivityKitUnavailable", code: 2, userInfo: [NSLocalizedDescriptionKey: "ActivityKit not available"])
#endif
    }
    
    // MARK: - Private Methods
    
    @available(iOS 16.2, *)
    private func hasActiveLiveActivity() -> Bool {
        #if canImport(ActivityKit)
        return !Activity<WorkSessionTimerAttributes>.activities.isEmpty
        #else
        return false
        #endif
    }
    
    @available(iOS 16.2, *)
    private func endAllActiveLiveActivities() async {
        #if canImport(ActivityKit)
        for activity in Activity<WorkSessionTimerAttributes>.activities {
            await activity.end(dismissalPolicy: .immediate)
            print("🛑 Live Activity terminada: \(activity.id)")
        }
        currentActivity = nil
        #endif
    }
    
    private func requestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Permisos de notificación otorgados")
            } else if let error = error {
                print("❌ Error solicitando permisos: \(error)")
            }
        }
    }
    
    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let identifier = "native-timer-notification"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        
        let center = UNUserNotificationCenter.current()
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
        center.add(request) { error in
            if let error = error {
                print("❌ Error enviando notificación: \(error)")
            }
        }
    }
    
    @available(iOS 16.2, *)
    public func hasActiveLiveActivities() -> Bool {
        #if canImport(ActivityKit)
        let activeCount = Activity<WorkSessionTimerAttributes>.activities.count
        print("📊 Live Activities activas: \(activeCount)")
        return activeCount > 0
        #else
        return false
        #endif
    }
    
    @available(iOS 16.2, *)
    public func stopAllLiveActivities() async throws {
        #if canImport(ActivityKit)
        // Finalizar todas las Live Activities activas
        for activity in Activity<WorkSessionTimerAttributes>.activities {
            await activity.end(dismissalPolicy: .immediate)
        }
        currentActivity = nil
        print("✅ Todas las Live Activities finalizadas")
        #endif
    }
    
    private func startPeriodicUpdates() {
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Solo para desarrollo - en producción esto se manejaría desde el servicio
            print("⏱️ Timer update - Elapsed: \(self.getElapsedTime())ms")
        }
    }
}
