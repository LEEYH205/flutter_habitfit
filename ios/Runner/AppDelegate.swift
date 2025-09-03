import Flutter
import UIKit
import HealthKit
import CoreLocation

@main
@objc class AppDelegate: FlutterAppDelegate {

  private let healthStore = HKHealthStore()
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // HealthKit 경로 플러그인 등록
    let controller = window?.rootViewController as! FlutterViewController
    let healthKitRouteChannel = FlutterMethodChannel(name: "healthkit_route_channel", binaryMessenger: controller.binaryMessenger)
    
    // 고급 러닝 메트릭을 위한 새로운 채널
    let runningMetricsChannel = FlutterMethodChannel(name: "hk_running", binaryMessenger: controller.binaryMessenger)
    

    
    // 메서드 호출 처리
    healthKitRouteChannel.setMethodCallHandler { [weak self] call, result in
      self?.handleMethodCall(call: call, result: result)
    }
    
    // 고급 러닝 메트릭 메서드 호출 처리
    runningMetricsChannel.setMethodCallHandler { [weak self] call, result in
      self?.handleRunningMetricsCall(call: call, result: result)
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
      // HealthKit 권한 요청
      guard HKHealthStore.isHealthDataAvailable() else {
        result(false)
        return
      }
      
      let typesToRead: Set<HKObjectType> = [
        HKObjectType.workoutType(),
        HKSeriesType.workoutRoute()
      ]
      
      self.healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
        DispatchQueue.main.async {
          result(success)
        }
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
      let workoutId = args["workoutId"] as? String
      
      print("iOS: MethodChannel getWorkoutRoute 호출됨 - \(startDate) ~ \(endDate)")
      print("iOS: 운동 ID: \(workoutId ?? "없음")")
      
      print("iOS: ===== MethodChannel getWorkoutRoute 호출됨 =====")
      print("iOS: 시작 시간: \(startDate)")
      print("iOS: 종료 시간: \(endDate)")
      print("iOS: 운동 ID: \(workoutId ?? "없음")")
      print("iOS: collectGPSDataDirectly 메서드 호출 시작...")
      
      // 직접 GPS 데이터 수집 (HealthKitRouteManager 우회)
      self.collectGPSDataDirectly(startDate: startDate, endDate: endDate, workoutId: workoutId) { gpsData in
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

      print("iOS: getWorkoutRoutes 호출됨 - \(startDate) ~ \(endDate)")

      // 직접 HealthKit에서 경로 데이터 수집
      self.getWorkoutRoutesDirect(startDate: startDate, endDate: endDate) { routes in
        if let routes = routes {
          print("iOS: getWorkoutRoutes 완료: \(routes.count)개 경로")
          result(routes)
        } else {
          print("iOS: getWorkoutRoutes 실패")
          result(nil)
        }
      }
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  // MARK: - 고급 러닝 메트릭 처리
  private func handleRunningMetricsCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestPermissions":
      requestRunningPermissions(result: result)
    case "getRunningSpeed":
      guard let args = call.arguments as? [String: Any],
            let fromMs = args["from"] as? Int64,
            let toMs = args["to"] as? Int64 else {
        result(FlutterError(code: "ARG", message: "bad args", details: nil))
        return
      }
      queryQuantity(typeId: .runningSpeed,
                   unit: HKUnit.meter().unitDivided(by: .second()),
                   from: Date(timeIntervalSince1970: TimeInterval(fromMs) / 1000),
                   to: Date(timeIntervalSince1970: TimeInterval(toMs) / 1000),
                   result: result)
    case "getRunningStrideLength":
      guard let args = call.arguments as? [String: Any],
            let fromMs = args["from"] as? Int64,
            let toMs = args["to"] as? Int64 else {
        result(FlutterError(code: "ARG", message: "bad args", details: nil))
        return
      }
      queryQuantity(typeId: .runningStrideLength,
                   unit: .meter(),
                   from: Date(timeIntervalSince1970: TimeInterval(fromMs) / 1000),
                   to: Date(timeIntervalSince1970: TimeInterval(toMs) / 1000),
                   result: result)
    case "getRunningPower":
      guard let args = call.arguments as? [String: Any],
            let fromMs = args["from"] as? Int64,
            let toMs = args["to"] as? Int64 else {
        result(FlutterError(code: "ARG", message: "bad args", details: nil))
        return
      }
      queryQuantity(typeId: .runningPower,
                   unit: .watt(),
                   from: Date(timeIntervalSince1970: TimeInterval(fromMs) / 1000),
                   to: Date(timeIntervalSince1970: TimeInterval(toMs) / 1000),
                   result: result)
    case "getRunningVerticalOscillation":
      guard let args = call.arguments as? [String: Any],
            let fromMs = args["from"] as? Int64,
            let toMs = args["to"] as? Int64 else {
        result(FlutterError(code: "ARG", message: "bad args", details: nil))
        return
      }
      queryQuantity(typeId: .runningVerticalOscillation,
                   unit: HKUnit.meter(), // 기본 미터 단위 사용
                   from: Date(timeIntervalSince1970: TimeInterval(fromMs) / 1000),
                   to: Date(timeIntervalSince1970: TimeInterval(toMs) / 1000),
                   result: result)
    case "getRunningGroundContactTime":
      guard let args = call.arguments as? [String: Any],
            let fromMs = args["from"] as? Int64,
            let toMs = args["to"] as? Int64 else {
        result(FlutterError(code: "ARG", message: "bad args", details: nil))
        return
      }
      queryQuantity(typeId: .runningGroundContactTime,
                   unit: HKUnit.second(), // 기본 초 단위 사용
                   from: Date(timeIntervalSince1970: TimeInterval(fromMs) / 1000),
                   to: Date(timeIntervalSince1970: TimeInterval(toMs) / 1000),
                   result: result)
    case "getWorkoutRoutes":
      guard let args = call.arguments as? [String: Any],
            let fromMs = args["from"] as? Int64,
            let toMs = args["to"] as? Int64 else {
        result(FlutterError(code: "ARG", message: "bad args", details: nil))
        return
      }

      let startDate = Date(timeIntervalSince1970: TimeInterval(fromMs) / 1000)
      let endDate = Date(timeIntervalSince1970: TimeInterval(toMs) / 1000)

      print("iOS: runningMetrics getWorkoutRoutes 호출됨 - \(startDate) ~ \(endDate)")

      // 직접 HealthKit에서 경로 데이터 수집
      self.getWorkoutRoutesDirect(startDate: startDate, endDate: endDate) { routes in
        if let routes = routes {
          print("iOS: runningMetrics getWorkoutRoutes 완료: \(routes.count)개 경로")
          result(routes)
        } else {
          print("iOS: runningMetrics getWorkoutRoutes 실패")
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
    return removeDuplicateGPSData(locations)
  }
  
  // MARK: - 고급 러닝 메트릭 헬퍼 메서드들
  private func requestRunningPermissions(result: @escaping FlutterResult) {
    var readTypes = Set<HKObjectType>()
    
    // 러닝 고급 지표
    let qtyIds: [HKQuantityTypeIdentifier] = [
      .runningStrideLength, .runningSpeed, .runningPower,
      .runningVerticalOscillation, .runningGroundContactTime
    ]
    
    qtyIds.forEach { if let t = HKObjectType.quantityType(forIdentifier: $0) { readTypes.insert(t) } }
    
    let route = HKSeriesType.workoutRoute()
    readTypes.insert(route)
    readTypes.insert(HKObjectType.workoutType())
    
    healthStore.requestAuthorization(toShare: nil, read: readTypes) { ok, err in
      if let err = err {
        result(FlutterError(code: "AUTH", message: err.localizedDescription, details: nil))
        return
      }
      result(ok)
    }
  }
  
  private func queryQuantity(typeId: HKQuantityTypeIdentifier, unit: HKUnit,
                           from: Date, to: Date, result: @escaping FlutterResult) {
    guard let type = HKObjectType.quantityType(forIdentifier: typeId) else {
      result(FlutterError(code: "TYPE", message: "unsupported type", details: nil))
      return
    }
    
    let pred = HKQuery.predicateForSamples(withStart: from, end: to, options: .strictStartDate)
    let q = HKSampleQuery(sampleType: type, predicate: pred, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
      if let error = error {
        result(FlutterError(code: "QUERY", message: error.localizedDescription, details: nil))
        return
      }
      
      let rows: [[String: Any]] = (samples as? [HKQuantitySample] ?? []).map {
        ["start": $0.startDate.timeIntervalSince1970 * 1000,
         "end": $0.endDate.timeIntervalSince1970 * 1000,
         "value": $0.quantity.doubleValue(for: unit)]
      }
      result(rows)
    }
    healthStore.execute(q)
  }
  
  private func queryRoutes(from: Date, to: Date, result: @escaping FlutterResult) {
    // 1) 해당 기간의 Workout 조회
    let pred = HKQuery.predicateForSamples(withStart: from, end: to, options: .strictStartDate)
    let wq = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: pred, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] _, samples, err in
      if let err = err {
        result(FlutterError(code: "WQUERY", message: err.localizedDescription, details: nil))
        return
      }
      
      guard let self = self else { return }
      let workouts = (samples as? [HKWorkout] ?? [])
      var allPoints: [[String: Any]] = []
      
      let group = DispatchGroup()
      for w in workouts {
        group.enter()
        let routePred = HKQuery.predicateForObjects(from: w)
        let rt = HKSeriesType.workoutRoute()
        let rq = HKAnchoredObjectQuery(type: rt, predicate: routePred, anchor: nil, limit: HKObjectQueryNoLimit) { _, objects, _, _, e in
          if let e = e {
            print("route err:", e)
            group.leave()
            return
          }
          
          guard let routes = objects as? [HKWorkoutRoute] else {
            group.leave()
            return
          }
          
          let locGroup = DispatchGroup()
          for r in routes {
            locGroup.enter()
            var acc: [[String: Any]] = []
            let lq = HKWorkoutRouteQuery(route: r) { _, locsOrNil, done, err in
              if let err = err { print("loc err:", err) }
              if let locs = locsOrNil {
                acc += locs.map { ["lat": $0.coordinate.latitude, "lng": $0.coordinate.longitude, "alt": $0.altitude, "ts": $0.timestamp.timeIntervalSince1970 * 1000] }
              }
              if done {
                allPoints += acc
                locGroup.leave()
              }
            }
            self.healthStore.execute(lq)
          }
          locGroup.notify(queue: .main) { group.leave() }
        }
        self.healthStore.execute(rq)
      }
      group.notify(queue: .main) { result(allPoints) }
    }
    healthStore.execute(wq)
  }
  
  // MARK: - GPS 데이터 수집 메서드들

  private func getWorkoutRoutesDirect(startDate: Date, endDate: Date, completion: @escaping ([[String: Any]]?) -> Void) {
    print("iOS: ===== getWorkoutRoutesDirect 시작 =====")
    print("iOS: 기간: \(startDate) ~ \(endDate)")

    // 1. 해당 기간의 운동 데이터 조회
    let workoutPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
    let workoutQuery = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: workoutPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] _, samples, error in
      if let error = error {
        print("iOS: 운동 조회 오류: \(error)")
        completion(nil)
        return
      }

      guard let workouts = samples as? [HKWorkout], !workouts.isEmpty else {
        print("iOS: 해당 기간에 운동 데이터 없음")
        completion(nil)
        return
      }

      print("iOS: \(workouts.count)개의 운동 발견")

      var allRoutes: [[String: Any]] = []
      let group = DispatchGroup()

      for workout in workouts {
        group.enter()
        self?.getRouteForWorkoutDirect(workout: workout) { routeData in
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
        print("iOS: getWorkoutRoutesDirect 완료: \(allRoutes.count)개 경로")
        completion(allRoutes)
      }
    }

    healthStore.execute(workoutQuery)
  }

  private func getRouteForWorkoutDirect(workout: HKWorkout, completion: @escaping ([[String: Any]]?) -> Void) {
    print("iOS: 운동 경로 조회 - \(workout.uuid)")

    let routeQuery = HKAnchoredObjectQuery(type: HKSeriesType.workoutRoute(), predicate: HKQuery.predicateForObjects(from: workout), anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] query, samples, _, _, error in
      if let error = error {
        print("iOS: 경로 쿼리 오류: \(error)")
        completion(nil)
        return
      }

      guard let routes = samples as? [HKWorkoutRoute], let route = routes.first else {
        print("iOS: 해당 운동에 경로 데이터 없음")
        completion(nil)
        return
      }

      self?.getLocationsForRouteDirect(route: route, completion: completion)
    }

    healthStore.execute(routeQuery)
  }

  private func getLocationsForRouteDirect(route: HKWorkoutRoute, completion: @escaping ([[String: Any]]?) -> Void) {
    print("iOS: 경로 위치 데이터 조회")

    var allLocations: [CLLocation] = []
    let routeQuery = HKWorkoutRouteQuery(route: route) { [weak self] query, locations, done, error in
      if let error = error {
        print("iOS: 위치 조회 오류: \(error)")
        completion(nil)
        return
      }

      if let locations = locations {
        allLocations.append(contentsOf: locations)
      }

      if done {
        print("iOS: 경로에서 \(allLocations.count)개 위치 수집 완료")

        let locationData = allLocations.map { location -> [String: Any] in
          return [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "altitude": location.altitude,
            "timestamp": location.timestamp.timeIntervalSince1970 * 1000,
            "speed": location.speed >= 0 ? location.speed : 0,
            "course": location.course >= 0 ? location.course : 0,
            "horizontalAccuracy": location.horizontalAccuracy,
            "verticalAccuracy": location.verticalAccuracy
          ]
        }

        completion(locationData)
      }
    }

    healthStore.execute(routeQuery)
  }

  private func collectGPSDataDirectly(startDate: Date, endDate: Date, workoutId: String?, completion: @escaping ([[String: Any]]?) -> Void) {
    print("iOS: ===== collectGPSDataDirectly 메서드 시작 =====")
    print("iOS: 직접 GPS 데이터 수집 시작 - \(startDate) ~ \(endDate)")
    print("iOS: 운동 ID: \(workoutId ?? "없음")")
    print("iOS: 이 로그가 보이면 iOS 네이티브 코드가 실행된 것입니다!")
    
    var allGPSData: [[String: Any]] = []
    
    if let workoutId = workoutId {
      print("iOS: 운동 ID 기반 경로 조회 시작 - \(workoutId)")
      
      if let uuid = UUID(uuidString: workoutId) {
        print("iOS: UUID 형식 운동 ID로 인식됨: \(uuid)")
        
        // UUID 기반 운동 조회
        let workoutQuery = HKSampleQuery(sampleType: .workoutType(), predicate: HKQuery.predicateForObjects(with: Set([uuid])), limit: 1, sortDescriptors: nil) { [weak self] (query, samples, error) in
          if let error = error {
            print("iOS: UUID 기반 운동 조회 오류: \(error)")
            self?.collectGPSDataByTimeRange(startDate: startDate, endDate: endDate, completion: completion)
            return
          }
          
          guard let workouts = samples as? [HKWorkout], !workouts.isEmpty else {
            print("iOS: UUID로 운동을 찾을 수 없음: \(uuid)")
            self?.collectGPSDataByTimeRange(startDate: startDate, endDate: endDate, completion: completion)
            return
          }
          
          let workout = workouts[0]
          print("iOS: UUID 기반 운동 발견: \(workout.uuid), 거리: \(workout.totalDistance?.doubleValue(for: .meter()) ?? 0)m")
          
          // 이 운동의 경로와 위치 데이터 모두 수집
          self?.collectComprehensiveGPSData(for: workout, completion: completion)
        }
        
        healthStore.execute(workoutQuery)
        return
      } else {
        print("iOS: 운동 ID가 UUID 형식이 아님: \(workoutId)")
        print("iOS: 숫자 ID 또는 다른 형식으로 인식, 시간 기반 쿼리로 진행")
        
        // Flutter에서 전달한 커스텀 UUID 형식 파싱 시도 (timestamp_source_type)
        if workoutId.contains("_") {
          let components = workoutId.components(separatedBy: "_")
          if components.count >= 3 {
            let timestampStr = components[0]
            let source = components[1]
            let type = components[2]
            print("iOS: 커스텀 UUID 형식 파싱: timestamp=\(timestampStr), source=\(source), type=\(type)")
            
            // 타임스탬프를 사용하여 해당 시간대의 운동 찾기
            if let timestamp = Double(timestampStr) {
              let workoutDate = Date(timeIntervalSince1970: timestamp / 1000)
              let timeWindow = 60.0 // 1분 전후
              let startSearch = workoutDate.addingTimeInterval(-timeWindow)
              let endSearch = workoutDate.addingTimeInterval(timeWindow)
              
              print("iOS: 커스텀 UUID 기반 운동 검색: \(startSearch) ~ \(endSearch)")
              
              let workoutPredicate = HKQuery.predicateForSamples(withStart: startSearch, end: endSearch, options: [])
              let workoutQuery = HKSampleQuery(sampleType: .workoutType(), predicate: workoutPredicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { [weak self] (query, samples, error) in
                if let error = error {
                  print("iOS: 커스텀 UUID 기반 운동 조회 오류: \(error)")
                  self?.collectGPSDataByTimeRange(startDate: startDate, endDate: endDate, completion: completion)
                  return
                }
                
                guard let workouts = samples as? [HKWorkout], let workout = workouts.first else {
                  print("iOS: 커스텀 UUID 기반 운동을 찾을 수 없음: \(workoutId)")
                  self?.collectGPSDataByTimeRange(startDate: startDate, endDate: endDate, completion: completion)
                  return
                }
                
                print("iOS: 커스텀 UUID 기반 운동 발견: \(workout.uuid)")
                self?.collectComprehensiveGPSData(for: workout, completion: completion)
              }
              
              self.healthStore.execute(workoutQuery)
              return
            }
          }
        }
      }
    }
    
    print("iOS: 운동 ID 없음, 시간 기반 경로 조회 시작")
    collectGPSDataByTimeRange(startDate: startDate, endDate: endDate, completion: completion)
  }
  
  private func collectComprehensiveGPSData(for workout: HKWorkout, completion: @escaping ([[String: Any]]?) -> Void) {
    print("iOS: ===== 종합 GPS 데이터 수집 시작 =====")
    print("iOS: 운동: \(workout.uuid), 시작: \(workout.startDate), 종료: \(workout.endDate)")
    
    var allGPSData: [[String: Any]] = []
    let group = DispatchGroup()
    
    // 1. HKWorkoutRoute에서 경로 데이터 수집
    group.enter()
    collectRouteData(for: workout) { routeData in
      if let routeData = routeData {
        print("iOS: 경로 데이터 수집 완료: \(routeData.count)개 포인트")
        allGPSData.append(contentsOf: routeData)
      } else {
        print("iOS: 경로 데이터 없음")
      }
      group.leave()
    }
    
    // 2. HKLocationSample에서 직접 위치 데이터 수집
    group.enter()
    collectLocationSamples(for: workout) { locationData in
      if let locationData = locationData {
        print("iOS: 위치 샘플 데이터 수집 완료: \(locationData.count)개 포인트")
        allGPSData.append(contentsOf: locationData)
      } else {
        print("iOS: 위치 샘플 데이터 없음")
      }
      group.leave()
    }
    
    group.notify(queue: .main) {
      print("iOS: 모든 GPS 데이터 수집 완료")
      
      if allGPSData.isEmpty {
        print("iOS: 수집된 GPS 데이터가 없음")
        completion(nil)
        return
      }
      
      // 중복 제거 및 정렬
      let uniqueData = self.removeDuplicateGPSData(allGPSData)
      let sortedData = uniqueData.sorted { (a, b) -> Bool in
        let timestampA = a["timestamp"] as? Double ?? 0
        let timestampB = b["timestamp"] as? Double ?? 0
        return timestampA < timestampB
      }
      
      print("iOS: 최종 GPS 데이터: \(sortedData.count)개 포인트 (중복 제거 후)")
      if let first = sortedData.first, let last = sortedData.last {
        let firstLat = first["latitude"] as? Double ?? 0
        let firstLng = first["longitude"] as? Double ?? 0
        let lastLat = last["latitude"] as? Double ?? 0
        let lastLng = last["longitude"] as? Double ?? 0
        print("iOS: 첫 번째 포인트 - lat: \(firstLat), lng: \(firstLng)")
        print("iOS: 마지막 포인트 - lat: \(lastLat), lng: \(lastLng)")
      }
      
      print("iOS: ===== collectGPSDataDirectly 메서드 완료 =====")
      print("iOS: Flutter로 전송할 데이터: \(sortedData.count)개 포인트")
      print("iOS: 전송 데이터 샘플:")
      for (index, point) in sortedData.prefix(3).enumerated() {
        let lat = point["latitude"] as? Double ?? 0
        let lng = point["longitude"] as? Double ?? 0
        let timestamp = point["timestamp"] as? Double ?? 0
        print("iOS:   포인트 \(index + 1): lat=\(lat), lng=\(lng), timestamp=\(timestamp)")
      }
      
      completion(sortedData)
    }
  }
  
  private func collectRouteData(for workout: HKWorkout, completion: @escaping ([[String: Any]]?) -> Void) {
    print("iOS: 1단계 - 운동 데이터 조회 및 UUID 기반 경로 연결 시작")
    
    let workoutQuery = HKSampleQuery(sampleType: .workoutType(), predicate: HKQuery.predicateForObjects(with: Set([workout.uuid])), limit: 1, sortDescriptors: nil) { [weak self] (query, samples, error) in
      if let error = error {
        print("iOS: 운동 데이터 쿼리 오류: \(error)")
        completion(nil)
        return
      }
      
      guard let workouts = samples as? [HKWorkout], !workouts.isEmpty else {
        print("iOS: 운동 데이터를 찾을 수 없음")
        completion(nil)
        return
      }
      
      print("iOS: \(workouts.count)개의 운동 발견")
      
      var allRouteData: [[String: Any]] = []
      let workoutGroup = DispatchGroup()
      
      for (index, workout) in workouts.enumerated() {
        workoutGroup.enter()
        
        print("iOS: 운동 \(index + 1) 처리 - UUID: \(workout.uuid), 타입: \(workout.workoutActivityType.rawValue), 거리: \(workout.totalDistance?.doubleValue(for: .meter()) ?? 0)m")
        
        // UUID 기반 운동 경로 조회
        print("iOS: UUID 기반 운동 경로 조회 - \(workout.uuid)")
        
                 let routeQuery = HKAnchoredObjectQuery(type: HKSeriesType.workoutRoute(), predicate: HKQuery.predicateForObjects(from: workout), anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] (query, samples, deletedObjects, anchor, error) in
          if let error = error {
            print("iOS: 경로 쿼리 오류: \(error)")
            workoutGroup.leave()
            return
          }
          
          guard let routes = samples as? [HKWorkoutRoute], !routes.isEmpty else {
            print("iOS: 운동에 연결된 경로가 없음")
            workoutGroup.leave()
            return
          }
          
          print("iOS: 직접 연결된 경로 발견 - 시작: \(routes[0].startDate), 종료: \(routes[0].endDate)")
          
          // 경로 위치 데이터 조회
          print("iOS: 경로 위치 데이터 조회")
          self?.getLocationsForRouteWithHighPrecision(route: routes[0]) { routeData in
            if let routeData = routeData {
              print("iOS: 경로에서 \(routeData.count)개 포인트 수집 완료")
              allRouteData.append(contentsOf: routeData)
            }
            workoutGroup.leave()
          }
        }
        
        self?.healthStore.execute(routeQuery)
      }
      
      workoutGroup.notify(queue: .main) {
        print("iOS: 모든 운동의 UUID 기반 경로 처리 완료 - 총 \(allRouteData.count)개 포인트")
        completion(allRouteData)
      }
    }
    
    healthStore.execute(workoutQuery)
  }
  
  private func collectLocationSamples(for workout: HKWorkout, completion: @escaping ([[String: Any]]?) -> Void) {
    print("iOS: 2단계 - HKLocationSample 직접 조회 시작")
    
    // 운동 시간 범위 내의 모든 위치 샘플 조회
    let locationPredicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
    
         let locationQuery = HKSampleQuery(sampleType: .quantityType(forIdentifier: .distanceWalkingRunning)!, predicate: locationPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { [weak self] (query, samples, error) in
      if let error = error {
        print("iOS: 위치 샘플 쿼리 오류: \(error)")
        completion(nil)
        return
      }
      
             guard let locationSamples = samples as? [HKQuantitySample], !locationSamples.isEmpty else {
        print("iOS: 위치 샘플 데이터 없음")
        completion(nil)
        return
      }
      
      print("iOS: 위치 샘플 \(locationSamples.count)개 발견")
      
      var locationData: [[String: Any]] = []
      
             for locationSample in locationSamples {
         // HKQuantitySample에서 위치 데이터 추출 (메타데이터에서)
         guard let metadata = locationSample.metadata,
               let latitude = metadata["HKLocationLatitude"] as? Double,
               let longitude = metadata["HKLocationLongitude"] as? Double else { continue }
         
         // 위치 데이터가 있는 경우에만 처리
         let location = CLLocation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: locationSample.startDate)
        
        // 정확도 필터링 주석처리 - 모든 GPS 데이터 수집
        // if location.horizontalAccuracy > 0 && location.horizontalAccuracy < 500 {
        let point: [String: Any] = [
          "timestamp": locationSample.startDate.timeIntervalSince1970,
          "latitude": location.coordinate.latitude,
          "longitude": location.coordinate.longitude,
          "altitude": location.altitude,
          "horizontalAccuracy": location.horizontalAccuracy,
          "verticalAccuracy": location.verticalAccuracy,
          "course": location.course,
          "speed": location.speed
        ]
        locationData.append(point)
        // }
      }
      
      print("iOS: 필터링된 위치 샘플: \(locationData.count)개 (정확도 필터 없음 - 모든 데이터 수집)")
      completion(locationData)
    }
    
    healthStore.execute(locationQuery)
  }
  
  private func removeDuplicateGPSData(_ data: [[String: Any]]) -> [[String: Any]] {
    var uniqueData: [[String: Any]] = []
    var seenCoordinates: Set<String> = []
    
    for point in data {
      let lat = point["latitude"] as? Double ?? 0
      let lng = point["longitude"] as? Double ?? 0
      
      // 좌표를 문자열로 변환하여 중복 체크 (소수점 6자리까지)
      let coordinateKey = String(format: "%.6f,%.6f", lat, lng)
      
      if !seenCoordinates.contains(coordinateKey) {
        seenCoordinates.insert(coordinateKey)
        uniqueData.append(point)
      }
    }
    
    print("iOS: 중복 제거: \(data.count)개 -> \(uniqueData.count)개")
    return uniqueData
  }
  
  // MARK: - 시간 기반 GPS 데이터 수집 (UUID 기반 실패 시)
  private func collectGPSDataByTimeRange(startDate: Date, endDate: Date, completion: @escaping ([[String: Any]]?) -> Void) {
    print("iOS: 시간 기반 GPS 데이터 수집 시작 - \(startDate) ~ \(endDate)")
    
    // 시간 범위를 확장하여 더 많은 GPS 데이터 수집
    let extendedStartDate = startDate.addingTimeInterval(-60 * 60) // 1시간 전
    let extendedEndDate = endDate.addingTimeInterval(60 * 60) // 1시간 후
    
    print("iOS: 확장된 시간 범위: \(extendedStartDate) ~ \(extendedEndDate)")
    
    // 1. 해당 기간의 운동 데이터 조회
    let workoutPredicate = HKQuery.predicateForSamples(withStart: extendedStartDate, end: extendedEndDate, options: [])
    let workoutQuery = HKSampleQuery(sampleType: .workoutType(), predicate: workoutPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { [weak self] (query, samples, error) in
      if let error = error {
        print("iOS: 시간 기반 운동 데이터 조회 오류: \(error)")
        completion(nil)
        return
      }
      
      guard let workouts = samples as? [HKWorkout], !workouts.isEmpty else {
        print("iOS: 해당 기간에 운동 데이터 없음")
        completion(nil)
        return
      }
      
      print("iOS: 시간 기반으로 \(workouts.count)개의 운동 발견")
      
      // 2. 각 운동에 대해 종합 GPS 데이터 수집
      var allGPSData: [[String: Any]] = []
      let group = DispatchGroup()
      
      for (index, workout) in workouts.enumerated() {
        group.enter()
        
        print("iOS: 시간 기반 운동 \(index + 1) 처리 - UUID: \(workout.uuid), 타입: \(workout.workoutActivityType.rawValue), 거리: \(workout.totalDistance?.doubleValue(for: .meter()) ?? 0)m")
        
        self?.collectComprehensiveGPSData(for: workout) { workoutGPSData in
          if let workoutGPSData = workoutGPSData {
            print("iOS: 운동 \(index + 1)에서 \(workoutGPSData.count)개 GPS 포인트 수집")
            allGPSData.append(contentsOf: workoutGPSData)
          } else {
            print("iOS: 운동 \(index + 1)에서 GPS 데이터 없음")
          }
          group.leave()
        }
      }
      
      group.notify(queue: .main) {
        print("iOS: 모든 운동의 시간 기반 GPS 데이터 수집 완료")
        
        if allGPSData.isEmpty {
          print("iOS: 시간 기반으로도 GPS 데이터를 찾을 수 없음")
          completion(nil)
          return
        }
        
        // 중복 제거 및 정렬
        let uniqueData = self?.removeDuplicateGPSData(allGPSData) ?? []
        let sortedData = uniqueData.sorted { (a, b) -> Bool in
          let timestampA = a["timestamp"] as? Double ?? 0
          let timestampB = b["timestamp"] as? Double ?? 0
          return timestampA < timestampB
        }
        
        print("iOS: 시간 기반 최종 GPS 데이터: \(sortedData.count)개 포인트 (중복 제거 후)")
        if let first = sortedData.first, let last = sortedData.last {
          let firstLat = first["latitude"] as? Double ?? 0
          let firstLng = first["longitude"] as? Double ?? 0
          let lastLat = last["latitude"] as? Double ?? 0
          let lastLng = last["longitude"] as? Double ?? 0
          print("iOS: 첫 번째 포인트 - lat: \(firstLat), lng: \(firstLng)")
          print("iOS: 마지막 포인트 - lat: \(lastLat), lng: \(lastLng)")
        }
        
        completion(sortedData)
      }
    }
    
    healthStore.execute(workoutQuery)
  }
  
  // MARK: - 고정밀 GPS 데이터 수집
  private func getLocationsForRouteWithHighPrecision(route: HKWorkoutRoute, completion: @escaping ([[String: Any]]?) -> Void) {
    print("iOS: 고정밀 GPS 데이터 수집 시작")
    
    // HKWorkoutRouteQuery로 실제 위치 데이터 접근 (더 세밀한 데이터)
    let locationQuery = HKWorkoutRouteQuery(route: route) { [weak self] query, locationsOrNil, done, error in
      if let error = error {
        print("iOS: 고정밀 GPS 데이터 조회 오류 - \(error)")
        completion(nil)
        return
      }
      
      guard let locations = locationsOrNil, !locations.isEmpty else {
        if done {
          print("iOS: 고정밀 GPS 데이터 없음")
          completion(nil)
        }
        return
      }
      
      print("iOS: \(locations.count)개의 고정밀 GPS 포인트 수신 (완료: \(done))")
      
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
        print("iOS: 고정밀 GPS 데이터 수집 완료: \(locationData.count)개 포인트")
        
        // GPS 데이터 품질 검증
        let validData = locationData.filter { location in
          let lat = location["latitude"] as? Double ?? 0
          let lng = location["longitude"] as? Double ?? 0
          let accuracy = location["horizontalAccuracy"] as? Double ?? 0
          
          // 유효한 좌표 범위 및 정확도 체크 (더 엄격한 기준)
          return lat != 0 && lng != 0 && 
                 lat >= -90 && lat <= 90 && 
                 lng >= -180 && lng <= 180 &&
                 accuracy > 0 && accuracy < 100 // 100m 이하 정확도만 허용 (더 엄격)
        }
        
        print("iOS: 유효한 고정밀 GPS 데이터: \(validData.count)/\(locationData.count)개")
        
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
  

}








