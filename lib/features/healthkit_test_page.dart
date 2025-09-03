import 'package:flutter/material.dart';
import 'package:health/health.dart';
import '../services/health_kit_service.dart';
import '../services/healthkit_route_service.dart';

class HealthKitTestPage extends StatefulWidget {
  const HealthKitTestPage({super.key});

  @override
  State<HealthKitTestPage> createState() => _HealthKitTestPageState();
}

class _HealthKitTestPageState extends State<HealthKitTestPage> {
  final List<String> _logs = [];
  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
  }

  Future<void> _testHealthKitPermissions() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    try {
      _addLog('🔍 HealthKit 권한 테스트 시작...');

      // 1. HealthKit 서비스 인스턴스 생성 및 초기화
      final healthKitService = HealthKitService();
      final hasPermissions = await healthKitService.initialize();
      _addLog('✅ HealthKit 초기화 결과: $hasPermissions');

      // 2. 운동 데이터 테스트
      _addLog('🏃‍♂️ 운동 데이터 테스트 시작...');
      final workouts = await healthKitService.getRecentWorkouts(days: 30);
      _addLog('📊 운동 데이터 개수: ${workouts.length}');

      if (workouts.isNotEmpty) {
        final latestWorkout = workouts.first;
        _addLog(
            '📋 최신 운동: ${latestWorkout.type} - ${latestWorkout.distance}km');
        _addLog('⏰ 시작 시간: ${latestWorkout.startTime}');
        _addLog('⏰ 종료 시간: ${latestWorkout.endTime}');
        _addLog('🆔 운동 ID: ${latestWorkout.id}');
        _addLog('🆔 운동 UUID: ${latestWorkout.uuid}');
      }

      // 3. 심박수 데이터 테스트
      _addLog('💓 심박수 데이터 테스트 시작...');
      if (workouts.isNotEmpty) {
        final latestWorkout = workouts.first;
        final heartRateData = await healthKitService.getHeartRateData(
          latestWorkout.startTime,
          latestWorkout.endTime ??
              latestWorkout.startTime.add(latestWorkout.duration),
        );
        _addLog('💓 심박수 데이터 개수: ${heartRateData.length}');

        if (heartRateData.isNotEmpty) {
          _addLog('💓 첫 번째 심박수: ${heartRateData.first.value} BPM');
          _addLog('💓 마지막 심박수: ${heartRateData.last.value} BPM');
        } else {
          _addLog('⚠️ 심박수 데이터가 없습니다');
        }
      }

      // 4. GPS 경로 데이터 테스트
      _addLog('🗺️ GPS 경로 데이터 테스트 시작...');
      if (workouts.isNotEmpty) {
        final latestWorkout = workouts.first;

        // HealthKitRouteService 권한 요청
        final routePermission =
            await HealthKitRouteService.requestPermissions();
        _addLog('🗺️ GPS 경로 권한 요청 결과: $routePermission');

        // GPS 경로 데이터 요청
        final routeData = await HealthKitRouteService.getWorkoutRoute(
          latestWorkout.startTime,
          latestWorkout.endTime ??
              latestWorkout.startTime.add(latestWorkout.duration),
          workoutId: latestWorkout.id.isNotEmpty ? latestWorkout.id : null,
        );

        _addLog('🗺️ GPS 경로 데이터 개수: ${routeData?.length ?? 0}');

        if (routeData != null && routeData.isNotEmpty) {
          _addLog('🗺️ 첫 번째 GPS 포인트: ${routeData.first}');
          _addLog('🗺️ 마지막 GPS 포인트: ${routeData.last}');
        } else {
          _addLog('⚠️ GPS 경로 데이터가 없습니다');
        }
      }

      _addLog('✅ HealthKit 테스트 완료!');
    } catch (e) {
      _addLog('❌ 오류 발생: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HealthKit 테스트'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _testHealthKitPermissions,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('HealthKit 데이터 테스트 시작'),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      _logs[index],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
