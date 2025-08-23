import 'dart:math';

/// 푸시업 운동 감지를 위한 클래스
class PushUpDetector {
  // MoveNet 키포인트 인덱스
  static const int LEFT_SHOULDER = 5; // 왼쪽 어깨
  static const int LEFT_ELBOW = 7; // 왼쪽 팔꿈치
  static const int LEFT_WRIST = 9; // 왼쪽 손목
  static const int RIGHT_SHOULDER = 6; // 오른쪽 어깨
  static const int RIGHT_ELBOW = 8; // 오른쪽 팔꿈치
  static const int RIGHT_WRIST = 10; // 오른쪽 손목

  // 푸시업 상태
  String _pushUpPhase = 'idle'; // 'idle', 'down', 'up'
  int _repCount = 0;
  double? _lastAngle;

  // 각도 임계값 (조정 가능)
  static const double DOWN_THRESHOLD = 90.0; // 팔꿈치가 90도 이하로 내려가면 'down' 상태
  static const double UP_THRESHOLD = 160.0; // 팔꿈치가 160도 이상으로 올라가면 'up' 상태

  // 최소 신뢰도 임계값 (푸시업은 더 낮게 설정)
  static const double MIN_CONFIDENCE = 0.2;

  /// 푸시업 상태 가져오기
  String get pushUpPhase => _pushUpPhase;

  /// 푸시업 횟수 가져오기
  int get repCount => _repCount;

  /// 마지막 각도 가져오기
  double? get lastAngle => _lastAngle;

  /// 푸시업 감지 및 상태 업데이트
  int detectPushUp(List<Map<String, double>> keypoints) {
    if (keypoints.length < 17) return 0;

    // 왼쪽과 오른쪽 팔꿈치 각도 모두 계산 시도
    double? leftAngle = _calculateElbowAngle(
        keypoints[LEFT_SHOULDER], keypoints[LEFT_ELBOW], keypoints[LEFT_WRIST]);

    double? rightAngle = _calculateElbowAngle(keypoints[RIGHT_SHOULDER],
        keypoints[RIGHT_ELBOW], keypoints[RIGHT_WRIST]);

    // 더 신뢰할 수 있는 각도 선택 (null이 아닌 것)
    double? currentAngle = leftAngle ?? rightAngle;

    if (currentAngle == null) {
      _lastAngle = null;
      return 0;
    }

    _lastAngle = currentAngle;

    // 푸시업 상태 머신
    int repIncrement = _updatePushUpState(currentAngle);

    if (repIncrement > 0) {
      _repCount += repIncrement;
      print(
          '💪 푸시업 완료! Count: $_repCount (각도: ${currentAngle.toStringAsFixed(1)}°)');
    }

    return repIncrement;
  }

  /// 팔꿈치 각도 계산
  double? _calculateElbowAngle(Map<String, double> shoulder,
      Map<String, double> elbow, Map<String, double> wrist) {
    // 신뢰도 확인
    if ((shoulder['confidence'] ?? 0) < MIN_CONFIDENCE ||
        (elbow['confidence'] ?? 0) < MIN_CONFIDENCE ||
        (wrist['confidence'] ?? 0) < MIN_CONFIDENCE) {
      return null;
    }

    // 좌표 추출
    final sx = shoulder['x'] ?? 0.0;
    final sy = shoulder['y'] ?? 0.0;
    final ex = elbow['x'] ?? 0.0;
    final ey = elbow['y'] ?? 0.0;
    final wx = wrist['x'] ?? 0.0;
    final wy = wrist['y'] ?? 0.0;

    // 벡터 계산: 어깨→팔꿈치, 팔꿈치→손목
    final v1x = ex - sx, v1y = ey - sy; // 어깨→팔꿈치
    final v2x = wx - ex, v2y = wy - ey; // 팔꿈치→손목

    // 내적 계산
    final dot = v1x * v2x + v1y * v2y;

    // 벡터 크기 계산
    final m1 = sqrt(v1x * v1x + v1y * v1y);
    final m2 = sqrt(v2x * v2x + v2y * v2y);

    if (m1 == 0 || m2 == 0) return null;

    // 코사인 각도 계산
    final cosT = (dot / (m1 * m2)).clamp(-1.0, 1.0);
    final angle = acos(cosT) * 180.0 / pi;

    return angle;
  }

  /// 푸시업 상태 업데이트
  int _updatePushUpState(double angle) {
    int repIncrement = 0;

    switch (_pushUpPhase) {
      case 'idle':
        if (angle < DOWN_THRESHOLD) {
          _pushUpPhase = 'down';
          print(
              '🔄 PushUp State: idle → down (각도: ${angle.toStringAsFixed(1)}°)');
        }
        break;

      case 'down':
        if (angle > UP_THRESHOLD) {
          _pushUpPhase = 'up';
          repIncrement = 1; // 푸시업 완료!
          print(
              '🔄 PushUp State: down → up (각도: ${angle.toStringAsFixed(1)}°)');
          print('💪 PushUp completed! Count: ${_repCount + 1}');
          // idle로 돌아가지 않고 up 상태 유지
        }
        break;

      case 'up':
        if (angle < DOWN_THRESHOLD) {
          _pushUpPhase = 'down';
          print(
              '🔄 PushUp State: up → down (각도: ${angle.toStringAsFixed(1)}°)');
        }
        break;
    }

    return repIncrement;
  }

  /// 상태 초기화
  void reset() {
    _pushUpPhase = 'idle';
    _repCount = 0;
    _lastAngle = null;
  }

  /// 디버그 정보 출력
  void debugInfo() {
    print(
        '📊 푸시업 상태: $_pushUpPhase, 횟수: $_repCount, 각도: ${_lastAngle?.toStringAsFixed(1) ?? "null"}°');
  }
}
