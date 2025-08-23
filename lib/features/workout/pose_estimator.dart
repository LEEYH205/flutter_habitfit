import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// 포즈 추정을 위한 추상 클래스
abstract class PoseEstimator {
  Future<void> load();
  int process(dynamic image);
  List<Map<String, double>>? get lastKeypoints;
  double? get lastAngle;
  String get squatPhase;
  int get repCount;
  void dispose();

  // 새로운 메서드들
  String get exerciseType;
  String get exercisePhase;
  bool isExerciseComplete();
  double? get exerciseSpecificMetric;
}

/// MoveNet 포즈 추정기 (float16 모델 사용, 안전한 텐서 처리)
class MoveNetPoseEstimator implements PoseEstimator {
  Interpreter? _interpreter;
  List<int>? _inShape;
  int _iw = 192, _ih = 192;

  List<Map<String, double>>? _lastKps;
  double? _lastAngle;
  bool _isInitialized = false;

  // 스쿼트 감지를 위한 상태 변수
  final List<double> _angleBuffer = [];
  static const int _angleBufferSize = 5;
  String _squatPhase = 'idle'; // 'idle', 'down', 'up'
  int _repCount = 0;
  bool _busy = false; // 재진입 방지

  // 운동 타입 관련 변수
  final String _exerciseType = 'squat'; // 기본값은 스쿼트

  @override
  Future<void> load() async {
    try {
      print('Loading MoveNet model...');
      final modelPath =
          'assets/models/movenet_singlepose_lightning_float16.tflite';
      final options = InterpreterOptions()..threads = 2;

      _interpreter = await Interpreter.fromAsset(modelPath, options: options);

      // (중요) 입력 텐서 모양 강제
      final want = [1, 192, 192, 3];
      final input0 = _interpreter!.getInputTensor(0);
      if (!_listEquals(input0.shape, want)) {
        _interpreter!.resizeInputTensor(0, want);
      }
      _interpreter!.allocateTensors(); // resize 후 반드시 호출

      // 입력 텐서 정보
      final inputTensor = _interpreter!.getInputTensor(0);
      _inShape = inputTensor.shape; // 기대: [1, 192, 192, 3]
      if (_inShape!.length == 4) {
        _ih = _inShape![1];
        _iw = _inShape![2];
      }

      print(
          'MoveNet loaded. inputShape=$_inShape, inputType=${inputTensor.type}');

      // 출력 텐서 정보 확인(참고)
      final outTensor = _interpreter!.getOutputTensor(0);
      print('outputShape=${outTensor.shape}, outputType=${outTensor.type}');

      _isInitialized = true;
    } catch (e) {
      print('Failed to load MoveNet: $e');
      _isInitialized = false;
    }
  }

  // 리스트 비교 헬퍼 함수
  bool _listEquals(List<int>? a, List<int> b) {
    if (a == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int process(dynamic image) {
    if (!_isInitialized || _interpreter == null) return 0;
    if (_busy) return 0; // 재진입 방지

    _busy = true;
    try {
      // 1) 이미지 전처리
      final rgbU8 = _preprocessImageToRGB888(image as CameraImage, _iw, _ih);

      // 2) 입력 텐서 준비
      final inputTensor = _interpreter!.getInputTensor(0);
      final inputShape = inputTensor.shape; // [1,192,192,3]

      // rgbU8: Uint8List(H*W*3) 0..255 → 올바른 API 사용
      try {
        if (inputTensor.type == TensorType.float32) {
          // float32 입력: 0~1 정규화
          final f32 = Float32List(rgbU8.length);
          for (int i = 0; i < rgbU8.length; i++) {
            f32[i] = rgbU8[i] / 255.0;
          }
          inputTensor.setTo(f32);
        } else if (inputTensor.type == TensorType.uint8) {
          // uint8 입력: 직접 설정
          inputTensor.setTo(rgbU8);
        } else if (inputTensor.type == TensorType.int8) {
          // int8 입력: 양자화 파라미터 적용
          final i8 = Int8List(rgbU8.length);
          for (int i = 0; i < rgbU8.length; i++) {
            i8[i] = (rgbU8[i] - 128);
          }
          inputTensor.setTo(i8);
        } else {
          // 기본값: float32
          final f32 = Float32List(rgbU8.length);
          for (int i = 0; i < rgbU8.length; i++) {
            f32[i] = rgbU8[i] / 255.0;
          }
          inputTensor.setTo(f32);
        }
      } catch (e) {
        print('ERROR: Failed to prepare input buffer: $e');
        return 0;
      }

      // 3) 추론 실행
      final outTensor = _interpreter!.getOutputTensor(0);
      final outShape = outTensor.shape; // 보통 [1,1,17,3]
      final outElems = outShape.fold<int>(1, (a, b) => a * b);

      try {
        _interpreter!.invoke();
      } catch (e) {
        print('ERROR: Failed to run inference: $e');
        return 0;
      }

      // 출력 데이터 추출 (올바른 API: copyTo() 사용 - 4D 구조)
      List<double> flatOutput;
      try {
        // 텐서와 같은 shape [1,1,17,3]의 4차원 리스트 준비
        final output4d = List.generate(
          1,
          (_) => List.generate(
            1,
            (_) => List.generate(
              17,
              (_) => List.filled(3, 0.0),
              growable: false,
            ),
            growable: false,
          ),
          growable: false,
        );

        // 텐서에서 4D 구조로 결과 복사
        outTensor.copyTo(output4d);

        // 사용하기 쉽게 1차원으로 평탄화
        final kps = output4d[0][0]; // List<List<double>> 크기 17x3
        flatOutput = <double>[];
        for (var i = 0; i < 17; i++) {
          flatOutput.add(kps[i][0]); // y
          flatOutput.add(kps[i][1]); // x
          flatOutput.add(kps[i][2]); // score
        }
      } catch (e) {
        print('ERROR: Failed to extract output: $e');
        return 0;
      }

      // 4) 키포인트 파싱
      List<Map<String, double>> keypoints;
      try {
        keypoints = _parseKeypoints(flatOutput, outShape);
        // 스코어 체크 (가끔씩만 출력)
        if (_repCount % 30 == 0) _debugScores(keypoints);
      } catch (e) {
        print('ERROR: Failed to parse keypoints: $e');
        return 0;
      }

      _lastKps = keypoints;

      // 5) 무릎 각도 계산 및 스쿼트 감지
      double? angle;
      try {
        angle = _calculateKneeAngle(keypoints);
        // 각도가 계산될 때만 로그 출력
        if (angle != null && _repCount % 10 == 0) {
          print('🎯 Knee angle: ${angle.toStringAsFixed(1)}°');
        }
      } catch (e) {
        print('ERROR: Failed to calculate knee angle: $e');
        angle = null;
      }

      if (angle != null) _updateAngle(angle);

      int result;
      try {
        result = _detectSquatMovement();
        // 스쿼트 감지될 때만 로그 출력
        if (result > 0) {
          print('💪 Squat completed! Count: $_repCount');
        }
      } catch (e) {
        print('ERROR: Failed to detect squat movement: $e');
        result = 0;
      }

      return result;
    } catch (e) {
      print('ERROR: Pose estimation error: $e');
      print('ERROR: Stack trace: ${StackTrace.current}');
      return 0;
    } finally {
      _busy = false; // 재진입 방지 해제
    }
  }

  // 🔍 스코어 디버깅 헬퍼 메서드
  void _debugScores(List<Map<String, double>> k) {
    final ids = {
      'LHIP': 11,
      'LKNEE': 13,
      'LANK': 15,
      'RHIP': 12,
      'RKNEE': 14,
      'RANK': 16,
    };
    final line = ids.entries
        .map((e) =>
            '${e.key}=${(k[e.value]['confidence'] ?? 0).toStringAsFixed(2)}')
        .join('  ');
    print('DEBUG scores: $line');
  }

  // --- YUV/BGRA → RGB888 (Uint8List) ---
  Uint8List _preprocessImageToRGB888(CameraImage img, int outW, int outH) {
    try {
      // iOS: BGRA, Android: YUV420 (일반적)
      if (img.format.group == ImageFormatGroup.bgra8888) {
        final plane = img.planes[0];
        final srcW = img.width, srcH = img.height, stride = plane.bytesPerRow;
        final src = plane.bytes;
        final out = Uint8List(outW * outH * 3);
        int di = 0;
        for (int dy = 0; dy < outH; dy++) {
          final sy = (dy * srcH) ~/ outH;
          for (int dx = 0; dx < outW; dx++) {
            final sx = (dx * srcW) ~/ outW;
            final si = sy * stride + sx * 4; // BGRA
            final b = src[si + 0], g = src[si + 1], r = src[si + 2];
            out[di++] = r;
            out[di++] = g;
            out[di++] = b;
          }
        }
        return out;
      } else {
        // 진짜 RGB 변환: iOS YUV420 bi-planar (NV12) 또는 Android YUV420 (3 planes)
        if (img.planes.length == 2) {
          // iOS: planes[0]=Y, planes[1]=CbCr interleaved
          final yPlane = img.planes[0];
          final uvPlane = img.planes[1];

          final yBytes = yPlane.bytes;
          final uvBytes = uvPlane.bytes;
          final yStride = yPlane.bytesPerRow;
          final uvStride = uvPlane.bytesPerRow;

          final out = Uint8List(outW * outH * 3);
          for (int dy = 0; dy < outH; dy++) {
            final srcY = (dy * img.height ~/ outH);
            final srcY2 = (srcY >> 1);
            for (int dx = 0; dx < outW; dx++) {
              final srcX = (dx * img.width ~/ outW);
              final srcX2 = (srcX >> 1);

              final yIndex = srcY * yStride + srcX;
              final uvIndex = srcY2 * uvStride + srcX2 * 2;

              if (yIndex < yBytes.length && uvIndex + 1 < uvBytes.length) {
                final Y = yBytes[yIndex].toDouble();
                final Cb = uvBytes[uvIndex].toDouble();
                final Cr = uvBytes[uvIndex + 1].toDouble();

                // BT.601 full range YUV to RGB 변환
                final r = (Y + 1.402 * (Cr - 128)).round().clamp(0, 255);
                final g = (Y - 0.344136 * (Cb - 128) - 0.714136 * (Cr - 128))
                    .round()
                    .clamp(0, 255);
                final b = (Y + 1.772 * (Cb - 128)).round().clamp(0, 255);

                final dst = (dy * outW + dx) * 3;
                out[dst] = r;
                out[dst + 1] = g;
                out[dst + 2] = b;
              } else {
                final dst = (dy * outW + dx) * 3;
                out[dst] = 0;
                out[dst + 1] = 0;
                out[dst + 2] = 0;
              }
            }
          }

          return out;
        } else if (img.planes.length == 3) {
          // Android: YUV420 (3 planes)
          final yPlane = img.planes[0];
          final uPlane = img.planes[1];
          final vPlane = img.planes[2];

          final yBytes = yPlane.bytes;
          final uBytes = uPlane.bytes;
          final vBytes = vPlane.bytes;
          final yStride = yPlane.bytesPerRow;
          final uStride = uPlane.bytesPerRow;
          final vStride = vPlane.bytesPerRow;

          final out = Uint8List(outW * outH * 3);
          for (int dy = 0; dy < outH; dy++) {
            final srcY = (dy * img.height ~/ outH);
            final srcY2 = (srcY >> 1);
            for (int dx = 0; dx < outW; dx++) {
              final srcX = (dx * img.width ~/ outW);
              final srcX2 = (srcX >> 1);

              final yIndex = srcY * yStride + srcX;
              final uIndex = srcY2 * uStride + srcX2;
              final vIndex = srcY2 * vStride + srcX2;

              if (yIndex < yBytes.length &&
                  uIndex < uBytes.length &&
                  vIndex < vBytes.length) {
                final Y = yBytes[yIndex].toDouble();
                final U = uBytes[uIndex].toDouble();
                final V = vBytes[vIndex].toDouble();

                // YUV to RGB 변환
                final r = (Y + 1.402 * (V - 128)).round().clamp(0, 255);
                final g = (Y - 0.344136 * (U - 128) - 0.714136 * (V - 128))
                    .round()
                    .clamp(0, 255);
                final b = (Y + 1.772 * (U - 128)).round().clamp(0, 255);

                final dst = (dy * outW + dx) * 3;
                out[dst] = r;
                out[dst + 1] = g;
                out[dst + 2] = b;
              } else {
                final dst = (dy * outW + dx) * 3;
                out[dst] = 0;
                out[dst + 1] = 0;
                out[dst + 2] = 0;
              }
            }
          }

          return out;
        } else {
          // fallback: Y 채널만 사용
          final yPlane = img.planes[0];
          final yBytes = yPlane.bytes;
          final yStride = yPlane.bytesPerRow;

          final out = Uint8List(outW * outH * 3);
          int dst = 0;
          for (int dy = 0; dy < outH; dy++) {
            final srcY = (dy * img.height ~/ outH);
            for (int dx = 0; dx < outW; dx++) {
              final srcX = (dx * img.width ~/ outW);
              final srcIdx = srcY * yStride + srcX;
              final v = (srcIdx < yBytes.length) ? yBytes[srcIdx] : 0;
              out[dst++] = v; // R
              out[dst++] = v; // G
              out[dst++] = v; // B
            }
          }

          return out;
        }
      }
    } catch (e) {
      print('ERROR: Failed to preprocess image: $e');
      // 에러 발생 시 기본 RGB 이미지 반환
      final out = Uint8List(outW * outH * 3);
      for (int i = 0; i < out.length; i += 3) {
        out[i] = 128; // R
        out[i + 1] = 128; // G
        out[i + 2] = 128; // B
      }
      return out;
    }
  }

  // --- 출력 파서 ---
  List<Map<String, double>> _parseKeypoints(
      List<double> flat, List<int> shape) {
    // shape가 [1,1,17,3] 혹은 [1,17,3] 인 경우를 모두 커버
    final is4d = shape.length == 4 && shape.last == 3;
    final nK =
        is4d ? shape[shape.length - 2] : (shape.length == 3 ? shape[1] : 17);
    final List<Map<String, double>> kps = [];

    // ★ flat 길이가 최소 3*nK인지 사전 방어
    final need = nK * 3;
    if (flat.length < need) {
      print(
          'WARN: output too short. flat=${flat.length}, need=$need, shape=$shape');
      return List.generate(17, (_) => {'x': 0, 'y': 0, 'confidence': 0});
    }

    for (int i = 0; i < nK; i++) {
      final base = i * 3;
      final y = flat[base + 0];
      final x = flat[base + 1];
      final s = flat[base + 2];
      kps.add(s > 0.3
          ? {'x': x, 'y': y, 'confidence': s}
          : {'x': 0.0, 'y': 0.0, 'confidence': 0.0});
    }

    // 키포인트 파싱 완료 (로그 생략)
    return kps;
  }

  /// 무릎 각도 계산
  double? _calculateKneeAngle(List<Map<String, double>> keypoints) {
    if (keypoints.length < 17) return null;

    try {
      // MoveNet 키포인트 인덱스로 무릎 각도 계산
      // 왼쪽 고관절 (11), 왼쪽 무릎 (13), 왼쪽 발목 (15)
      // 오른쪽 고관절 (12), 오른쪽 무릎 (14), 오른쪽 발목 (16)

      final leftHip = keypoints[11];
      final leftKnee = keypoints[13];
      final leftAnkle = keypoints[15];

      final rightHip = keypoints[12];
      final rightKnee = keypoints[14];
      final rightAnkle = keypoints[16];

      // 더 높은 신뢰도를 가진 쪽 사용 (임계값을 0.2로 낮춤)
      double? angle;
      if (leftHip['confidence']! > 0.2 &&
          leftKnee['confidence']! > 0.2 &&
          leftAnkle['confidence']! > 0.2) {
        angle = _calculateAngle(leftHip, leftKnee, leftAnkle);
      } else if (rightHip['confidence']! > 0.2 &&
          rightKnee['confidence']! > 0.2 &&
          rightAnkle['confidence']! > 0.2) {
        angle = _calculateAngle(rightHip, rightKnee, rightAnkle);
      } else {
        // 신뢰도가 낮을 때는 가끔씩만 로그 출력
        if (_repCount % 60 == 0) {
          print(
              '⚠️ Low confidence: L(${leftHip['confidence']?.toStringAsFixed(2)},${leftKnee['confidence']?.toStringAsFixed(2)},${leftAnkle['confidence']?.toStringAsFixed(2)}) R(${rightHip['confidence']?.toStringAsFixed(2)},${rightKnee['confidence']?.toStringAsFixed(2)},${rightAnkle['confidence']?.toStringAsFixed(2)})');
        }
      }

      return angle;
    } catch (e) {
      print('Error calculating knee angle: $e');
      return null;
    }
  }

  /// 세 점 사이의 각도 계산
  double _calculateAngle(
      Map<String, double> p1, Map<String, double> p2, Map<String, double> p3) {
    // 내적을 사용하여 세 점 사이의 각도 계산
    // p1, p2, p3는 [x, y, confidence] 형태, x, y는 정규화된 [0.0, 1.0]
    final v1 = [p1['x']! - p2['x']!, p1['y']! - p2['y']!];
    final v2 = [p3['x']! - p2['x']!, p3['y']! - p2['y']!];

    final dot = v1[0] * v2[0] + v1[1] * v2[1];
    final mag1 = sqrt(v1[0] * v1[0] + v1[1] * v1[1]);
    final mag2 = sqrt(v2[0] * v2[0] + v2[1] * v2[1]);

    if (mag1 == 0 || mag2 == 0) return 180.0;

    final cosAngle = dot / (mag1 * mag2);
    final angle = acos(cosAngle.clamp(-1.0, 1.0));

    return angle * 180.0 / pi;
  }

  /// 각도 업데이트 및 평활화
  void _updateAngle(double angle) {
    _angleBuffer.add(angle);
    if (_angleBuffer.length > _angleBufferSize) {
      _angleBuffer.removeAt(0);
    }

    // 평활화된 각도 계산
    final sum = _angleBuffer.reduce((a, b) => a + b);
    _lastAngle = sum / _angleBuffer.length;
  }

  /// 스쿼트 동작 감지
  int _detectSquatMovement() {
    if (_lastAngle == null) return 0;

    final angle = _lastAngle!;

    // 스쿼트 동작 감지 로직 (개선된 상태 머신)
    switch (_squatPhase) {
      case 'idle':
        if (angle < 140.0) {
          _squatPhase = 'down';
          print('🔄 State: idle → down (angle: ${angle.toStringAsFixed(1)}°)');
        }
        break;

      case 'down':
        if (angle > 150.0) {
          _squatPhase = 'up';
          print('🔄 State: down → up (angle: ${angle.toStringAsFixed(1)}°)');
        }
        break;

      case 'up':
        if (angle < 140.0) {
          _squatPhase = 'down';
          print('🔄 State: up → down (angle: ${angle.toStringAsFixed(1)}°)');
        } else if (angle > 160.0) {
          // 완전히 서있을 때 idle로 복귀
          _squatPhase = 'idle';
          _repCount++;
          print(
              '💪 Squat completed! Count: $_repCount (angle: ${angle.toStringAsFixed(1)}°)');
          return 1; // 한 번의 반복 완료
        }
        break;
    }

    return 0;
  }

  @override
  List<Map<String, double>>? get lastKeypoints => _lastKps;

  @override
  double? get lastAngle => _lastAngle;

  @override
  String get squatPhase => _squatPhase;

  @override
  int get repCount => _repCount;

  @override
  void dispose() {
    try {
      _interpreter?.close();
    } catch (_) {}
    print('MoveNet pose estimator disposed');
  }

  // 새로운 메서드들 구현
  @override
  String get exerciseType => _exerciseType;

  @override
  String get exercisePhase => squatPhase; // 스쿼트와 호환성을 위해

  @override
  bool isExerciseComplete() => _repCount > 0;

  @override
  double? get exerciseSpecificMetric => lastAngle;
}

/// 시뮬레이션 모드 포즈 추정기 (AI 모델 대신 사용)
class SimulationPoseEstimator implements PoseEstimator {
  List<Map<String, double>>? _lastKps;
  double? _lastAngle;
  bool _isInitialized = false;
  final Random _random = Random();

  // 시뮬레이션을 위한 상태 변수
  double _time = 0.0;
  double _squatPhase = 0.0; // 0.0 ~ 1.0 (스쿼트 동작 단계)
  bool _isSquatting = false;

  // 운동 타입 관련 변수
  final String _exerciseType = 'squat';
  int _repCount = 0;

  @override
  Future<void> load() async {
    print('Simulation pose estimator loaded successfully');
    _isInitialized = true;
  }

  @override
  int process(dynamic image) {
    if (!_isInitialized) return 0;

    // 시간 기반 시뮬레이션
    _time += 0.1;

    // 스쿼트 동작 시뮬레이션 (3초 주기)
    _squatPhase = (_time % 3.0) / 3.0;

    // 스쿼트 감지 (중간 단계에서)
    if (_squatPhase > 0.3 && _squatPhase < 0.7) {
      _isSquatting = true;
      // 스쿼트 완료 시 카운트 증가
      if (_squatPhase > 0.6) {
        _repCount++;
      }
    } else {
      _isSquatting = false;
    }

    // 17개 키포인트 생성 (MoveNet과 동일한 구조)
    _lastKps = _generateSimulatedKeypoints();

    // 무릎 각도 계산
    _lastAngle = _calculateSimulatedKneeAngle();

    // 스쿼트 동작 감지 결과 반환
    return _isSquatting ? 1 : 0;
  }

  /// 시뮬레이션된 키포인트 생성
  List<Map<String, double>> _generateSimulatedKeypoints() {
    final keypoints = <Map<String, double>>[];

    // 기본 위치 (화면 중앙)
    const centerX = 0.5;
    const centerY = 0.5;

    // 17개 키포인트 (MoveNet 순서)
    final pointNames = [
      'nose',
      'left_eye',
      'right_eye',
      'left_ear',
      'right_ear',
      'left_shoulder',
      'right_shoulder',
      'left_elbow',
      'right_elbow',
      'left_wrist',
      'right_wrist',
      'left_hip',
      'right_hip',
      'left_knee',
      'right_knee',
      'left_ankle',
      'right_ankle'
    ];

    for (int i = 0; i < pointNames.length; i++) {
      final name = pointNames[i];
      double x, y, confidence;

      // 신체 부위별 위치 계산
      switch (name) {
        case 'nose':
          x = centerX + _random.nextDouble() * 0.1 - 0.05;
          y = centerY - 0.2 + _random.nextDouble() * 0.1 - 0.05;
          break;
        case 'left_shoulder':
        case 'right_shoulder':
          x = centerX + (name == 'left_shoulder' ? -0.15 : 0.15);
          y = centerY - 0.15 + _random.nextDouble() * 0.1 - 0.05;
          break;
        case 'left_elbow':
        case 'right_elbow':
          x = centerX + (name == 'left_elbow' ? -0.25 : 0.25);
          y = centerY + _random.nextDouble() * 0.1 - 0.05;
          break;
        case 'left_wrist':
        case 'right_wrist':
          x = centerX + (name == 'left_wrist' ? -0.35 : 0.35);
          y = centerY + 0.15 + _random.nextDouble() * 0.1 - 0.05;
          break;
        case 'left_hip':
        case 'right_hip':
          x = centerX + (name == 'left_hip' ? -0.1 : 0.1);
          y = centerY + 0.1 + _random.nextDouble() * 0.1 - 0.05;
          break;
        case 'left_knee':
        case 'right_knee':
          x = centerX + (name == 'left_knee' ? -0.08 : 0.08);
          // 스쿼트 동작에 따른 무릎 위치 변화
          y = centerY +
              0.3 +
              (_isSquatting ? 0.2 : 0.0) +
              _random.nextDouble() * 0.1 -
              0.05;
          break;
        case 'left_ankle':
        case 'right_ankle':
          x = centerX + (name == 'left_ankle' ? -0.05 : 0.05);
          y = centerY + 0.5 + _random.nextDouble() * 0.1 - 0.05;
          break;
        default: // 눈, 귀 등
          x = centerX + _random.nextDouble() * 0.2 - 0.1;
          y = centerY - 0.25 + _random.nextDouble() * 0.1 - 0.05;
      }

      // 신뢰도 (0.7 ~ 1.0)
      confidence = 0.7 + _random.nextDouble() * 0.3;

      keypoints.add({
        'x': x.clamp(0.0, 1.0),
        'y': y.clamp(0.0, 1.0),
        'confidence': confidence,
      });
    }

    return keypoints;
  }

  /// 시뮬레이션된 무릎 각도 계산
  double? _calculateSimulatedKneeAngle() {
    if (_lastKps == null || _lastKps!.length < 17) return null;

    try {
      // 왼쪽 무릎 각도 계산 (고관절-무릎-발목)
      final leftHip = _lastKps![11]; // left_hip
      final leftKnee = _lastKps![13]; // left_knee
      final leftAnkle = _lastKps![15]; // left_ankle

      // 스쿼트 동작에 따른 각도 변화
      double baseAngle = 170.0; // 서있는 상태
      if (_isSquatting) {
        baseAngle = 90.0 + (_squatPhase - 0.3) * 40.0; // 90도 ~ 130도
      }

      // 약간의 변동성 추가
      final variation = _random.nextDouble() * 10.0 - 5.0;
      return (baseAngle + variation).clamp(80.0, 180.0);
    } catch (e) {
      print('Error calculating simulated knee angle: $e');
      return null;
    }
  }

  @override
  List<Map<String, double>>? get lastKeypoints => _lastKps;

  @override
  double? get lastAngle => _lastAngle;

  @override
  String get squatPhase {
    if (_squatPhase < 0.3) return 'idle';
    if (_squatPhase < 0.7) return 'down';
    return 'up';
  }

  @override
  int get repCount => _repCount;

  @override
  void dispose() {
    _isInitialized = false;
    print('Simulation pose estimator disposed');
  }

  // 새로운 메서드들 구현
  @override
  String get exerciseType => _exerciseType;

  @override
  String get exercisePhase => squatPhase; // 스쿼트와 호환성을 위해

  @override
  bool isExerciseComplete() => _repCount > 0;

  @override
  double? get exerciseSpecificMetric => lastAngle;
}
