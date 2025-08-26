import Flutter
import UIKit
import HealthKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var healthKitRouteManager: HealthKitRouteManager?
  private let healthStore = HKHealthStore()
  
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
    case "testBasicCommunication":
      print("iOS: 기본 통신 테스트 메서드 호출됨")
      print("iOS: 이 로그가 보이면 iOS 네이티브 코드가 실행된 것입니다!")
      result("iOS 네이티브 코드에서 응답: 기본 통신 성공!")
      
    case "testLogging":
      print("iOS: 로깅 테스트 메서드 호출됨")
      print("iOS: 이 로그가 Flutter에서 보이면 iOS 네이티브 코드가 실행된 것입니다!")
      result("iOS 네이티브 코드에서 응답: 로깅 테스트 성공!")
      
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
      
      print("iOS: MethodChannel getWorkoutRoute 호출됨 - \(startDate) ~ \(endDate)")
      
      print("iOS: ===== MethodChannel getWorkoutRoute 호출됨 =====")
      print("iOS: 시작 시간: \(startDate)")
      print("iOS: 종료 시간: \(endDate)")
      print("iOS: collectGPSDataDirectly 메서드 호출 시작...")
      
      // 직접 GPS 데이터 수집 (HealthKitRouteManager 우회)
      self.collectGPSDataDirectly(startDate: startDate, endDate: endDate) { gpsData in
        if let gpsData = gpsData {
          print("iOS: MethodChannel - 직접 GPS 데이터 수집 완료: \(gpsData.count)개 포인트")
          result(gpsData)
        } else {
          print("iOS: MethodChannel - 직접 GPS 데이터 수집 실패")
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
  
  // MARK: - GPS 데이터 처리 메서드들
  private func getLocationsForRoute(route: HKWorkoutRoute, completion: @escaping ([[String: Any]]?) -> Void) {
    print("iOS: 경로 위치 데이터 조회")
    
    // HKWorkoutRouteQuery로 실제 위치 데이터 접근
    let routeQuery = HKWorkoutRouteQuery(route: route) { [weak self] query, locations, done, error in
      if let error = error {
        print("iOS: 경로 쿼리 오류: \(error)")
        completion(nil)
        return
      }
      
      guard let locations = locations else {
        if done {
          print("iOS: 경로 쿼리 완료")
          completion([])
        }
        return
      }
      
      // HKLocation을 딕셔너리로 변환
      let locationData = locations.map { location -> [String: Any] in
        return [
          "latitude": location.coordinate.latitude,
          "longitude": location.coordinate.longitude,
          "altitude": location.altitude,
          "horizontalAccuracy": location.horizontalAccuracy,
          "verticalAccuracy": location.verticalAccuracy,
          "course": location.course,
          "speed": location.speed,
          "timestamp": location.timestamp.timeIntervalSince1970
        ]
      }
      
      if done {
        print("iOS: 경로에서 \(locationData.count)개 포인트 수집 완료")
        completion(locationData)
      }
    }
    
    healthStore.execute(routeQuery)
  }
  
  private func removeDuplicateLocations(_ locations: [[String: Any]]) -> [[String: Any]] {
    var uniqueLocations: [[String: Any]] = []
    var seenCoordinates: Set<String> = []
    
    for location in locations {
      guard let lat = location["latitude"] as? Double,
            let lng = location["longitude"] as? Double else { continue }
      
      let coordinateKey = "\(lat),\(lng)"
      if !seenCoordinates.contains(coordinateKey) {
        seenCoordinates.insert(coordinateKey)
        uniqueLocations.append(location)
      }
    }
    
    return uniqueLocations
  }
  
  // MARK: - 직접 GPS 데이터 수집
  private func collectGPSDataDirectly(startDate: Date, endDate: Date, completion: @escaping ([[String: Any]]?) -> Void) {
    print("iOS: ===== collectGPSDataDirectly 메서드 시작 =====")
    print("iOS: 직접 GPS 데이터 수집 시작 - \(startDate) ~ \(endDate)")
    print("iOS: 이 로그가 보이면 iOS 네이티브 코드가 실행된 것입니다!")
    
          // 1. HKWorkoutRoute 쿼리로 GPS 데이터 수집
      let routeType = HKSeriesType.workoutRoute()
      let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
      
      print("iOS: HKWorkoutRoute 쿼리 실행 시작...")
      print("iOS: routeType: \(routeType)")
      print("iOS: predicate: \(predicate)")
    
    let query = HKSampleQuery(sampleType: routeType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { [weak self] query, samples, error in
      print("iOS: HKWorkoutRoute 쿼리 콜백 실행됨")
      
      if let error = error {
        print("iOS: HKWorkoutRoute 쿼리 오류: \(error)")
        completion(nil)
        return
      }
      
      guard let routes = samples as? [HKWorkoutRoute], !routes.isEmpty else {
        print("iOS: 해당 기간의 경로 데이터 없음")
        completion(nil)
        return
      }
      
      print("iOS: \(routes.count)개의 경로 발견")
      
      var allLocationData: [[String: Any]] = []
      let group = DispatchGroup()
      
      for (index, route) in routes.enumerated() {
        group.enter()
        print("iOS: 경로 \(index + 1) 처리 - 시작: \(route.startDate), 종료: \(route.endDate)")
        
        self?.getLocationsForRoute(route: route) { routeData in
          if let routeData = routeData {
            print("iOS: 경로 \(index + 1)에서 \(routeData.count)개 포인트 수집")
            allLocationData.append(contentsOf: routeData)
          } else {
            print("iOS: 경로 \(index + 1)에서 데이터 없음")
          }
          group.leave()
        }
      }
      
      group.notify(queue: .main) {
        print("iOS: 모든 경로 처리 완료 - 총 \(allLocationData.count)개 포인트")
        
        if !allLocationData.isEmpty {
          // 중복 제거 및 시간순 정렬
          let uniqueData = self?.removeDuplicateLocations(allLocationData) ?? []
          let sortedData = uniqueData.sorted { 
            ($0["timestamp"] as? Double ?? 0) < ($1["timestamp"] as? Double ?? 0)
          }
          
          print("iOS: 최종 GPS 데이터: \(sortedData.count)개 포인트 (중복 제거 후)")
          
          // 첫 번째와 마지막 포인트 로그
          if let first = sortedData.first, let last = sortedData.last {
            print("iOS: 첫 번째 포인트 - lat: \(first["latitude"]!), lng: \(first["longitude"]!)")
            print("iOS: 마지막 포인트 - lat: \(last["latitude"]!), lng: \(last["longitude"]!)")
          }
          
          print("iOS: ===== collectGPSDataDirectly 메서드 완료 =====")
          print("iOS: Flutter로 전송할 데이터: \(sortedData.count)개 포인트")
          print("iOS: 전송 데이터 샘플:")
          for (index, point) in sortedData.prefix(3).enumerated() {
            print("iOS:   포인트 \(index + 1): lat=\(point["latitude"]!), lng=\(point["longitude"]!), timestamp=\(point["timestamp"]!)")
          }
          completion(sortedData)
        } else {
          print("iOS: GPS 데이터 수집 실패")
          completion(nil)
        }
      }
    }
    
          print("iOS: healthStore.execute(query) 호출...")
      healthStore.execute(query)
      
      // 가짜 GPS 데이터 생성 제거 - 실제 GPS 데이터만 사용
      print("iOS: 가짜 GPS 데이터 생성 제거됨 - 실제 GPS 데이터만 사용")
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
            HKSeriesType.workoutRoute(), // workoutRouteType 대신 workoutRoute() 사용
            // HKObjectType.locationType()은 존재하지 않음 - 제거
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    @objc func getWorkoutRoute(startDate: Date, endDate: Date, completion: @escaping ([[String: Any]]?) -> Void) {
        print("iOS: ===== getWorkoutRoute 메서드 시작 =====")
        print("iOS: 운동 경로 데이터 조회 시작 - \(startDate) ~ \(endDate)")
        
        var allLocationData: [[String: Any]] = []
        let group = DispatchGroup()
        
        // 1. 운동과 직접 연결된 경로 데이터 (UUID 기반)
        print("iOS: 1단계 - 직접 연결된 경로 데이터 조회 시작")
        group.enter()
        getRouteForWorkoutWithExtendedData(startDate: startDate, endDate: endDate) { routeData in
            if let routeData = routeData {
                print("iOS: 1단계 완료 - 직접 연결된 경로 데이터: \(routeData.count)개 포인트")
                allLocationData.append(contentsOf: routeData)
            } else {
                print("iOS: 1단계 실패 - 직접 연결된 경로 데이터 없음")
            }
            group.leave()
        }
        
        // 2. 운동 시간 동안의 모든 GPS 데이터 (더 넓은 범위)
        print("iOS: 2단계 - 확장 GPS 데이터 조회 시작")
        group.enter()
        getExtendedLocationData(startDate: startDate, endDate: endDate) { extendedData in
            if let extendedData = extendedData {
                print("iOS: 2단계 완료 - 확장 GPS 데이터: \(extendedData.count)개 포인트")
                allLocationData.append(contentsOf: extendedData)
            } else {
                print("iOS: 2단계 실패 - 확장 GPS 데이터 없음")
            }
            group.leave()
        }
        
        // 3. 추가 GPS 데이터 수집 (운동 전후 30분)
        print("iOS: 3단계 - 추가 GPS 데이터 조회 시작")
        group.enter()
        let additionalStartDate = startDate.addingTimeInterval(-30 * 60) // 30분 전
        let additionalEndDate = endDate.addingTimeInterval(30 * 60) // 30분 후
        print("iOS: 추가 GPS 데이터 수집 - \(additionalStartDate) ~ \(additionalEndDate)")
        
        let additionalRouteType = HKSeriesType.workoutRoute()
        let additionalPredicate = HKQuery.predicateForSamples(withStart: additionalStartDate, end: additionalEndDate, options: [])
        
        let additionalQuery = HKSampleQuery(sampleType: additionalRouteType, predicate: additionalPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { [weak self] query, samples, error in
            if let error = error {
                print("iOS: 3단계 실패 - 추가 GPS 데이터 조회 오류 - \(error)")
                group.leave()
                return
            }
            
            guard let additionalRoutes = samples as? [HKWorkoutRoute], !additionalRoutes.isEmpty else {
                print("iOS: 3단계 실패 - 추가 GPS 데이터 없음")
                group.leave()
                return
            }
            
            print("iOS: 3단계 진행 - 추가 GPS 경로 \(additionalRoutes.count)개 발견")
            
            var additionalLocationData: [[String: Any]] = []
            let additionalGroup = DispatchGroup()
            
            for (index, route) in additionalRoutes.enumerated() {
                additionalGroup.enter()
                print("iOS: 추가 경로 \(index + 1) 처리 - 시작: \(route.startDate), 종료: \(route.endDate)")
                
                self?.getLocationsForRoute(route: route) { routeData in
                    if let routeData = routeData {
                        print("iOS: 추가 경로 \(index + 1)에서 \(routeData.count)개 포인트 수집")
                        additionalLocationData.append(contentsOf: routeData)
                    } else {
                        print("iOS: 추가 경로 \(index + 1)에서 데이터 없음")
                    }
                    additionalGroup.leave()
                }
            }
            
            additionalGroup.notify(queue: .main) {
                print("iOS: 3단계 완료 - 추가 경로 처리 완료 - 총 \(additionalLocationData.count)개 포인트")
                allLocationData.append(contentsOf: additionalLocationData)
                group.leave()
            }
        }
        
        healthStore.execute(additionalQuery)
        
        group.notify(queue: .main) {
            print("iOS: ===== 모든 단계 완료 - 데이터 통합 시작 =====")
            print("iOS: 수집된 총 GPS 데이터: \(allLocationData.count)개 포인트")
            
            if !allLocationData.isEmpty {
                // 중복 제거 및 시간순 정렬
                let uniqueData = self.removeDuplicateLocations(allLocationData)
                let sortedData = uniqueData.sorted { 
                    ($0["timestamp"] as? Double ?? 0) < ($1["timestamp"] as? Double ?? 0)
                }
                
                print("iOS: 최종 GPS 데이터: \(sortedData.count)개 포인트 (중복 제거 후)")
                
                // 첫 번째와 마지막 포인트 로그
                if let first = sortedData.first, let last = sortedData.last {
                    print("iOS: 첫 번째 포인트 - lat: \(first["latitude"]!), lng: \(first["longitude"]!)")
                    print("iOS: 마지막 포인트 - lat: \(last["latitude"]!), lng: \(last["longitude"]!)")
                }
                
                // GPS 데이터 품질 분석
                self.analyzeGPSDataQuality(sortedData)
                
                print("iOS: ===== getWorkoutRoute 메서드 완료 =====")
                completion(sortedData)
            } else {
                print("iOS: 모든 GPS 데이터 수집 실패")
                print("iOS: ===== getWorkoutRoute 메서드 실패 =====")
                completion(nil)
            }
        }
    }
    
    private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "requestHealthKitPermissions":
            self.requestHealthKitPermissions { success in
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
            
            print("iOS: MethodChannel getWorkoutRoute 호출됨 - \(startDate) ~ \(endDate)")
            
            // getExtendedLocationData를 직접 호출하여 더 많은 GPS 데이터 수집
            self.getExtendedLocationData(startDate: startDate, endDate: endDate) { extendedData in
                if let extendedData = extendedData {
                    print("iOS: MethodChannel - 확장 GPS 데이터: \(extendedData.count)개 포인트")
                    result(extendedData)
                } else {
                    print("iOS: MethodChannel - 확장 GPS 데이터 없음, 기본 경로 데이터 시도")
                    // 확장 데이터가 없으면 기본 경로 데이터 시도
                    self.getWorkoutRoute(startDate: startDate, endDate: endDate) { routeData in
                        if let routeData = routeData {
                            print("iOS: MethodChannel - 기본 경로 데이터: \(routeData.count)개 포인트")
                            result(routeData)
                        } else {
                            print("iOS: MethodChannel - 모든 GPS 데이터 수집 실패")
                            result(nil)
                        }
                    }
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
            
            self.getWorkoutRoute(startDate: startDate, endDate: endDate) { routesData in
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
    
    private func getRouteForWorkoutWithExtendedData(startDate: Date, endDate: Date, completion: @escaping ([[String: Any]]?) -> Void) {
        print("iOS: 운동과 직접 연결된 경로 데이터 조회 - \(startDate) ~ \(endDate)")
        
        // 해당 기간의 운동 데이터 조회
        let workoutPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        let workoutQuery = HKSampleQuery(sampleType: .workoutType(), predicate: workoutPredicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { [weak self] query, samples, error in
            if let error = error {
                print("iOS: 운동 조회 오류 - \(error)")
                completion(nil)
                return
            }
            
            guard let workouts = samples as? [HKWorkout], let workout = workouts.first else {
                print("iOS: 해당 기간에 운동 데이터 없음")
                completion(nil)
                return
            }
            
            print("iOS: 운동 발견 - 타입: \(workout.workoutActivityType.rawValue), 거리: \(workout.totalDistance?.doubleValue(for: .meter()) ?? 0)m")
            
            // 해당 운동의 경로 데이터 조회
            self?.getRouteForWorkout(workout: workout, completion: completion)
        }
        
        healthStore.execute(workoutQuery)
    }
    
    private func getRouteForWorkout(workout: HKWorkout, completion: @escaping ([[String: Any]]?) -> Void) {
        print("iOS: 운동 경로 조회 - \(workout.workoutActivityType.rawValue)")
        
        // 해당 운동과 직접 연결된 경로만 조회 (UUID 기반)
        let routePredicate = HKQuery.predicateForObjects(from: workout)
        let routeQuery = HKSampleQuery(sampleType: HKSeriesType.workoutRoute(), predicate: routePredicate, limit: 1, sortDescriptors: nil) { [weak self] query, samples, error in
            if let error = error {
                print("iOS: 경로 조회 오류 - \(error)")
                completion(nil)
                return
            }
            
            guard let routes = samples as? [HKWorkoutRoute], let route = routes.first else {
                print("iOS: 해당 운동의 경로 데이터 없음")
                completion(nil)
                return
            }
            
            print("iOS: 운동과 연결된 경로 발견 - 시작: \(route.startDate), 종료: \(route.endDate)")
            
            // 3. 경로의 위치 데이터 조회
            self?.getLocationsForRoute(route: route, completion: completion)
        }
        
        healthStore.execute(routeQuery)
    }
    
    private func getRouteForWorkout(startDate: Date, endDate: Date, completion: @escaping ([[String: Any]]?) -> Void) {
        print("iOS: 운동 경로 조회 - \(startDate) ~ \(endDate)")
        
        // 해당 기간의 운동 경로 데이터 조회
        let routePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        let routeQuery = HKSampleQuery(sampleType: HKSeriesType.workoutRoute(), predicate: routePredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] query, samples, error in
            if let error = error {
                print("iOS: 경로 조회 오류 - \(error)")
                completion(nil)
                return
            }
            
            guard let routes = samples as? [HKWorkoutRoute], !routes.isEmpty else {
                print("iOS: 해당 운동의 경로 데이터 없음")
                completion(nil)
                return
            }
            
            print("iOS: 운동과 연결된 경로 발견 - 시작: \(routes.first!.startDate), 종료: \(routes.first!.endDate)")
            
            // 3. 경로의 위치 데이터 조회
            self?.getLocationsForRoute(route: routes.first!, completion: completion)
        }
        
        healthStore.execute(routeQuery)
    }
    
    private func getLocationsForRoute(route: HKWorkoutRoute, completion: @escaping ([[String: Any]]?) -> Void) {
        print("iOS: 경로 위치 데이터 조회")
        
        // HKWorkoutRouteQuery로 실제 위치 데이터 접근
        let locationQuery = HKWorkoutRouteQuery(route: route) { [weak self] query, locationsOrNil, done, error in
            if let error = error {
                print("iOS: 위치 데이터 조회 오류 - \(error)")
                completion(nil)
                return
            }
            
            guard let locations = locationsOrNil, !locations.isEmpty else {
                if done {
                    print("iOS: 위치 데이터 없음")
                    completion(nil)
                }
                return
            }
            
            print("iOS: \(locations.count)개의 위치 데이터 수신 (완료: \(done))")
            
            // 위치 데이터를 Flutter에서 사용할 수 있는 형태로 변환 (더 상세한 정보 포함)
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
                print("iOS: 총 \(locationData.count)개의 GPS 포인트 완료")
                
                // GPS 데이터 품질 검증
                let validData = locationData.filter { location in
                    let lat = location["latitude"] as? Double ?? 0
                    let lng = location["longitude"] as? Double ?? 0
                    let accuracy = location["horizontalAccuracy"] as? Double ?? 0
                    
                    // 유효한 좌표 범위 및 정확도 체크
                    return lat != 0 && lng != 0 && 
                           lat >= -90 && lat <= 90 && 
                           lng >= -180 && lng <= 180 &&
                           accuracy > 0 && accuracy < 1000 // 1km 이하 정확도만 허용
                }
                
                print("iOS: 유효한 GPS 데이터: \(validData.count)/\(locationData.count)개")
                
                // 첫 번째와 마지막 포인트 로그
                if let first = validData.first, let last = validData.last {
                    print("iOS: 첫 번째 포인트 - lat: \(first["latitude"]!), lng: \(first["longitude"]!)")
                    print("iOS: 마지막 포인트 - lat: \(last["latitude"]!), lng: \(last["longitude"]!)")
                }
                
                DispatchQueue.main.async {
                    completion(validData)
                }
            }
        }
        
        healthStore.execute(locationQuery)
    }
    
    private func getExtendedLocationData(startDate: Date, endDate: Date, completion: @escaping ([[String: Any]]?) -> Void) {
        print("iOS: ===== getExtendedLocationData 메서드 시작 =====")
        print("iOS: 확장 GPS 데이터 조회 - \(startDate) ~ \(endDate)")
        
        // 1. 운동 시간 내의 모든 GPS 데이터 수집 (더 넓은 범위)
        let extendedStartDate = startDate.addingTimeInterval(-15 * 60) // 15분 전
        let extendedEndDate = endDate.addingTimeInterval(15 * 60) // 15분 후
        
        print("iOS: 확장된 GPS 수집 시간 범위 - \(extendedStartDate) ~ \(extendedEndDate)")
        
        // 2. HKWorkoutRoute를 사용하여 더 많은 GPS 데이터 수집
        let routeType = HKSeriesType.workoutRoute()
        let routePredicate = HKQuery.predicateForSamples(withStart: extendedStartDate, end: extendedEndDate, options: [])
        
        print("iOS: HKWorkoutRoute 쿼리 실행 시작...")
        
        // 3. 더 상세한 GPS 데이터 수집 (초당 또는 5초마다)
        let routeQuery = HKSampleQuery(sampleType: routeType, predicate: routePredicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { [weak self] query, samples, error in
            print("iOS: HKWorkoutRoute 쿼리 콜백 실행됨")
            
            if let error = error {
                print("iOS: GPS 데이터 조회 오류 - \(error)")
                print("iOS: ===== getExtendedLocationData 메서드 실패 =====")
                completion(nil)
                return
            }
            
            guard let routes = samples as? [HKWorkoutRoute], !routes.isEmpty else {
                print("iOS: GPS 데이터 없음")
                print("iOS: ===== getExtendedLocationData 메서드 실패 =====")
                completion(nil)
                return
            }
            
            print("iOS: GPS 경로 \(routes.count)개 발견")
            
            // 4. 모든 경로에서 GPS 데이터 수집
            var allLocationData: [[String: Any]] = []
            let group = DispatchGroup()
            
            for (index, route) in routes.enumerated() {
                group.enter()
                print("iOS: 경로 \(index + 1) 처리 - 시작: \(route.startDate), 종료: \(route.endDate)")
                
                self?.getLocationsForRoute(route: route) { routeData in
                    if let routeData = routeData {
                        print("iOS: 경로 \(index + 1)에서 \(routeData.count)개 포인트 수집")
                        allLocationData.append(contentsOf: routeData)
                    } else {
                        print("iOS: 경로 \(index + 1)에서 데이터 없음")
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                print("iOS: 모든 경로 처리 완료 - 총 \(allLocationData.count)개 포인트")
                
                // 5. GPS 데이터 품질 검증 및 정렬
                let validData = allLocationData.filter { location in
                    let lat = location["latitude"] as? Double ?? 0
                    let lng = location["longitude"] as? Double ?? 0
                    let accuracy = location["horizontalAccuracy"] as? Double ?? 0
                    
                    // 유효한 좌표 범위 및 정확도 체크
                    return lat != 0 && lng != 0 && 
                           lat >= -90 && lat <= 90 && 
                           lng >= -180 && lng <= 180 &&
                           accuracy > 0 && accuracy < 1000 // 1km 이하 정확도만 허용
                }
                
                let sortedData = validData.sorted { 
                    ($0["timestamp"] as? Double ?? 0) < ($1["timestamp"] as? Double ?? 0)
                }
                
                print("iOS: 유효한 GPS 데이터: \(sortedData.count)/\(allLocationData.count)개")
                
                // 6. GPS 데이터 품질 분석
                if !sortedData.isEmpty {
                    self?.analyzeGPSDataQuality(sortedData)
                    
                    // 첫 번째와 마지막 포인트 로그
                    if let first = sortedData.first, let last = sortedData.last {
                        print("iOS: 첫 번째 포인트 - lat: \(first["latitude"]!), lng: \(first["longitude"]!)")
                        print("iOS: 마지막 포인트 - lat: \(last["latitude"]!), lng: \(last["longitude"]!)")
                    }
                    
                    // GPS 데이터 범위 분석
                    let latitudes = sortedData.map { $0["latitude"] as? Double ?? 0 }
                    let longitudes = sortedData.map { $0["longitude"] as? Double ?? 0 }
                    
                    if let minLat = latitudes.min(), let maxLat = latitudes.max(),
                       let minLng = longitudes.min(), let maxLng = longitudes.max() {
                        let latRange = maxLat - minLat
                        let lngRange = maxLng - minLng
                        print("iOS: GPS 데이터 범위 - 위도: \(latRange)도, 경도: \(lngRange)도")
                        print("iOS: GPS 데이터 범위 - 위도: \(latRange * 111000)m, 경도: \(lngRange * 88900)m")
                    }
                }
                
                print("iOS: ===== getExtendedLocationData 메서드 완료 =====")
                completion(sortedData)
            }
        }
        
        print("iOS: healthStore.execute(routeQuery) 호출...")
        healthStore.execute(routeQuery)
    }
    
    private func removeDuplicateLocations(_ locations: [[String: Any]]) -> [[String: Any]] {
        var uniqueLocations: [[String: Any]] = []
        var seenCoordinates: Set<String> = []
        
        for location in locations {
            let lat = location["latitude"] as? Double ?? 0
            let lng = location["longitude"] as? Double ?? 0
            
            // 좌표를 문자열로 변환하여 중복 체크 (약간의 오차 허용)
            let coordinateKey = String(format: "%.6f,%.6f", lat, lng)
            
            if !seenCoordinates.contains(coordinateKey) {
                seenCoordinates.insert(coordinateKey)
                uniqueLocations.append(location)
            }
        }
        
        return uniqueLocations
    }
    
    private func analyzeGPSDataQuality(_ locations: [[String: Any]]) {
        print("iOS: GPS 데이터 품질 분석 시작")
        
        guard locations.count >= 2 else {
            print("iOS: GPS 포인트가 부족합니다 (최소 2개 필요)")
            return
        }
        
        // 시간 간격 분석
        var timeIntervals: [TimeInterval] = []
        for i in 1..<locations.count {
            let prevTimestamp = locations[i-1]["timestamp"] as? Double ?? 0
            let currTimestamp = locations[i]["timestamp"] as? Double ?? 0
            let interval = (currTimestamp - prevTimestamp) / 1000 // 밀리초를 초로 변환
            timeIntervals.append(interval)
        }
        
        let avgInterval = timeIntervals.reduce(0, +) / Double(timeIntervals.count)
        print("iOS: 평균 GPS 수집 간격: \(avgInterval)초")
        
        // 정확도 분석
        let accuracies = locations.compactMap { $0["horizontalAccuracy"] as? Double }
        if !accuracies.isEmpty {
            let avgAccuracy = accuracies.reduce(0, +) / Double(accuracies.count)
            let minAccuracy = accuracies.min() ?? 0
            let maxAccuracy = accuracies.max() ?? 0
            print("iOS: GPS 정확도 - 평균: \(avgAccuracy)m, 최소: \(minAccuracy)m, 최대: \(maxAccuracy)m")
        }
        
        // 속도 분석
        let speeds = locations.compactMap { $0["speed"] as? Double }
        if !speeds.isEmpty {
            let avgSpeed = speeds.reduce(0, +) / Double(speeds.count)
            let maxSpeed = speeds.max() ?? 0
            print("iOS: 속도 - 평균: \(avgSpeed)m/s, 최대: \(maxSpeed)m/s")
        }
        
        print("iOS: GPS 데이터 품질 분석 완료")
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


