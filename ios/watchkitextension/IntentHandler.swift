//
//  ExtensionDelegate.swift
//  HabitFitWatch Extension
//
//  Created by 이영호 on 9/7/25.
//

import WatchKit
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate {
    
    func applicationDidFinishLaunching() {
        // Watch Connectivity 세션 설정
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func applicationDidBecomeActive() {
        // 앱이 활성화될 때 호출
    }
    
    func applicationWillResignActive() {
        // 앱이 비활성화될 때 호출
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("Watch Connectivity activation failed: \(error.localizedDescription)")
        } else {
            print("Watch Connectivity activated successfully")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // iPhone에서 Watch로 메시지 수신
        DispatchQueue.main.async {
            if let action = message["action"] as? String {
                switch action {
                case "heartRateUpdate":
                    if let heartRate = message["heartRate"] as? Double {
                        // 심박수 업데이트 처리
                        NotificationCenter.default.post(
                            name: NSNotification.Name("HeartRateUpdate"),
                            object: nil,
                            userInfo: ["heartRate": heartRate]
                        )
                    }
                case "workoutStatus":
                    if let isActive = message["isActive"] as? Bool {
                        // 운동 상태 업데이트 처리
                        NotificationCenter.default.post(
                            name: NSNotification.Name("WorkoutStatusUpdate"),
                            object: nil,
                            userInfo: ["isActive": isActive]
                        )
                    }
                default:
                    break
                }
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        // iPhone에서 Watch로 메시지 수신 (응답 필요)
        DispatchQueue.main.async {
            replyHandler(["status": "received"])
        }
    }
}

