import 'package:flutter/material.dart';
import '../../widgets/watch_workout_widget.dart';

/// 워치 연동 테스트 페이지
class WatchTestPage extends StatefulWidget {
  const WatchTestPage({super.key});

  @override
  State<WatchTestPage> createState() => _WatchTestPageState();
}

class _WatchTestPageState extends State<WatchTestPage> {
  final List<String> _workoutTypes = [
    '달리기',
    '걷기',
    '자전거',
    '수영',
    '스쿼트',
    '푸시업',
    '플랭크',
  ];

  String _selectedWorkoutType = '달리기';
  final List<Map<String, dynamic>> _workoutHistory = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⌚ Apple Watch 연동 테스트'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: const Icon(Icons.watch),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 워치 연동 위젯
            WatchWorkoutWidget(
              workoutType: _selectedWorkoutType,
              onWorkoutStart: () {
                print('🏃‍♂️ 운동 시작: $_selectedWorkoutType');
              },
              onWorkoutEnd: () {
                print('🏁 운동 종료: $_selectedWorkoutType');
              },
              onWorkoutData: (distance, calories, heartRate) {
                setState(() {
                  _workoutHistory.insert(0, {
                    'workoutType': _selectedWorkoutType,
                    'distance': distance,
                    'calories': calories,
                    'heartRate': heartRate,
                    'timestamp': DateTime.now(),
                  });
                });
              },
            ),

            const SizedBox(height: 16),

            // 운동 타입 선택
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '운동 타입 선택',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _workoutTypes.map((type) {
                        final isSelected = _selectedWorkoutType == type;
                        return FilterChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedWorkoutType = type;
                              });
                            }
                          },
                          selectedColor: Colors.blue.withOpacity(0.3),
                          checkmarkColor: Colors.blue,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 운동 기록
            if (_workoutHistory.isNotEmpty) ...[
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '최근 운동 기록',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...(_workoutHistory.take(5).map((workout) {
                        final timestamp = workout['timestamp'] as DateTime;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.fitness_center),
                            title: Text(workout['workoutType']),
                            subtitle: Text(
                              '거리: ${workout['distance'].toStringAsFixed(2)}km, '
                              '칼로리: ${workout['calories'].toStringAsFixed(0)}kcal, '
                              '심박수: ${workout['heartRate']}BPM',
                            ),
                            trailing: Text(
                              '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        );
                      }).toList()),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // 사용법 안내
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📱 사용법',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Apple Watch가 iPhone과 연결되어 있는지 확인하세요\n'
                      '2. 운동 타입을 선택하세요\n'
                      '3. "운동 시작" 버튼을 눌러 워치에 알림을 전송하세요\n'
                      '4. 운동 중 실시간 데이터가 워치로 전송됩니다\n'
                      '5. "종료" 버튼을 눌러 운동 데이터를 워치에 저장하세요',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 주의사항
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚠️ 주의사항',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• 이 기능은 Apple Watch가 연결된 iPhone에서만 작동합니다\n'
                      '• HealthKit 권한이 필요합니다\n'
                      '• 실제 운동 데이터는 시뮬레이션입니다\n'
                      '• 워치 연결이 끊어지면 기능이 제한됩니다',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
