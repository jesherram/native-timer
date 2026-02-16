#if canImport(ActivityKit)
import SwiftUI
import WidgetKit
import ActivityKit

@available(iOS 16.2, *)
public struct NativeTimerWidget: Widget {
    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkSessionTimerAttributes.self) { context in
            // Debug: Imprimir el primaryColor recibido
            let _ = print("🎨 Widget recibió primaryColor: \(context.state.primaryColor)")
            
            // Lock Screen / Banner UI - Diseño moderno y elegante
            HStack(spacing: 16) {
                // Icono circular con gradiente
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: context.state.primaryColor).opacity(0.8),
                                    Color(hex: context.state.primaryColor)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "timer")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Información del timer
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("⚡ Jornada Activa")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Text(formatStartDate(context.state.startTime))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // Timer grande y prominente
                    Text(calculateStartDate(from: context.state.elapsedTime), style: .timer)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                }
            }
            .padding(20)
            .background(
                // Fondo con gradiente basado en primaryColor
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: context.state.primaryColor).opacity(0.9),
                        Color(hex: context.state.primaryColor).opacity(0.7),
                        Color.black.opacity(0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    // Patrón sutil de puntos
                    Canvas { context, size in
                        let dotSize: CGFloat = 1.5
                        let spacing: CGFloat = 20
                        
                        for x in stride(from: 0, through: size.width, by: spacing) {
                            for y in stride(from: 0, through: size.height, by: spacing) {
                                let point = CGPoint(x: x, y: y)
                                context.fill(
                                    Path(ellipseIn: CGRect(
                                        origin: point,
                                        size: CGSize(width: dotSize, height: dotSize)
                                    )),
                                    with: .color(.white.opacity(0.1))
                                )
                            }
                        }
                    }
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI - Diseño más funcional
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: context.state.primaryColor))
                                .frame(width: 24, height: 24)
                            
                            Image(systemName: "timer")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Jornada")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Activa")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.leading, 12)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Desde")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.gray)
                        Text(formatStartDateShort(context.state.startTime))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.trailing, 12)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    // Timer principal completamente centrado
                    VStack(spacing: 0) {
                        Text(calculateStartDate(from: context.state.elapsedTime), style: .timer)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .monospacedDigit()
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 16)
                }
            } compactLeading: {
                // Icono compacto con color dinámico
                ZStack {
                    Circle()
                        .fill(Color(hex: context.state.primaryColor))
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "timer")
                        .foregroundColor(.white)
                        .font(.system(size: 10, weight: .bold))
                }
            } compactTrailing: {
                // Tiempo compacto con timer en tiempo real
                Text(calculateStartDate(from: context.state.elapsedTime), style: .timer)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: 45)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color(hex: context.state.primaryColor).opacity(0.8))
                    )
            } minimal: {
                // Versión minimal con color dinámico
                ZStack {
                    Circle()
                        .fill(Color(hex: context.state.primaryColor))
                        .frame(width: 20, height: 20)
                    
                    Image(systemName: "timer")
                        .foregroundColor(.white)
                        .font(.system(size: 8, weight: .bold))
                }
            }
        }
    }
    
    public init() {}
}

// MARK: - Helper Functions
private func calculateStartDate(from elapsedTime: String) -> Date {
    let now = Date()
    let totalSeconds = parseElapsedTimeToSeconds(elapsedTime)
    return now.addingTimeInterval(-Double(totalSeconds))
}

private func parseElapsedTimeToSeconds(_ timeString: String) -> Int {
    let components = timeString.components(separatedBy: " ")
    var totalSeconds = 0
    
    for i in 0..<components.count {
        if i < components.count - 1 {
            let value = Int(components[i]) ?? 0
            let unit = components[i + 1]
            
            switch unit {
            case "h":
                totalSeconds += value * 3600
            case "min":
                totalSeconds += value * 60
            default:
                break
            }
        }
    }
    
    return totalSeconds
}

private func formatElapsedTime(_ timeString: String) -> String {
    let components = timeString.components(separatedBy: " ")
    var result = ""
    
    for i in 0..<components.count {
        if i < components.count - 1 {
            let value = components[i]
            let unit = components[i + 1]
            
            if unit == "h" || unit.hasPrefix("h") {
                result += "\(value)h"
                if i + 2 < components.count {
                    result += " "
                }
            } else if unit == "min" || unit.hasPrefix("min") {
                result += "\(value)m"
            }
        }
    }
    
    return result.isEmpty ? timeString : result
}

private func formatElapsedTimeCompact(_ timeString: String) -> String {
    let components = timeString.components(separatedBy: " ")
    
    // Buscar horas y minutos
    var hours: String?
    var minutes: String?
    
    for i in 0..<components.count {
        if i < components.count - 1 {
            let value = components[i]
            let unit = components[i + 1]
            
            if unit == "h" || unit.hasPrefix("h") {
                hours = value
            } else if unit == "min" || unit.hasPrefix("min") {
                minutes = value
            }
        }
    }
    
    // Formatear de forma ultra compacta
    if let h = hours, let m = minutes {
        return "\(h):\(m.count == 1 ? "0" + m : m)"
    } else if let h = hours {
        return "\(h):00"
    } else if let m = minutes {
        return "0:\(m.count == 1 ? "0" + m : m)"
    }
    
    return "0:00"
}

private func formatStartTime(_ timeString: String) -> String {
    if timeString.contains(":") {
        let timeComponents = timeString.components(separatedBy: " ")
        let timeOnly = timeComponents.last ?? timeString
        let hourMinute = timeOnly.components(separatedBy: ":").prefix(2).joined(separator: ":")
        return hourMinute
    }
    return timeString
}

private func formatStartTimeExpanded(_ timeString: String) -> String {
    // Formateo más detallado para la vista expandida
    let formatters = [
        "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
        "yyyy-MM-dd'T'HH:mm:ssZ", 
        "yyyy-MM-dd'T'HH:mm:ss",
        "yyyy-MM-dd HH:mm:ss.SSS",
        "yyyy-MM-dd HH:mm:ss",
    ]
    
    for format in formatters {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "es_ES")
        formatter.timeZone = TimeZone.current
        
        if let date = formatter.date(from: timeString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "HH:mm"
            outputFormatter.locale = Locale(identifier: "es_ES")
            return outputFormatter.string(from: date)
        }
    }
    
    // Fallback a formatStartTime si no funciona el parsing completo
    return formatStartTime(timeString)
}

private func formatElapsedTimeExpanded(_ timeString: String) -> String {
    let components = timeString.components(separatedBy: " ")
    var hours: String?
    var minutes: String?
    
    // Buscar horas y minutos
    for i in 0..<components.count {
        if i < components.count - 1 {
            let value = components[i]
            let unit = components[i + 1]
            
            if unit == "h" || unit.hasPrefix("h") {
                hours = value
            } else if unit == "min" || unit.hasPrefix("min") {
                minutes = value
            }
        }
    }
    
    // Formatear para vista expandida - más descriptivo
    if let h = hours, let m = minutes {
        if h == "0" {
            return "\(m) min"
        } else if m == "0" {
            return "\(h) h"
        } else {
            return "\(h)h \(m)m"
        }
    } else if let h = hours {
        return "\(h) h"
    } else if let m = minutes {
        return "\(m) min"
    }
    
    return "0 min"
}

private func formatStartDate(_ dateString: String) -> String {
    let formatters = [
        "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
        "yyyy-MM-dd'T'HH:mm:ssZ", 
        "yyyy-MM-dd'T'HH:mm:ss",
        "yyyy-MM-dd HH:mm:ss.SSS",
        "yyyy-MM-dd HH:mm:ss",
        "dd/MM/yyyy HH:mm:ss",
        "yyyy-MM-dd",
        "dd/MM/yyyy"
    ]
    
    for format in formatters {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "es_ES")
        formatter.timeZone = TimeZone.current
        
        if let date = formatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "d MMM"
            outputFormatter.locale = Locale(identifier: "es_ES")
            return outputFormatter.string(from: date)
        }
    }
    
    let iso8601Formatter = ISO8601DateFormatter()
    iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    
    if let date = iso8601Formatter.date(from: dateString) {
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "d MMM"
        outputFormatter.locale = Locale(identifier: "es_ES")
        return outputFormatter.string(from: date)
    }
    
    return "Hoy"
}

private func formatStartDateShort(_ dateString: String) -> String {
    // Para el Dynamic Island trailing - formato completo con fecha y hora
    let formatters = [
        "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
        "yyyy-MM-dd'T'HH:mm:ssZ", 
        "yyyy-MM-dd'T'HH:mm:ss",
        "yyyy-MM-dd HH:mm:ss.SSS",
        "yyyy-MM-dd HH:mm:ss",
    ]
    
    for format in formatters {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "es_ES")
        formatter.timeZone = TimeZone.current
        
        if let date = formatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            let calendar = Calendar.current
            
            if calendar.isDateInToday(date) {
                // Para hoy: "Hoy 07:43"
                outputFormatter.dateFormat = "'Hoy' HH:mm"
            } else if calendar.isDateInYesterday(date) {
                // Para ayer: "Ayer 07:43"
                outputFormatter.dateFormat = "'Ayer' HH:mm"
            } else {
                // Para otras fechas: "3 de sep 07:43"
                outputFormatter.dateFormat = "d 'de' MMM HH:mm"
            }
            
            outputFormatter.locale = Locale(identifier: "es_ES")
            return outputFormatter.string(from: date)
        }
    }
    
    // Fallback con ISO8601
    let iso8601Formatter = ISO8601DateFormatter()
    iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    
    if let date = iso8601Formatter.date(from: dateString) {
        let outputFormatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            outputFormatter.dateFormat = "'Hoy' HH:mm"
        } else if calendar.isDateInYesterday(date) {
            outputFormatter.dateFormat = "'Ayer' HH:mm"
        } else {
            outputFormatter.dateFormat = "d 'de' MMM HH:mm"
        }
        
        outputFormatter.locale = Locale(identifier: "es_ES")
        return outputFormatter.string(from: date)
    }
    
    return "Hoy 00:00"
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

@available(iOS 16.2, *)
public struct NativeTimerWidgetBundle: WidgetBundle {
    public var body: some Widget {
        NativeTimerWidget()
    }
    
    public init() {}
}
#endif
