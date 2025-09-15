import WatchKit
import HealthKit
import WatchConnectivity

class HabitFitWatchApp: WKInterfaceController {
    
    @IBOutlet weak var workoutTypeLabel: WKInterfaceLabel!
    @IBOutlet weak var durationLabel: WKInterfaceLabel!
    @IBOutlet weak var heartRateLabel: WKInterfaceLabel!
    @IBOutlet weak var stepsLabel: WKInterfaceLabel!
    @IBOutlet weak var caloriesLabel: WKInterfaceLabel!
    @IBOutlet weak var startStopButton: WKInterfaceButton!
    @IBOutlet weak var pauseResumeButton: WKInterfaceButton!
    
    private let healthStore = HKHealthStore()
    private let session = WCSession.default
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    
    private var isWorkoutActive = false
    private var isWorkoutPaused = false
    private var workoutStartTime: Date?
    private var workoutType: HKWorkoutActivityType = .running
    
    private var heartRate: Double = 0.0
    private var steps: Int = 0
    private var calories: Double = 0.0
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        setupWatchConnectivity()
        setupHealthKit()
        updateUI()
    }
    
    // MARK: - Watch Connectivity Setup
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - HealthKit Setup
    
    private func setupHealthKit() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit is not available on this device")
            return
        }
        
        let typesToShare: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        ]
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if let error = error {
                print("❌ HealthKit authorization failed: \(error.localizedDescription)")
            } else {
                print("✅ HealthKit authorization successful")
            }
        }
    }
    
    // MARK: - UI Actions
    
    @IBAction func startStopButtonTapped() {
        if isWorkoutActive {
            stopWorkout()
        } else {
            startWorkout()
        }
    }
    
    @IBAction func pauseResumeButtonTapped() {
        if isWorkoutPaused {
            resumeWorkout()
        } else {
            pauseWorkout()
        }
    }
    
    // MARK: - Workout Management
    
    private func startWorkout() {
        guard !isWorkoutActive else { return }
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutType
        configuration.locationType = .outdoor
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            
            workoutSession?.delegate = self
            workoutBuilder?.delegate = self
            
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            
            let startDate = Date()
            workoutSession?.startActivity(with: startDate)
            workoutBuilder?.beginCollection(at: startDate) { success, error in
                if let error = error {
                    print("❌ Workout builder begin collection failed: \(error.localizedDescription)")
                } else {
                    print("✅ Workout builder begin collection successful")
                }
            }
            
            workoutStartTime = startDate
            isWorkoutActive = true
            isWorkoutPaused = false
            
            updateUI()
            sendWorkoutStartToPhone()
            
        } catch {
            print("❌ Failed to start workout: \(error.localizedDescription)")
        }
    }
    
    private func stopWorkout() {
        guard isWorkoutActive else { return }
        
        let endDate = Date()
        workoutSession?.end()
        workoutBuilder?.endCollection(at: endDate) { success, error in
            if let error = error {
                print("❌ Workout builder end collection failed: \(error.localizedDescription)")
            } else {
                print("✅ Workout builder end collection successful")
            }
        }
        
        workoutBuilder?.finishWorkout { workout, error in
            if let error = error {
                print("❌ Failed to finish workout: \(error.localizedDescription)")
            } else {
                print("✅ Workout finished successfully")
            }
        }
        
        isWorkoutActive = false
        isWorkoutPaused = false
        workoutStartTime = nil
        
        updateUI()
        sendWorkoutEndToPhone()
    }
    
    private func pauseWorkout() {
        guard isWorkoutActive && !isWorkoutPaused else { return }
        
        workoutSession?.pause()
        isWorkoutPaused = true
        updateUI()
        sendWorkoutPauseToPhone()
    }
    
    private func resumeWorkout() {
        guard isWorkoutActive && isWorkoutPaused else { return }
        
        workoutSession?.resume()
        isWorkoutPaused = false
        updateUI()
        sendWorkoutResumeToPhone()
    }
    
    // MARK: - Phone Communication
    
    private func sendWorkoutStartToPhone() {
        let message: [String: Any] = [
            "type": "workout_start",
            "workoutType": workoutType.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ]
        session.sendMessage(message, replyHandler: nil, errorHandler: { error in
            print("❌ Failed to send workout start to phone: \(error.localizedDescription)")
        })
    }
    
    private func sendWorkoutEndToPhone() {
        let duration = workoutStartTime?.timeIntervalSinceNow ?? 0
        let message: [String: Any] = [
            "type": "workout_end",
            "workoutType": workoutType.rawValue,
            "duration": abs(duration),
            "calories": calories,
            "timestamp": Date().timeIntervalSince1970
        ]
        session.sendMessage(message, replyHandler: nil, errorHandler: { error in
            print("❌ Failed to send workout end to phone: \(error.localizedDescription)")
        })
    }
    
    private func sendWorkoutPauseToPhone() {
        let message: [String: Any] = [
            "type": "workout_pause",
            "timestamp": Date().timeIntervalSince1970
        ]
        session.sendMessage(message, replyHandler: nil, errorHandler: { error in
            print("❌ Failed to send workout pause to phone: \(error.localizedDescription)")
        })
    }
    
    private func sendWorkoutResumeToPhone() {
        let message: [String: Any] = [
            "type": "workout_resume",
            "timestamp": Date().timeIntervalSince1970
        ]
        session.sendMessage(message, replyHandler: nil, errorHandler: { error in
            print("❌ Failed to send workout resume to phone: \(error.localizedDescription)")
        })
    }
    
    private func sendRealTimeDataToPhone() {
        let message: [String: Any] = [
            "type": "realtime_data",
            "heartRate": heartRate,
            "steps": steps,
            "calories": calories,
            "timestamp": Date().timeIntervalSince1970
        ]
        session.sendMessage(message, replyHandler: nil, errorHandler: { error in
            print("❌ Failed to send real-time data to phone: \(error.localizedDescription)")
        })
    }
    
    // MARK: - UI Updates
    
    private func updateUI() {
        workoutTypeLabel.setText(getWorkoutTypeName())
        
        if isWorkoutActive {
            let duration = workoutStartTime?.timeIntervalSinceNow ?? 0
            durationLabel.setText(formatDuration(abs(duration)))
            startStopButton.setTitle("종료")
            startStopButton.setBackgroundColor(.red)
        } else {
            durationLabel.setText("00:00")
            startStopButton.setTitle("시작")
            startStopButton.setBackgroundColor(.green)
        }
        
        pauseResumeButton.setEnabled(isWorkoutActive)
        if isWorkoutPaused {
            pauseResumeButton.setTitle("재개")
            pauseResumeButton.setBackgroundColor(.green)
        } else {
            pauseResumeButton.setTitle("일시정지")
            pauseResumeButton.setBackgroundColor(.orange)
        }
        
        heartRateLabel.setText("\(Int(heartRate)) BPM")
        stepsLabel.setText("\(steps) 걸음")
        caloriesLabel.setText("\(Int(calories)) 칼로리")
    }
    
    private func getWorkoutTypeName() -> String {
        switch workoutType {
        case .running:
            return "달리기"
        case .walking:
            return "걷기"
        case .cycling:
            return "자전거"
        case .swimming:
            return "수영"
        default:
            return "운동"
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - HKWorkoutSessionDelegate

extension HabitFitWatchApp: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            switch toState {
            case .running:
                print("✅ Workout session is running")
            case .paused:
                print("⏸️ Workout session is paused")
            case .ended:
                print("🏁 Workout session ended")
            default:
                break
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("❌ Workout session failed: \(error.localizedDescription)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension HabitFitWatchApp: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        DispatchQueue.main.async {
            for type in collectedTypes {
                guard let quantityType = type as? HKQuantityType else { continue }
                
                let statistics = workoutBuilder.statistics(for: quantityType)
                
                switch quantityType {
                case HKQuantityType.quantityType(forIdentifier: .heartRate):
                    if let heartRate = statistics?.mostRecentQuantity()?.doubleValue(for: HKUnit(from: "count/min")) {
                        self.heartRate = heartRate
                    }
                case HKQuantityType.quantityType(forIdentifier: .stepCount):
                    if let steps = statistics?.sumQuantity()?.doubleValue(for: HKUnit.count()) {
                        self.steps = Int(steps)
                    }
                case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                    if let calories = statistics?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) {
                        self.calories = calories
                    }
                default:
                    break
                }
            }
            
            self.updateUI()
            
            // 실시간 데이터를 iPhone으로 전송
            if self.isWorkoutActive {
                self.sendRealTimeDataToPhone()
            }
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // 이벤트 수집 시 처리
    }
}

// MARK: - WCSessionDelegate

extension HabitFitWatchApp: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("❌ Watch session activation failed: \(error.localizedDescription)")
        } else {
            print("✅ Watch session activation successful")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            guard let type = message["type"] as? String else { return }
            
            switch type {
            case "workout_start":
                if let workoutTypeRaw = message["workoutType"] as? Int,
                   let workoutType = HKWorkoutActivityType(rawValue: workoutTypeRaw) {
                    self.workoutType = workoutType
                    self.startWorkout()
                }
            case "workout_end":
                self.stopWorkout()
            case "workout_pause":
                self.pauseWorkout()
            case "workout_resume":
                self.resumeWorkout()
            default:
                print("⚠️ Unknown message type: \(type)")
            }
        }
    }
}
