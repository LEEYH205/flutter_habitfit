import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/watch_service.dart';

/// 워치 연동 운동 위젯
class WatchWorkoutWidget extends ConsumerStatefulWidget {
  final String workoutType;
  final VoidCallback? onWorkoutStart;
  final VoidCallback? onWorkoutEnd;
  final Function(double distance, double calories, int heartRate)?
      onWorkoutData;

  const WatchWorkoutWidget({
    super.key,
    required this.workoutType,
    this.onWorkoutStart,
    this.onWorkoutEnd,
    this.onWorkoutData,
  });

  @override
  ConsumerState<WatchWorkoutWidget> createState() => _WatchWorkoutWidgetState();
}

class _WatchWorkoutWidgetState extends ConsumerState<WatchWorkoutWidget> {
  final WatchService _watchService = WatchService();
  bool _isInitialized = false;
  bool _isConnected = false;
  bool _isWorkoutActive = false;
  DateTime? _workoutStartTime;
  int _currentHeartRate = 0;
  int _totalSteps = 0;
  double _totalCalories = 0.0;
  double _totalDistance = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeWatch();
  }

  Future<void> _initializeWatch() async {
    try {
      final success = await _watchService.initialize();
      setState(() {
        _isInitialized = true;
        _isConnected = success;
      });
    } catch (e) {
      print('❌ 워치 초기화 오류: $e');
      setState(() {
        _isInitialized = true;
        _isConnected = false;
      });
    }
  }

  Future<void> _startWorkout() async {
    try {
      final success = await _watchService.startWorkout(
        workoutType: widget.workoutType,
        metadata: {
          'app': 'HabitFit',
          'version': '1.0.0',
        },
      );

      if (success) {
        setState(() {
          _isWorkoutActive = true;
          _workoutStartTime = DateTime.now();
        });

        widget.onWorkoutStart?.call();

        // 실시간 데이터 전송 시작
        _startRealTimeDataSync();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⌚ 워치에 운동 시작 알림을 전송했습니다'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ 워치 연결에 실패했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ 운동 시작 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('운동 시작 오류: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _endWorkout() async {
    try {
      final success = await _watchService.endWorkout(
        distance: _totalDistance,
        calories: _totalCalories,
        averageHeartRate: _currentHeartRate > 0 ? _currentHeartRate : null,
        metadata: {
          'totalSteps': _totalSteps,
          'workoutDuration': _workoutStartTime != null
              ? DateTime.now().difference(_workoutStartTime!).inMinutes
              : 0,
        },
      );

      if (success) {
        widget.onWorkoutData
            ?.call(_totalDistance, _totalCalories, _currentHeartRate);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⌚ 워치에 운동 데이터를 저장했습니다'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ 워치 데이터 저장에 실패했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() {
        _isWorkoutActive = false;
        _workoutStartTime = null;
        _currentHeartRate = 0;
        _totalSteps = 0;
        _totalCalories = 0.0;
        _totalDistance = 0.0;
      });

      widget.onWorkoutEnd?.call();
    } catch (e) {
      print('❌ 운동 종료 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('운동 종료 오류: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startRealTimeDataSync() {
    // 실시간 데이터 전송 (심박수, 걸음수, 칼로리)
    // 실제 구현에서는 센서 데이터를 받아서 처리
    _simulateRealTimeData();
  }

  void _simulateRealTimeData() {
    if (!_isWorkoutActive) return;

    // 심박수 시뮬레이션 (120-160 BPM)
    _currentHeartRate = 120 + (DateTime.now().millisecond % 40);
    _watchService.sendHeartRateToWatch(_currentHeartRate);

    // 걸음 수 시뮬레이션 (운동 시간에 비례)
    if (_workoutStartTime != null) {
      final duration = DateTime.now().difference(_workoutStartTime!);
      _totalSteps = (duration.inSeconds * 2).toInt(); // 초당 2걸음
      _watchService.sendStepsToWatch(_totalSteps);
    }

    // 칼로리 시뮬레이션 (운동 시간에 비례)
    if (_workoutStartTime != null) {
      final duration = DateTime.now().difference(_workoutStartTime!);
      _totalCalories = duration.inMinutes * 8.0; // 분당 8칼로리
      _watchService.sendCaloriesToWatch(_totalCalories);
    }

    // 거리 시뮬레이션 (걸음 수 기반)
    _totalDistance = _totalSteps * 0.0007; // 걸음당 약 0.7m

    setState(() {});

    // 5초마다 데이터 업데이트
    Future.delayed(Duration(seconds: 5), _simulateRealTimeData);
  }

  Future<void> _pauseWorkout() async {
    try {
      await _watchService.pauseWorkout();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏸️ 워치에 운동 일시정지 알림을 전송했습니다'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      print('❌ 운동 일시정지 오류: $e');
    }
  }

  Future<void> _resumeWorkout() async {
    try {
      await _watchService.resumeWorkout();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('▶️ 워치에 운동 재개 알림을 전송했습니다'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      print('❌ 운동 재개 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 워치 연결 상태
            Row(
              children: [
                Icon(
                  _isConnected ? Icons.watch : Icons.watch_off,
                  color: _isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _isConnected ? 'Apple Watch 연결됨' : 'Apple Watch 연결되지 않음',
                  style: TextStyle(
                    color: _isConnected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _initializeWatch,
                  tooltip: '연결 상태 새로고침',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 운동 제어 버튼
            if (_isConnected) ...[
              if (!_isWorkoutActive) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _startWorkout,
                    icon: const Icon(Icons.play_arrow),
                    label: Text('${widget.workoutType} 시작 (워치 연동)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ] else ...[
                // 운동 중 상태
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${widget.workoutType} 진행 중',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            _workoutStartTime != null
                                ? '${DateTime.now().difference(_workoutStartTime!).inMinutes}분'
                                : '0분',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _pauseWorkout,
                              icon: const Icon(Icons.pause),
                              label: const Text('일시정지'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _endWorkout,
                              icon: const Icon(Icons.stop),
                              label: const Text('종료'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 실시간 데이터 표시
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '실시간 데이터 (워치로 전송 중)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDataItem(
                              '💓', '심박수', '${_currentHeartRate}BPM'),
                          _buildDataItem('👟', '걸음수', '$_totalSteps걸음'),
                          _buildDataItem('🔥', '칼로리',
                              '${_totalCalories.toStringAsFixed(0)}kcal'),
                          _buildDataItem('📏', '거리',
                              '${_totalDistance.toStringAsFixed(2)}km'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              // 워치 연결 안됨
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.red,
                      size: 32,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Apple Watch가 연결되지 않았습니다',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'iPhone과 Apple Watch가 연결되어 있는지 확인해주세요',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataItem(String emoji, String label, String value) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
