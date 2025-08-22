
// MoveNet(TFLite) 구현 + 스켈레톤 오버레이용 키포인트 제공 + 히스테리시스/이동평균 스무딩 + 임계값 주입(setThresholds)
// 모델 파일: assets/models/movenet.tflite (singlepose lightning 192x192 권장)

import 'dart:math' as math;
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

abstract class PoseEstimator {
  Future<void> load();
  Future<int> process(CameraImage image); // 반환: rep 증가량(0 또는 1)
  List<List<double>>? get lastKeypoints;  // [ [y,x,score], ... 17개, 0~1 정규화 ]
  double? get lastAngle;                  // 마지막 스무딩 각도(무릎)
  void setThresholds({required double downEnter, required double upExit, required int smoothWin});
  void dispose();
}

class MoveNetEstimator implements PoseEstimator {
  late Interpreter _interpreter;
  late TfLiteType _inType;
  late List<int> _inShape; // [1, H, W, 3]
  int _iw = 192, _ih = 192;

  // 상태
  String _phase = 'idle';     // idle/down
  int _reps = 0;

  // 임계값 & 스무딩
  double _downEnter = 100.0;
  double _upExit = 160.0;
  int _smoothWin = 5;
  final List<double> _angleBuf = [];

  // 출력 정보
  List<List<double>>? _lastKps; // 17x3
  double? _lastSmoothedAngle;

  @override
  Future<void> load() async {
    _interpreter = await Interpreter.fromAsset('assets/models/movenet.tflite');
    _interpreter.allocateTensors();
    final input = _interpreter.getInputTensor(0);
    _inType = input.type;
    _inShape = input.shape; // [1, 192, 192, 3] 예상
    if (_inShape.length == 4) {
      _ih = _inShape[1];
      _iw = _inShape[2];
    }
  }

  @override
  void setThresholds({required double downEnter, required double upExit, required int smoothWin}) {
    _downEnter = downEnter;
    _upExit = upExit;
    _smoothWin = math.max(1, smoothWin);
  }

  @override
  List<List<double>>? get lastKeypoints => _lastKps;

  @override
  double? get lastAngle => _lastSmoothedAngle;

  @override
  Future<int> process(CameraImage image) async {
    // 입력 준비
    final inputTensor = _interpreter.getInputTensor(0);
    if (_inType == TfLiteType.uint8) {
      final bytes = _convertToRGBBytes(image, _iw, _ih);
      inputTensor.copyFromBuffer(bytes);
    } else {
      final bytes = _convertToRGBFloatBytes(image, _iw, _ih);
      inputTensor.copyFromBuffer(bytes);
    }

    // 추론
    _interpreter.invoke();

    // 출력 파싱 (singlepose: [1,1,17,3] or [1,17,3])
    final outTensor = _interpreter.getOutputTensor(0);
    final outShape = outTensor.shape;
    final outFloats = Float32List(outTensor.dataSize);
    outTensor.copyToBuffer(outFloats);

    List<List<double>> kps = List.generate(17, (_) => [0.0, 0.0, 0.0]);
    if (outShape.length == 4) {
      for (int i = 0; i < 17; i++) {
        final base = i * 3;
        kps[i][0] = outFloats[base + 0]; // y
        kps[i][1] = outFloats[base + 1]; // x
        kps[i][2] = outFloats[base + 2]; // score
      }
    } else if (outShape.length == 3) {
      for (int i = 0; i < 17; i++) {
        final base = i * 3;
        kps[i][0] = outFloats[base + 0];
        kps[i][1] = outFloats[base + 1];
        kps[i][2] = outFloats[base + 2];
      }
    } else {
      return 0;
    }
    _lastKps = kps;

    // 무릎 각도(좌/우) 중 신뢰도 높은 값 사용
    final angleL = _kneeAngle(kps, left: true);
    final angleR = _kneeAngle(kps, left: false);
    final angle = (angleL != null && angleR != null)
        ? (angleL.item2 >= angleR.item2 ? angleL.item1 : angleR.item1)
        : (angleL?.item1 ?? angleR?.item1);
    if (angle == null) return 0;

    // 이동평균 스무딩
    _angleBuf.add(angle);
    if (_angleBuf.length > _smoothWin) _angleBuf.removeAt(0);
    final smoothed = _angleBuf.reduce((a,b) => a + b) / _angleBuf.length;
    _lastSmoothedAngle = smoothed;

    // 히스테리시스 상태머신
    int inc = 0;
    if (_phase == 'idle' && smoothed < _downEnter) {
      _phase = 'down';
    } else if (_phase == 'down' && smoothed > _upExit) {
      _reps += 1;
      inc = 1;
      _phase = 'idle';
    }
    return inc;
  }

  @override
  void dispose() {
    try { _interpreter.close(); } catch (_) {}
  }

  // ----------------- 유틸 -----------------

  (_Pair<double,double>?) _kneeAngle(List<List<double>> kps, {required bool left}) {
    final hip = left ? 11 : 12;
    final knee = left ? 13 : 14;
    final ank = left ? 15 : 16;
    final s = math.min(kps[hip][2], math.min(kps[knee][2], kps[ank][2]));
    if (s < 0.3) return null;
    final ax = kps[hip][1], ay = kps[hip][0];
    final bx = kps[knee][1], by = kps[knee][0];
    final cx = kps[ank][1], cy = kps[ank][0];
    final angle = _angle(ax, ay, bx, by, cx, cy);
    return _Pair(angle, s);
  }

  double _angle(double ax, double ay, double bx, double by, double cx, double cy) {
    final bax = ax - bx, bay = ay - by;
    final bcx = cx - bx, bcy = cy - by;
    final dot = bax * bcx + bay * bcy;
    final mag1 = math.sqrt(bax*bax + bay*bay) + 1e-9;
    final mag2 = math.sqrt(bcx*bcx + bcy*bcy) + 1e-9;
    final cos = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    return math.acos(cos) * 180.0 / math.pi;
  }

  Uint8List _convertToRGBBytes(CameraImage img, int outW, int outH) {
    final out = Uint8List(outW * outH * 3);
    if (img.format.group == ImageFormatGroup.bgra8888) {
      final plane = img.planes[0];
      final bytes = plane.bytes;
      final srcW = img.width, srcH = img.height, stride = plane.bytesPerRow;
      int di = 0;
      for (int dy = 0; dy < outH; dy++) {
        final sy = (dy * srcH) ~/ outH;
        for (int dx = 0; dx < outW; dx++) {
          final sx = (dx * srcW) ~/ outW;
          final si = sy * stride + sx * 4; // BGRA
          final b = bytes[si + 0];
          final g = bytes[si + 1];
          final r = bytes[si + 2];
          out[di++] = r;
          out[di++] = g;
          out[di++] = b;
        }
      }
      return out;
    } else {
      // YUV420
      final y = img.planes[0];
      final u = img.planes[1];
      final v = img.planes[2];
      final srcW = img.width, srcH = img.height;
      final yRow = y.bytesPerRow;
      final uRow = u.bytesPerRow;
      final vRow = v.bytesPerRow;
      final uPix = u.bytesPerPixel ?? 1;
      final vPix = v.bytesPerPixel ?? 1;
      final yBytes = y.bytes;
      final uBytes = u.bytes;
      final vBytes = v.bytes;
      int di = 0;
      for (int dy = 0; dy < outH; dy++) {
        final sy = (dy * srcH) ~/ outH;
        final uvY = sy ~/ 2;
        for (int dx = 0; dx < outW; dx++) {
          final sx = (dx * srcW) ~/ outW;
          final uvX = sx ~/ 2;
          final yi = sy * yRow + sx;
          final ui = uvY * uRow + uvX * uPix;
          final vi = uvY * vRow + uvX * vPix;

          final Y = yBytes[yi].toDouble();
          final U = uBytes[ui].toDouble();
          final V = vBytes[vi].toDouble();

          final c = Y - 16.0;
          final d = U - 128.0;
          final e = V - 128.0;
          double r = 1.164 * c + 1.596 * e;
          double g = 1.164 * c - 0.392 * d - 0.813 * e;
          double b = 1.164 * c + 2.017 * d;
          int ri = r.isNaN ? 0 : r.round().clamp(0, 255);
          int gi = g.isNaN ? 0 : g.round().clamp(0, 255);
          int bi = b.isNaN ? 0 : b.round().clamp(0, 255);

          out[di++] = ri;
          out[di++] = gi;
          out[di++] = bi;
        }
      }
      return out;
    }
  }

  Uint8List _convertToRGBFloatBytes(CameraImage img, int outW, int outH) {
    final rgb = _convertToRGBBytes(img, outW, outH);
    final f = Float32List(outW * outH * 3);
    for (int i = 0; i < rgb.length; i++) {
      f[i] = rgb[i] / 255.0;
    }
    return f.buffer.asUint8List();
  }
}

class _Pair<T1, T2> {
  final T1 item1;
  final T2 item2;
  _Pair(this.item1, this.item2);
}
