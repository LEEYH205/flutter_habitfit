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
            HKObjectType.workoutRouteType()
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    @objc func getWorkoutRoute(startDate: Date, endDate: Date, completion: @escaping ([[String: Any]]?) -> Void) {
        // 1. 운동 데이터 조회
        let workoutPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let workoutQuery = HKSampleQuery(sampleType: .workoutType(), predicate: workoutPredicate, limit: 1, sortDescriptors: nil) { [weak self] query, samples, error in
            guard let workouts = samples as? [HKWorkout], let workout = workouts.first else {
                completion(nil)
                return
            }
            
            // 2. 운동 경로 조회
            self?.getRouteForWorkout(workout: workout, completion: completion)
        }
        
        healthStore.execute(workoutQuery)
    }
    
    private func getRouteForWorkout(workout: HKWorkout, completion: @escaping ([[String: Any]]?) -> Void) {
        // HKAnchoredObjectQuery로 경로 샘플 조회 (블로그 예제 기반)
        let routeQuery = HKAnchoredObjectQuery(type: HKSeriesType.workoutRoute(), predicate: HKQuery.predicateForObjects(from: workout), anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] query, samples, deletedObjects, anchor, error in
            guard let routes = samples as? [HKWorkoutRoute], let route = routes.first else {
                completion(nil)
                return
            }
            
            // 3. 경로의 위치 데이터 조회
            self?.getLocationsForRoute(route: route, completion: completion)
        }
        
        healthStore.execute(routeQuery)
    }
    
    private func getLocationsForRoute(route: HKWorkoutRoute, completion: @escaping ([[String: Any]]?) -> Void) {
        // HKWorkoutRouteQuery로 실제 위치 데이터 접근 (블로그 예제 기반)
        let locationQuery = HKWorkoutRouteQuery(route: route) { [weak self] query, locationsOrNil, done, error in
            guard let locations = locationsOrNil else {
                completion(nil)
                return
            }
            
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
