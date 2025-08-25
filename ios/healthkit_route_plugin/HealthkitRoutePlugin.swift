import Flutter
import UIKit
import HealthKit

public class HealthkitRoutePlugin: NSObject, FlutterPlugin {
    private var healthKitRouteManager: HealthKitRouteManager?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "healthkit_route_channel", binaryMessenger: registrar.messenger())
        let instance = HealthkitRoutePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        // HealthKit 경로 매니저 초기화
        instance.healthKitRouteManager = HealthKitRouteManager()
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "requestHealthKitPermissions":
            healthKitRouteManager?.requestHealthKitPermissions { success in
                result(success)
            }
            
        case "getWorkoutRoute":
            guard let args = call.arguments as? [String: Any],
                  let startTimestamp = args["startDate"] as? Double,
                  let endTimestamp = args["endDate"] as? Double else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                return
            }
            
            let startDate = Date(timeIntervalSince1970: startTimestamp / 1000)
            let endDate = Date(timeIntervalSince1970: endTimestamp / 1000)
            
            healthKitRouteManager?.getWorkoutRoute(startDate: startDate, endDate: endDate) { routeData in
                if let routeData = routeData {
                    result(routeData)
                } else {
                    result(nil)
                }
            }
            
        case "getWorkoutRoutes":
            guard let args = call.arguments as? [String: Any],
                  let startTimestamp = args["startDate"] as? Double,
                  let endTimestamp = args["endDate"] as? Double else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                return
            }
            
            let startDate = Date(timeIntervalSince1970: startTimestamp / 1000)
            let endDate = Date(timeIntervalSince1970: endTimestamp / 1000)
            
            healthKitRouteManager?.getWorkoutRoutes(startDate: startDate, endDate: endDate) { routesData in
                if let routesData = routesData {
                    result(routesData)
                } else {
                    result(nil)
                }
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
