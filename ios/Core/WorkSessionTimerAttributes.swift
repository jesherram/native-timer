import Foundation

#if canImport(ActivityKit)
import ActivityKit
#endif

#if canImport(ActivityKit)
@available(iOS 16.1, *)
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
#endif
