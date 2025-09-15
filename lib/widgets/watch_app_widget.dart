import 'dart:async';
import 'package:flutter/material.dart';
import '../services/watch_connectivity_service.dart';

/// Apple Watch 앱을 시뮬레이션하는 위젯
class WatchAppWidget extends StatefulWidget {
  const WatchAppWidget({super.key});

  @override
  State<WatchAppWidget> createState() => _WatchAppWidgetState();
}

class _WatchAppWidgetState extends State<WatchAppWidget> {
  final WatchConnectivityService _watchService = WatchConnectivityService();

  bool _isConnected = false;
  String _connectionState = '연결 확인 중...';
  String _currentWorkoutType = 'Running';
  bool _isWorkoutActive = false;
  bool _isWorkoutPaused = false;

  // 실시간 데이터
  double _heartRate = 0.0;
  int _steps = 0;
  double _calories = 0.0;
  Duration _workoutDuration = Duration.zero;

  Timer? _workoutTimer;
  Timer? _dataSimulationTimer;
  DateTime? _workoutStartTime;

  @override
  void initState() {
    super.initState();
    print('⌚ WatchAppWidget 초기화 시작');
    _initializeWatchService();
    _setupWatchEventListeners();
  }

  Future<void> _initializeWatchService() async {
    print('⌚ WatchService 초기화 중...');
    await _watchService.initialize();
    print('⌚ WatchService 초기화 완료');
    await _checkConnectionStatus();
    print('⌚ 연결 상태 확인 완료: $_connectionState');
  }

  void _setupWatchEventListeners() {
    // Watch에서 운동 시작 이벤트 수신
    _watchService.workoutStartStream.listen((data) {
      setState(() {
        _currentWorkoutType = data['workoutType'] ?? 'Unknown';
        _isWorkoutActive = true;
        _isWorkoutPaused = false;
        _workoutStartTime = DateTime.now();
      });
      _startWorkoutTimer();
    });

    // Watch에서 운동 종료 이벤트 수신
    _watchService.workoutEndStream.listen((data) {
      setState(() {
        _isWorkoutActive = false;
        _isWorkoutPaused = false;
        _workoutDuration = Duration.zero;
      });
      _stopWorkoutTimer();
    });

    // Watch에서 운동 일시정지 이벤트 수신
    _watchService.workoutPauseStream.listen((data) {
      setState(() {
        _isWorkoutPaused = true;
      });
      _pauseWorkoutTimer();
    });

    // Watch에서 운동 재개 이벤트 수신
    _watchService.workoutResumeStream.listen((data) {
      setState(() {
        _isWorkoutPaused = false;
      });
      _resumeWorkoutTimer();
    });

    // Watch에서 심박수 업데이트 수신
    _watchService.heartRateStream.listen((data) {
      setState(() {
        _heartRate = (data['heartRate'] as num?)?.toDouble() ?? 0.0;
      });
    });

    // Watch에서 걸음수 업데이트 수신
    _watchService.stepsStream.listen((data) {
      setState(() {
        _steps = (data['steps'] as num?)?.toInt() ?? 0;
      });
    });
  }

  Future<void> _checkConnectionStatus() async {
    try {
      print('⌚ Watch 연결 상태 확인 중...');
      final isConnected = await _watchService.isWatchConnected();
      final connectionState = await _watchService.getWatchConnectionState();

      print('⌚ 연결 상태: $isConnected, 상태: $connectionState');

      setState(() {
        _isConnected = isConnected;
        _connectionState = isConnected ? connectionState : '시뮬레이션 모드';
      });

      print('⌚ 최종 연결 상태: $_isConnected, $_connectionState');
    } catch (e) {
      print('⌚ Watch 연결 확인 실패: $e');
      // Watch 앱이 설치되지 않은 경우 시뮬레이션 모드로 설정
      setState(() {
        _isConnected = false;
        _connectionState = '시뮬레이션 모드';
      });
      print('⌚ 시뮬레이션 모드로 설정됨');
    }
  }

  void _startWorkoutTimer() {
    _workoutTimer?.cancel();
    _workoutTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_workoutStartTime != null && !_isWorkoutPaused) {
        setState(() {
          _workoutDuration = DateTime.now().difference(_workoutStartTime!);
        });
      }
    });
  }

  void _stopWorkoutTimer() {
    _workoutTimer?.cancel();
    _workoutStartTime = null;
  }

  void _pauseWorkoutTimer() {
    // 타이머는 계속 실행되지만 duration 업데이트를 중단
  }

  void _resumeWorkoutTimer() {
    if (_workoutStartTime != null) {
      // 일시정지된 시간을 보정
      final pausedDuration = _workoutDuration;
      _workoutStartTime = DateTime.now().subtract(pausedDuration);
    }
  }

  void _simulateRealTimeData() {
    print('📊 시뮬레이션 데이터 시작');
    _dataSimulationTimer?.cancel();
    _dataSimulationTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (_isWorkoutActive && !_isWorkoutPaused) {
        setState(() {
          // 심박수 시뮬레이션 (120-160 BPM) - 더 현실적인 변화
          final baseHeartRate = 120.0;
          final variation = (DateTime.now().millisecond % 40).toDouble();
          _heartRate = baseHeartRate + variation;

          // 걸음수 시뮬레이션 (운동 시간에 비례, 더 빠른 증가)
          _steps = (_workoutDuration.inSeconds * 3).clamp(0, 10000);

          // 칼로리 시뮬레이션 (운동 시간에 비례, 더 현실적인 증가)
          _calories = (_workoutDuration.inSeconds * 0.15).clamp(0, 1000);
        });

        print(
            '📊 시뮬레이션 데이터 업데이트: 심박수 ${_heartRate.toStringAsFixed(0)}BPM, 걸음수 $_steps걸음, 칼로리 ${_calories.toStringAsFixed(1)}kcal');
      } else {
        print('📊 시뮬레이션 일시정지: 운동활성=$_isWorkoutActive, 일시정지=$_isWorkoutPaused');
      }
    });
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _dataSimulationTimer?.cancel();
    _watchService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey[800]!, width: 2),
      ),
      child: Column(
        children: [
          // Watch 헤더
          Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.watch, color: Colors.white, size: 16),
                Text(
                  'HabitFit',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _connectionState == '시뮬레이션 모드'
                        ? Colors.orange
                        : (_isConnected ? Colors.green : Colors.red),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),

          // 연결 상태
          Text(
            _connectionState,
            style: TextStyle(
              color: _connectionState == '시뮬레이션 모드'
                  ? Colors.orange
                  : (_isConnected ? Colors.green : Colors.red),
              fontSize: 10,
            ),
          ),

          SizedBox(height: 8),

          // 운동 정보
          if (_isWorkoutActive) ...[
            Text(
              _currentWorkoutType,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              _formatDuration(_workoutDuration),
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),

            // 실시간 데이터
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDataColumn('💓', '${_heartRate.toInt()}', 'BPM'),
                _buildDataColumn('👟', '$_steps', '걸음'),
                _buildDataColumn('🔥', '${_calories.toInt()}', '칼로리'),
              ],
            ),
            SizedBox(height: 8),

            // 운동 상태
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _isWorkoutPaused ? Colors.orange : Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _isWorkoutPaused ? '일시정지' : '운동 중',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ] else ...[
            // 대기 상태
            Icon(
              Icons.fitness_center,
              color: Colors.grey[600],
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              '운동 대기 중',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],

          SizedBox(height: 8),

          // Watch 버튼들
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildWatchButton(
                icon: Icons.play_arrow,
                color: Colors.green,
                onTap: _startWorkout,
              ),
              _buildWatchButton(
                icon: _isWorkoutPaused ? Icons.play_arrow : Icons.pause,
                color: _isWorkoutPaused ? Colors.green : Colors.orange,
                onTap: _isWorkoutActive ? _togglePause : null,
              ),
              _buildWatchButton(
                icon: Icons.stop,
                color: Colors.red,
                onTap: _stopWorkout,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataColumn(String emoji, String value, String unit) {
    return Column(
      children: [
        Text(emoji, style: TextStyle(fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildWatchButton({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1),
        ),
        child: Icon(
          icon,
          color: color,
          size: 16,
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  void _startWorkout() async {
    print('🏃‍♂️ 운동 시작 버튼 클릭됨');

    // Watch 앱이 설치되지 않은 경우 시뮬레이션
    if (!_isConnected || _connectionState == '시뮬레이션 모드') {
      print('⌚ Watch 앱이 설치되지 않음 - 시뮬레이션 모드로 운동 시작');
      setState(() {
        _isWorkoutActive = true;
        _isWorkoutPaused = false;
        _workoutStartTime = DateTime.now();
        _heartRate = 120.0; // 초기 심박수 설정
        _steps = 0;
        _calories = 0.0;
      });
      _startWorkoutTimer();
      _simulateRealTimeData();
      return;
    }

    try {
      await _watchService.sendWorkoutStartToWatch(_currentWorkoutType);
      setState(() {
        _isWorkoutActive = true;
        _isWorkoutPaused = false;
        _workoutStartTime = DateTime.now();
      });
      _startWorkoutTimer();
    } catch (e) {
      print('❌ Watch 앱 통신 실패 - 시뮬레이션 모드로 전환: $e');
      setState(() {
        _isWorkoutActive = true;
        _isWorkoutPaused = false;
        _workoutStartTime = DateTime.now();
        _connectionState = '시뮬레이션 모드';
        _isConnected = false;
      });
      _startWorkoutTimer();
      _simulateRealTimeData();
    }
  }

  void _stopWorkout() async {
    print('🏁 운동 종료 버튼 클릭됨');

    // Watch 앱이 설치되지 않은 경우 시뮬레이션
    if (!_isConnected || _connectionState == '시뮬레이션 모드') {
      print('⌚ Watch 앱이 설치되지 않음 - 시뮬레이션 모드로 운동 종료');
      setState(() {
        _isWorkoutActive = false;
        _isWorkoutPaused = false;
        _workoutDuration = Duration.zero;
        _heartRate = 0.0;
        _steps = 0;
        _calories = 0.0;
      });
      _stopWorkoutTimer();
      _dataSimulationTimer?.cancel();
      return;
    }

    try {
      await _watchService.sendWorkoutEndToWatch(
        workoutType: _currentWorkoutType,
        duration: _workoutDuration,
        calories: _calories,
      );
      setState(() {
        _isWorkoutActive = false;
        _isWorkoutPaused = false;
        _workoutDuration = Duration.zero;
      });
      _stopWorkoutTimer();
      _dataSimulationTimer?.cancel();
    } catch (e) {
      print('❌ Watch 앱 통신 실패 - 시뮬레이션 모드로 전환: $e');
      setState(() {
        _isWorkoutActive = false;
        _isWorkoutPaused = false;
        _workoutDuration = Duration.zero;
        _connectionState = '시뮬레이션 모드';
        _isConnected = false;
      });
      _stopWorkoutTimer();
      _dataSimulationTimer?.cancel();
    }
  }

  void _togglePause() async {
    print('⏸️ 일시정지/재개 버튼 클릭됨');

    // Watch 앱이 설치되지 않은 경우 시뮬레이션
    if (!_isConnected || _connectionState == '시뮬레이션 모드') {
      print('⌚ Watch 앱이 설치되지 않음 - 시뮬레이션 모드로 일시정지/재개');
      setState(() {
        _isWorkoutPaused = !_isWorkoutPaused;
      });
      return;
    }

    try {
      if (_isWorkoutPaused) {
        await _watchService.sendWorkoutResumeToWatch();
      } else {
        await _watchService.sendWorkoutPauseToWatch();
      }
    } catch (e) {
      print('❌ Watch 앱 통신 실패 - 시뮬레이션 모드로 전환: $e');
      setState(() {
        _connectionState = '시뮬레이션 모드';
        _isConnected = false;
        _isWorkoutPaused = !_isWorkoutPaused;
      });
    }
  }
}
