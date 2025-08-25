import Flutter
import UIKit
import HealthKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var healthKitRouteManager: HealthKitRouteManager?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // HealthKit 경로 플러그인 등록
    let controller = window?.rootViewController as! FlutterViewController
    let healthKitRouteChannel = FlutterMethodChannel(name: "healthkit_route_channel", binaryMessenger: controller.binaryMessenger)
    
    // HealthKit 경로 매니저 초기화
    healthKitRouteManager = HealthKitRouteManager()
    
    // 메서드 호출 처리
    healthKitRouteChannel.setMethodCallHandler { [weak self] call, result in
      self?.handleMethodCall(call: call, result: result)
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
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

// MARK: - HealthKit Route Manager
@objc class HealthKitRouteManager: NSObject {
    private let healthStore = HKHealthStore()
    
    @objc func requestHealthKitPermissions(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute() // workoutRouteType 대신 workoutRoute() 사용
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    @objc func getWorkoutRoute(startDate: Date, endDate: Date, completion: @escaping ([[String: Any]]?) -> Void) {
        print("🔍 iOS: GPS 경로 조회 시작")
        print("🔍 iOS: 요청 시간 범위 - \(startDate) ~ \(endDate)")
        
        // 1. 운동 데이터 조회 (정확한 시간 범위)
        let workoutPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        let workoutQuery = HKSampleQuery(sampleType: .workoutType(), predicate: workoutPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] query, samples, error in
            if let error = error {
                print("❌ iOS: 운동 조회 오류 - \(error)")
                completion(nil)
                return
            }
            
            guard let workouts = samples as? [HKWorkout], !workouts.isEmpty else {
                print("⚠️ iOS: 해당 기간에 운동 데이터 없음")
                completion(nil)
                return
            }
            
            print("✅ iOS: \(workouts.count)개의 운동 발견")
            
            // 모든 발견된 운동 정보 로깅
            for (index, workout) in workouts.enumerated() {
                print("  📍 iOS: 운동 \(index + 1) - 타입: \(workout.workoutActivityType.rawValue), 거리: \(workout.totalDistance?.doubleValue(for: .meter()) ?? 0)m, 시간: \(workout.duration)초, 시작: \(workout.startDate), 종료: \(workout.endDate)")
            }
            
            // 첫 번째 운동 선택 (가장 정확한 매칭)
            let workout = workouts.first!
            print("✅ iOS: 선택된 운동 - 타입: \(workout.workoutActivityType.rawValue), 거리: \(workout.totalDistance?.doubleValue(for: .meter()) ?? 0)m, 시간: \(workout.duration)초")
            
            // 2. 해당 운동의 정확한 경로 조회
            self?.getRouteForWorkout(workout: workout, completion: completion)
        }
        
        healthStore.execute(workoutQuery)
    }
    
    private func getRouteForWorkout(workout: HKWorkout, completion: @escaping ([[String: Any]]?) -> Void) {
        print("🔍 iOS: 운동 경로 조회 - \(workout.workoutActivityType.rawValue)")
        
        // 해당 운동과 직접 연결된 경로만 조회 (UUID 기반)
        let routePredicate = HKQuery.predicateForObjects(from: workout)
        let routeQuery = HKSampleQuery(sampleType: HKSeriesType.workoutRoute(), predicate: routePredicate, limit: 1, sortDescriptors: nil) { [weak self] query, samples, error in
            if let error = error {
                print("❌ iOS: 경로 조회 오류 - \(error)")
                completion(nil)
                return
            }
            
            guard let routes = samples as? [HKWorkoutRoute], let route = routes.first else {
                print("⚠️ iOS: 해당 운동의 경로 데이터 없음")
                completion(nil)
                return
            }
            
            print("✅ iOS: 운동과 연결된 경로 발견 - 시작: \(route.startDate), 종료: \(route.endDate)")
            
            // 3. 경로의 위치 데이터 조회
            self?.getLocationsForRoute(route: route, completion: completion)
        }
        
        healthStore.execute(routeQuery)
    }
    
    private func getLocationsForRoute(route: HKWorkoutRoute, completion: @escaping ([[String: Any]]?) -> Void) {
        print("🔍 iOS: 경로 위치 데이터 조회")
        
        // HKWorkoutRouteQuery로 실제 위치 데이터 접근
        let locationQuery = HKWorkoutRouteQuery(route: route) { [weak self] query, locationsOrNil, done, error in
            if let error = error {
                print("❌ iOS: 위치 데이터 조회 오류 - \(error)")
                completion(nil)
                return
            }
            
            guard let locations = locationsOrNil, !locations.isEmpty else {
                if done {
                    print("⚠️ iOS: 위치 데이터 없음")
                    completion(nil)
                }
                return
            }
            
            print("✅ iOS: \(locations.count)개의 위치 데이터 수신 (완료: \(done))")
            
            // 위치 데이터를 Flutter에서 사용할 수 있는 형태로 변환
            let locationData = locations.map { location -> [String: Any] in
                return [
                    "latitude": location.coordinate.latitude,
                    "longitude": location.coordinate.longitude,
                    "altitude": location.altitude,
                    "timestamp": location.timestamp.timeIntervalSince1970 * 1000, // Flutter에서 사용할 수 있도록 밀리초 단위로 변환
                    "speed": location.speed >= 0 ? location.speed : 0,
                    "course": location.course >= 0 ? location.course : 0,
                    "horizontalAccuracy": location.horizontalAccuracy,
                    "verticalAccuracy": location.verticalAccuracy
                ]
            }
            
            if done {
                // 모든 위치 데이터를 받았을 때
                print("✅ iOS: 총 \(locationData.count)개의 GPS 포인트 완료")
                
                // 첫 번째와 마지막 포인트 로그
                if let first = locationData.first, let last = locationData.last {
                    print("📍 iOS: 첫 번째 포인트 - lat: \(first["latitude"]!), lng: \(first["longitude"]!)")
                    print("📍 iOS: 마지막 포인트 - lat: \(last["latitude"]!), lng: \(last["longitude"]!)")
                }
                
                DispatchQueue.main.async {
                    completion(locationData)
                }
            }
        }
        
        healthStore.execute(locationQuery)
    }
    
    @objc func getWorkoutRoutes(startDate: Date, endDate: Date, completion: @escaping ([[String: Any]]?) -> Void) {
        // 특정 기간의 모든 운동 경로 조회
        let workoutPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let workoutQuery = HKSampleQuery(sampleType: .workoutType(), predicate: workoutPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] query, samples, error in
            guard let workouts = samples as? [HKWorkout] else {
                completion(nil)
                return
            }
            
            var allRoutes: [[String: Any]] = []
            let group = DispatchGroup()
            
            for workout in workouts {
                group.enter()
                self?.getRouteForWorkout(workout: workout) { routeData in
                    if let routeData = routeData {
                        let workoutRoute = [
                            "workoutId": workout.uuid.uuidString,
                            "startDate": workout.startDate.timeIntervalSince1970 * 1000,
                            "endDate": workout.endDate.timeIntervalSince1970 * 1000,
                            "workoutType": workout.workoutActivityType.rawValue,
                            "totalDistance": workout.totalDistance?.doubleValue(for: .meter()) ?? 0,
                            "totalEnergyBurned": workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
                            "duration": workout.duration,
                            "routePoints": routeData
                        ]
                        allRoutes.append(workoutRoute)
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                completion(allRoutes)
            }
        }
        
        healthStore.execute(workoutQuery)
    }
}


