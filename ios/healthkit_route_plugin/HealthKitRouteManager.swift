import Foundation
import HealthKit
import Flutter

@objc class HealthKitRouteManager: NSObject {
    private let healthStore = HKHealthStore()
    
    @objc func requestHealthKitPermissions(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKObjectType.workoutRouteType(),
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .exerciseTime)!,
            HKObjectType.quantityType(forIdentifier: .flightsClimbed)!,
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!
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
    
    private func getRouteForWorkout(workout: HKWorkout, completion: @escaping ([[String: Any]]?) -> Void) {
        print("🔍 HealthKit: 운동 경로 조회 시작 - 운동 ID: \(workout.uuid)")
        
        // HKAnchoredObjectQuery로 경로 샘플 조회 (블로그 예제 기반)
        let routeQuery = HKAnchoredObjectQuery(type: HKSeriesType.workoutRoute(), predicate: HKQuery.predicateForObjects(from: workout), anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] query, samples, deletedObjects, anchor, error in
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
