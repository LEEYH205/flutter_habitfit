import Flutter
import UIKit
import HealthKit
import CoreLocation
import GoogleSignIn

@main
@objc class AppDelegate: FlutterAppDelegate {

  private let healthStore = HKHealthStore()
  private let healthKitRouteManager = HealthKitRouteManager()
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Google Sign-In 초기화
    GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
      if error != nil || user == nil {
        // Show the app's signed-out state.
      } else {
        // Show the app's signed-in state.
      }
    }
    
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

  // Google Sign-In URL 핸들링
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    return GIDSignIn.sharedInstance.handle(url)
  }

  // iOS 8 이하 지원을 위한 URL 핸들링
  override func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
    return GIDSignIn.sharedInstance.handle(url)
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
      // 앱 시작 시 기본 권한만 요청
      requestBasicPermissions(result: result)

    case "checkHealthKitPermissions":
      // HealthKit 권한 상태 확인
      checkHealthKitPermissions(result: result)
      
    case "requestReportPermissions":
      // 달력 클릭 시 리포트 관련 권한 요청
      requestReportPermissions(result: result)
      
    case "requestRunningPermissions":
      // 러닝 기록 클릭 시 Apple Watch 고급 권한 요청
      requestRunningPermissions(result: result)
      
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
      print("iOS: HealthKitRouteManager에 위임")

      // HealthKitRouteManager에 위임
      healthKitRouteManager.getWorkoutRoute(startDate: startDate, endDate: endDate) { gpsData in
        if let gpsData = gpsData {
          print("iOS: HealthKitRouteManager로부터 GPS 데이터 수신: \(gpsData.count)개 포인트")
          result(gpsData)
        } else {
          print("iOS: HealthKitRouteManager로부터 GPS 데이터 수신 실패")
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
      print("iOS: HealthKitRouteManager에 위임")

      // HealthKitRouteManager에 위임
      healthKitRouteManager.getWorkoutRoutes(startDate: startDate, endDate: endDate) { routes in
        if let routes = routes {
          print("iOS: HealthKitRouteManager로부터 경로 데이터 수신: \(routes.count)개 경로")
          result(routes)
        } else {
          print("iOS: HealthKitRouteManager로부터 경로 데이터 수신 실패")
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
      print("iOS: HealthKitRouteManager에 위임")

      // HealthKitRouteManager에 위임
      healthKitRouteManager.getWorkoutRoutes(startDate: startDate, endDate: endDate) { routes in
        if let routes = routes {
          print("iOS: runningMetrics HealthKitRouteManager로부터 경로 데이터 수신: \(routes.count)개 경로")
          result(routes)
        } else {
          print("iOS: runningMetrics HealthKitRouteManager로부터 경로 데이터 수신 실패")
          result(nil)
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  
  // MARK: - 단계별 HealthKit 권한 요청 메서드들
  
  /// 앱 시작 시 기본 권한 요청 (걸음 수, 심박수, 운동 거리, 운동)
  private func requestBasicPermissions(result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(false)
      return
    }
    
    print("📱 iOS: 기본 HealthKit 권한 요청 시작")
    
    let typesToRead: Set<HKObjectType> = [
      // 기본 운동 데이터
      HKObjectType.workoutType(),                    // 운동
      HKObjectType.quantityType(forIdentifier: .heartRate)!,  // 심박수
      HKObjectType.quantityType(forIdentifier: .stepCount)!,              // 걸음
      HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!, // 걷기+달리기 거리
    ]
    
    self.healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
      DispatchQueue.main.async {
        if success {
          print("✅ iOS: 기본 HealthKit 권한 승인됨")
        } else {
          print("❌ iOS: 기본 HealthKit 권한 거부됨")
        }
        result(success)
      }
    }
  }
  
  /// 달력 클릭 시 리포트 관련 권한 요청
  private func requestReportPermissions(result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(false)
      return
    }
    
    print("📊 iOS: 리포트 관련 HealthKit 권한 요청 시작")
    
    let typesToRead: Set<HKObjectType> = [
      // 리포트 관련 데이터
      HKObjectType.quantityType(forIdentifier: .height)!,                 // 신장
      HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,  // 심박수 변이도
      HKObjectType.quantityType(forIdentifier: .flightsClimbed)!,          // 오른 층수
      HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,       // 운동하기 시간
      HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,     // 활동 에너지
      HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,      // 휴식 에너지
      HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,  // 안정 심박수
    ]
    
    self.healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
      DispatchQueue.main.async {
        if success {
          print("✅ iOS: 리포트 관련 HealthKit 권한 승인됨")
        } else {
          print("❌ iOS: 리포트 관련 HealthKit 권한 거부됨")
        }
        result(success)
      }
    }
  }
  
  /// HealthKit 권한 상태 확인
  private func checkHealthKitPermissions(result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(false)
      return
    }

    print("🔍 iOS: HealthKit 권한 상태 확인 시작")

    let typesToRead: Set<HKObjectType> = [
      // 기본 운동 데이터
      HKObjectType.workoutType(),
      HKObjectType.quantityType(forIdentifier: .heartRate)!,
      HKObjectType.quantityType(forIdentifier: .stepCount)!,
      HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
    ]

    // 권한 상태 확인
    let authorizationStatus = healthStore.authorizationStatus(for: HKObjectType.workoutType())

    switch authorizationStatus {
    case .sharingAuthorized:
      print("✅ iOS: HealthKit 권한이 이미 승인되어 있습니다")
      result(true)
    case .sharingDenied:
      print("❌ iOS: HealthKit 권한이 거부되어 있습니다")
      result(false)
    case .notDetermined:
      print("⚠️ iOS: HealthKit 권한이 아직 결정되지 않았습니다")
      result(false)
    @unknown default:
      print("⚠️ iOS: HealthKit 권한 상태를 알 수 없습니다")
      result(false)
    }
  }

  /// 러닝 기록 클릭 시 Apple Watch 고급 권한 요청
  private func requestRunningPermissions(result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(false)
      return
    }
    
    print("🏃‍♂️ iOS: Apple Watch 러닝 관련 HealthKit 권한 요청 시작")
    
    let typesToRead: Set<HKObjectType> = [
      // Apple Watch 특화 러닝 다이내믹스 데이터
      HKObjectType.quantityType(forIdentifier: .runningStrideLength)!,       // 달리기 보폭 길이 (Apple Watch)
      HKObjectType.quantityType(forIdentifier: .runningSpeed)!,              // 달리기 속도 (Apple Watch)
      HKObjectType.quantityType(forIdentifier: .runningPower)!,              // 달리기 파워 (Apple Watch)
      HKObjectType.quantityType(forIdentifier: .runningVerticalOscillation)!, // 수직 진폭 (Apple Watch)
      HKObjectType.quantityType(forIdentifier: .runningGroundContactTime)!,  // 지면 접촉 시간 (Apple Watch)
      HKObjectType.quantityType(forIdentifier: .walkingHeartRateAverage)!,  // 걷기 평균 심박수
      HKObjectType.quantityType(forIdentifier: .appleStandTime)!,            // 서 있는 시간
    ]
    
    self.healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
      DispatchQueue.main.async {
        if success {
          print("✅ iOS: Apple Watch 러닝 관련 HealthKit 권한 승인됨")
        } else {
          print("❌ iOS: Apple Watch 러닝 관련 HealthKit 권한 거부됨")
        }
        result(success)
      }
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
  
// MARK: - HealthKit Route Manager
@objc class HealthKitRouteManager: NSObject {
    private let healthStore = HKHealthStore()

    @objc func requestHealthKitPermissions(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
          }
          
        let typesToRead: Set<HKObjectType> = [
            // 필수 운동 데이터
            HKObjectType.workoutType(),                    // 운동
            HKSeriesType.workoutRoute(),                   // 운동 경로

            // 필수 심박수 및 심장 건강 (Apple Watch 지원)
            HKObjectType.quantityType(forIdentifier: .heartRate)!,  // 심박수
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,  // 안정 심박수
            HKObjectType.quantityType(forIdentifier: .walkingHeartRateAverage)!,  // 걷기 평균 심박수
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,  // 심박수 변이도

            // 필수 운동 및 활동 데이터
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,     // 활동 에너지
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,      // 휴식 에너지
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!, // 걷기+달리기 거리
            HKObjectType.quantityType(forIdentifier: .stepCount)!,              // 걸음
            HKObjectType.quantityType(forIdentifier: .flightsClimbed)!,          // 오른 층수
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,       // 운동하기 시간
            HKObjectType.quantityType(forIdentifier: .appleStandTime)!,            // 서 있는 시간

            // Apple Watch 특화 데이터 (고급 센서 데이터)
            HKObjectType.quantityType(forIdentifier: .runningStrideLength)!,       // 달리기 보폭 길이 (Apple Watch)
            HKObjectType.quantityType(forIdentifier: .runningSpeed)!,              // 달리기 속도 (Apple Watch)
            HKObjectType.quantityType(forIdentifier: .runningPower)!,              // 달리기 파워 (Apple Watch)
            HKObjectType.quantityType(forIdentifier: .runningVerticalOscillation)!, // 수직 진폭 (Apple Watch)
            HKObjectType.quantityType(forIdentifier: .runningGroundContactTime)!,  // 지면 접촉 시간 (Apple Watch)

            // 추가 심장 건강 데이터 (주석 처리)
            // HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            // HKObjectType.quantityType(forIdentifier: .walkingHeartRateAverage)!,
            // HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,

            // 추가 활동 데이터 (주석 처리)
            // HKObjectType.quantityType(forIdentifier: .appleStandTime)!,

            // 신체 측정 (주석 처리)
            // HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            // HKObjectType.quantityType(forIdentifier: .height)!,
            // HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!,
            // HKObjectType.quantityType(forIdentifier: .leanBodyMass)!,

            // 영양 및 수분 (주석 처리)
            // HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            // HKObjectType.quantityType(forIdentifier: .dietaryProtein)!,
            // HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
            // HKObjectType.quantityType(forIdentifier: .dietaryFatTotal)!,
            // HKObjectType.quantityType(forIdentifier: .dietaryWater)!,

            // 수면 (주석 처리)
            // HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,

            // 혈압 및 혈당 (주석 처리)
            // HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!,
            // HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
            // HKObjectType.quantityType(forIdentifier: .bloodGlucose)!,

            // 체온 (주석 처리)
            // HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,

            // 산소 포화도 (주석 처리)
            // HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
            // HKObjectType.quantityType(forIdentifier: .peripheralPerfusionIndex)!,

            // 호흡 (주석 처리)
            // HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,

            // 여성 건강 (주석 처리)
            // HKObjectType.categoryType(forIdentifier: .menstrualFlow)!,
            // HKObjectType.quantityType(forIdentifier: .basalBodyTemperature)!,

            // 건강 기록 (주석 처리)
            // HKObjectType.clinicalType(forIdentifier: .allergyRecord)!,
            // HKObjectType.clinicalType(forIdentifier: .conditionRecord)!,
            // HKObjectType.clinicalType(forIdentifier: .medicationRecord)!,
            // HKObjectType.clinicalType(forIdentifier: .procedureRecord)!,

            // 정신 건강 (주석 처리)
            // HKObjectType.quantityType(forIdentifier: .mindfulSession)!,
        ]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }

    @objc func getWorkoutRoute(startDate: Date, endDate: Date, completion: @escaping ([[String: Any]]?) -> Void) {
        print("🔍 HealthKit: getWorkoutRoute 시작 - \(startDate) ~ \(endDate)")
        print("🔍 HealthKit: HealthStore 상태 확인 - isHealthDataAvailable: \(HKHealthStore.isHealthDataAvailable())")

        // 1. 운동 데이터 조회 (더 넓은 범위로 검색)
        let workoutPredicate = HKQuery.predicateForSamples(withStart: startDate.addingTimeInterval(-3600), end: endDate.addingTimeInterval(3600), options: .strictStartDate)
        let workoutQuery = HKSampleQuery(sampleType: .workoutType(), predicate: workoutPredicate, limit: 10, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { [weak self] query, samples, error in
      if let error = error {
                print("❌ HealthKit: 운동 데이터 조회 오류 - \(error.localizedDescription)")
        completion(nil)
        return
      }
      
            guard let workouts = samples as? [HKWorkout] else {
                print("⚠️ HealthKit: 운동 데이터 타입 변환 실패")
        completion(nil)
        return
      }
      
            print("🔍 HealthKit: 조회된 운동 수: \(workouts.count)")

            // 요청한 시간 범위와 가장 가까운 운동 찾기
            var targetWorkout: HKWorkout?
            var minTimeDiff = Double.greatestFiniteMagnitude

            for workout in workouts {
                let timeDiff = abs(workout.startDate.timeIntervalSince(startDate))
                print("🔍 HealthKit: 운동 시간 차이 - \(timeDiff)초, 시작: \(workout.startDate)")
                if timeDiff < minTimeDiff {
                    minTimeDiff = timeDiff
                    targetWorkout = workout
                }
            }

            guard let workout = targetWorkout else {
                print("⚠️ HealthKit: 해당 시간대에 운동 데이터가 없습니다")
        completion(nil)
        return
      }
      
            print("✅ HealthKit: 가장 가까운 운동 발견 - \(workout.workoutActivityType.rawValue), 시작: \(workout.startDate), 종료: \(workout.endDate)")
            print("🔍 HealthKit: 운동 UUID: \(workout.uuid)")
            print("🔍 HealthKit: 운동 소스: \(workout.sourceRevision.source.name)")
            print("🔍 HealthKit: 시간 차이: \(minTimeDiff)초")

            // 2. 운동 경로 조회
            self?.getRouteForWorkout(workout: workout, completion: completion)
        }

        healthStore.execute(workoutQuery)
    }

    private func queryWorkoutRoute(for workout: HKWorkout, completion: @escaping ([[String: Any]]?) -> Void) {
        print("🔍 HealthKit: 운동 경로 데이터 조회 시작")

        let routeType = HKSeriesType.workoutRoute()

        // HKAnchoredObjectQuery로 경로 샘플 조회
        let routeQuery = HKAnchoredObjectQuery(type: routeType, predicate: HKQuery.predicateForObjects(from: workout), anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] query, samples, deletedObjects, anchor, error in
            if let error = error {
                print("❌ HealthKit: 경로 데이터 조회 오류 - \(error.localizedDescription)")
                completion(nil)
                return
            }

            print("🔍 HealthKit: 경로 쿼리 결과 - 샘플 수: \(samples?.count ?? 0)")

            guard let routes = samples as? [HKWorkoutRoute], let route = routes.first else {
                print("⚠️ HealthKit: 해당 운동에 경로 데이터가 없습니다")
                print("🔍 HealthKit: 조회된 샘플 타입: \(type(of: samples?.first))")
                completion(nil)
                return
            }

            print("✅ HealthKit: 경로 데이터 발견 - 경로 ID: \(route.uuid)")
            print("🔍 HealthKit: 경로 시작 시간: \(route.startDate)")
            print("🔍 HealthKit: 경로 종료 시간: \(route.endDate)")

            // 3. 경로의 위치 데이터 조회
            self?.getLocationsForRoute(route: route, completion: completion)
        }

        healthStore.execute(routeQuery)
    }

    private func getRouteForWorkout(workout: HKWorkout, completion: @escaping ([[String: Any]]?) -> Void) {
        print("🔍 HealthKit: 운동 경로 조회 시작 - 운동 ID: \(workout.uuid)")

        // 권한 상태 확인 후 요청 (이미 승인된 경우 생략)
        let routeType = HKSeriesType.workoutRoute()
        let workoutType = HKObjectType.workoutType()

        // 권한 상태 먼저 확인
        let routeAuthStatus = healthStore.authorizationStatus(for: routeType)
        let workoutAuthStatus = healthStore.authorizationStatus(for: workoutType)

        if routeAuthStatus == .sharingAuthorized && workoutAuthStatus == .sharingAuthorized {
            print("✅ HealthKit: 경로 권한이 이미 승인되어 있습니다")
            // 권한이 이미 승인되었으므로 경로 데이터 조회 진행
            self.queryWorkoutRoute(for: workout, completion: completion)
            return
        }

        print("🔄 HealthKit: 경로 권한 요청 시작...")
        healthStore.requestAuthorization(toShare: nil, read: [routeType, workoutType]) { [weak self] success, error in
            if let error = error {
                print("❌ HealthKit: 경로 권한 요청 오류 - \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if !success {
                print("❌ HealthKit: 경로 권한이 거부되었습니다")
                completion(nil)
                return
            }
            
            print("✅ HealthKit: 경로 권한 승인됨")

            // 권한 승인 후 경로 데이터 조회
            self?.queryWorkoutRoute(for: workout, completion: completion)
        }
    }

    private func getLocationsForRoute(route: HKWorkoutRoute, completion: @escaping ([[String: Any]]?) -> Void) {
        print("🔍 HealthKit: 위치 데이터 조회 시작")

        var allLocations: [CLLocation] = []

        // HKWorkoutRouteQuery로 실제 위치 데이터 접근 (블로그 예제 기반)
    let locationQuery = HKWorkoutRouteQuery(route: route) { [weak self] query, locationsOrNil, done, error in
      if let error = error {
                print("❌ HealthKit: 위치 데이터 조회 오류 - \(error.localizedDescription)")
        completion(nil)
        return
      }
      
            guard let locations = locationsOrNil else {
                print("⚠️ HealthKit: 위치 데이터가 nil입니다")
          completion(nil)
        return
      }
      
            allLocations.append(contentsOf: locations)
            print("📍 HealthKit: \(locations.count)개 위치 데이터 수신 (총 \(allLocations.count)개)")

            if done {
                // 모든 위치 데이터를 받았을 때
                print("✅ HealthKit: 모든 위치 데이터 수신 완료 - 총 \(allLocations.count)개")
      
      // 위치 데이터를 Flutter에서 사용할 수 있는 형태로 변환
                let locationData = allLocations.map { location -> [String: Any] in
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
}



