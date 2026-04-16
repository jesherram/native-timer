import Foundation
import Capacitor

#if canImport(ActivityKit)
import ActivityKit
#endif

@objc(NativeTimerPlugin)
public class NativeTimerPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "NativeTimerPlugin"
    public let jsName = "NativeTimer"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "startTimer", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stopTimer", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "updateNotification", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isTimerRunning", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getElapsedTime", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setAppForegroundState", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "resetNotificationState", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "areLiveActivitiesAvailable", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "hasActiveLiveActivities", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "startLiveActivity", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "updateLiveActivity", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stopLiveActivity", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stopAllLiveActivities", returnType: CAPPluginReturnPromise)
    ]
    
    private let nativeTimerManager = NativeTimerManager()
    
    @objc func startTimer(_ call: CAPPluginCall) {
        guard let startTime = call.getInt("startTime"),
              let title = call.getString("title"),
              let body = call.getString("body") else {
            call.reject("Missing required parameters")
            return
        }
        
        let primaryColor = call.getString("primaryColor")
        
        nativeTimerManager.startTimer(
            startTime: startTime,
            title: title,
            body: body,
            primaryColor: primaryColor
        )
        
        call.resolve(["success": true])
    }
    
    @objc func stopTimer(_ call: CAPPluginCall) {
        nativeTimerManager.stopTimer()
        call.resolve(["success": true])
    }
    
    @objc func updateNotification(_ call: CAPPluginCall) {
        guard let title = call.getString("title"),
              let body = call.getString("body") else {
            call.reject("Missing required parameters")
            return
        }
        
        nativeTimerManager.updateNotification(title: title, body: body)
        call.resolve(["success": true])
    }
    
    @objc func isTimerRunning(_ call: CAPPluginCall) {
        let isRunning = nativeTimerManager.isTimerRunning()
        call.resolve(["isRunning": isRunning])
    }
    
    @objc func getElapsedTime(_ call: CAPPluginCall) {
        let elapsedTime = nativeTimerManager.getElapsedTime()
        call.resolve(["elapsedTime": elapsedTime])
    }
    
    @objc func setAppForegroundState(_ call: CAPPluginCall) {
        guard let inForeground = call.getBool("inForeground") else {
            call.reject("Missing required parameter: inForeground")
            return
        }
        
        nativeTimerManager.setAppForegroundState(inForeground: inForeground)
        call.resolve(["success": true])
    }
    
    @objc func resetNotificationState(_ call: CAPPluginCall) {
        nativeTimerManager.resetNotificationState()
        call.resolve(["success": true])
    }
    
    @objc func areLiveActivitiesAvailable(_ call: CAPPluginCall) {
        guard #available(iOS 16.2, *) else {
            call.resolve(["available": false])
            return
        }
        
#if canImport(ActivityKit)
        call.resolve(["available": ActivityAuthorizationInfo().areActivitiesEnabled])
#else
        call.resolve(["available": false])
#endif
    }
    
    @objc func hasActiveLiveActivities(_ call: CAPPluginCall) {
        guard #available(iOS 16.2, *) else {
            call.resolve(["hasActive": false])
            return
        }
        
        let hasActive = nativeTimerManager.hasActiveLiveActivities()
        call.resolve(["hasActive": hasActive])
    }
    
    @objc func startLiveActivity(_ call: CAPPluginCall) {
        guard #available(iOS 16.2, *) else {
            call.reject("Live Activities require iOS 16.2+")
            return
        }
        
        guard let title = call.getString("title"),
              let startTime = call.getString("startTime"),
              let elapsedTime = call.getString("elapsedTime"),
              let status = call.getString("status") else {
            call.reject("Missing required parameters")
            return
        }
        
        let primaryColor = call.getString("primaryColor") ?? "#0045a5"
        print("🎨 startLiveActivity recibió primaryColor: \(primaryColor)")
        
        Task {
            do {
                let activityId = try await nativeTimerManager.startLiveActivity(
                    title: title,
                    startTime: startTime,
                    elapsedTime: elapsedTime,
                    status: status,
                    primaryColor: primaryColor
                )
                
                await MainActor.run {
                    call.resolve([
                        "success": true,
                        "activityId": activityId
                    ])
                }
            } catch {
                await MainActor.run {
                    call.reject("Failed to start Live Activity: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc func updateLiveActivity(_ call: CAPPluginCall) {
        guard #available(iOS 16.2, *) else {
            call.reject("Live Activities require iOS 16.2+")
            return
        }
        
        guard let activityId = call.getString("activityId"),
              let elapsedTime = call.getString("elapsedTime"),
              let status = call.getString("status") else {
            call.reject("Missing required parameters")
            return
        }
        
        Task {
            do {
                try await nativeTimerManager.updateLiveActivity(
                    activityId: activityId,
                    elapsedTime: elapsedTime,
                    status: status
                )
                
                await MainActor.run {
                    call.resolve(["success": true])
                }
            } catch {
                await MainActor.run {
                    call.reject("Failed to update Live Activity: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc func stopLiveActivity(_ call: CAPPluginCall) {
        guard #available(iOS 16.2, *) else {
            call.reject("Live Activities require iOS 16.2+")
            return
        }
        
        guard let activityId = call.getString("activityId") else {
            call.reject("Missing required parameter: activityId")
            return
        }
        
        Task {
            do {
                try await nativeTimerManager.stopLiveActivity(activityId: activityId)
                
                await MainActor.run {
                    call.resolve(["success": true])
                }
            } catch {
                await MainActor.run {
                    call.reject("Failed to stop Live Activity: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc func stopAllLiveActivities(_ call: CAPPluginCall) {
        guard #available(iOS 16.2, *) else {
            call.reject("Live Activities require iOS 16.2+")
            return
        }
        
        Task {
            do {
                try await nativeTimerManager.stopAllLiveActivities()
                
                await MainActor.run {
                    call.resolve(["success": true])
                }
            } catch {
                await MainActor.run {
                    call.reject("Failed to stop all Live Activities: \(error.localizedDescription)")
                }
            }
        }
    }
}
