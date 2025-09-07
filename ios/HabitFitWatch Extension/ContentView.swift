//
//  ContentView.swift
//  HabitFitWatch Extension
//
//  Created by 이영호 on 9/7/25.
//

import SwiftUI
import HealthKit
import WatchConnectivity

struct ContentView: View {
    @State private var heartRate: Double = 0
    @State private var isWorkoutActive = false
    @State private var workoutDuration: TimeInterval = 0
    @State private var stepsToday: Int = 0
    @State private var activeCalories: Double = 0
    @State private var isConnected = false
    
    private let healthStore = HKHealthStore()
    private let session = WCSession.default
    
    var body: some View {
        TabView {
            // 메인 대시보드
            VStack(spacing: 10) {
                // 연결 상태
                HStack {
                    Circle()
                        .fill(isConnected ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(isConnected ? "연결됨" : "연결 안됨")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // 심박수
                VStack {
                    Text("\(Int(heartRate))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.red)
                    Text("BPM")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // 운동 제어
                VStack(spacing: 8) {
                    Button(action: isWorkoutActive ? stopWorkout : startWorkout) {
                        Text(isWorkoutActive ? "운동 중지" : "운동 시작")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(isWorkoutActive ? Color.red : Color.green)
                            .cornerRadius(8)
                    }
                    
                    if isWorkoutActive {
                        Text(formatDuration(workoutDuration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .tabItem {
                Image(systemName: "heart.fill")
                Text("심박수")
            }
            
            // 건강 요약
            VStack(spacing: 12) {
                Text("오늘의 활동")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "figure.walk")
                            .foregroundColor(.blue)
                        Text("걸음수")
                            .font(.caption)
                        Spacer()
                        Text("\(stepsToday)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("활동 칼로리")
                            .font(.caption)
                        Spacer()
                        Text("\(Int(activeCalories)) kcal")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.green)
                        Text("운동 시간")
                            .font(.caption)
                        Spacer()
                        Text(formatDuration(workoutDuration))
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .tabItem {
                Image(systemName: "chart.bar.fill")
                Text("활동")
            }
        }
        .onAppear {
            checkConnectivity()
            startHeartRateMonitoring()
        }
    }
    
    private func startWorkout() {
        isWorkoutActive = true
        workoutDuration = 0
        
        // iPhone에 운동 시작 메시지 전송
        sendMessageToiOS(["action": "startWorkout"])
        
        // 타이머 시작
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if isWorkoutActive {
                workoutDuration += 1
            }
        }
    }
    
    private func stopWorkout() {
        isWorkoutActive = false
        
        // iPhone에 운동 종료 메시지 전송
        sendMessageToiOS(["action": "stopWorkout", "duration": workoutDuration])
    }
    
    private func startHeartRateMonitoring() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        healthStore.requestAuthorization(toShare: nil, read: [heartRateType]) { success, error in
            if success {
                let query = HKAnchoredObjectQuery(
                    type: heartRateType,
                    predicate: nil,
                    anchor: nil,
                    limit: HKObjectQueryNoLimit
                ) { _, samples, _, _, _ in
                    if let sample = samples?.last as? HKQuantitySample {
                        DispatchQueue.main.async {
                            self.heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                        }
                    }
                }
                
                healthStore.execute(query)
            }
        }
    }
    
    private func checkConnectivity() {
        if WCSession.isSupported() {
            session.activate()
            isConnected = session.isReachable
        }
    }
    
    private func sendMessageToiOS(_ message: [String: Any]) {
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { error in
                print("Watch to iOS message failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    ContentView()
}
