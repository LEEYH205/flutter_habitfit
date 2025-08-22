// TFLite API 호환성 문제로 인해 임시 주석 처리
// TODO: 최신 TFLite Flutter API에 맞게 수정 필요

/*
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class _Pair<T1, T2> {
  final T1 item1;
  final T2 item2;
  _Pair(this.item1, this.item2);
}

abstract class PoseEstimator {
  void setThresholds({required double downEnter, required double upExit, required int smoothWin});
  List<List<double>>? get lastKeypoints;
  double? get lastAngle;
  Future<int> process(CameraImage image);
  void dispose();
}

class MoveNetPoseEstimator implements PoseEstimator {
  Interpreter? _interpreter;
  TensorType? _inType;
  List<int>? _inShape;
  int _iw = 192, _ih = 192;
  
  double _downEnter = 120.0;
  double _upExit = 160.0;
  int _smoothWin = 5;
  
  List<List<double>>? _lastKps;
  double? _lastSmoothedAngle;
  final List<double> _angleBuf = [];
  String _phase = 'idle';
  int _reps = 0;

  Future<void> load() async {
    _interpreter = await Interpreter.fromAsset('assets/models/movenet.tflite');
    _interpreter!.allocateTensors();
    final input = _interpreter!.getInputTensor(0);
    _inType = input.type;
    _inShape = input.shape;
    if (_inShape!.length == 4) {
      _ih = _inShape![1];
      _iw = _inShape![2];
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
    // TFLite API 호환성 문제로 임시 구현
    return 0;
  }

  @override
  void dispose() {
    try { _interpreter?.close(); } catch (_) {}
  }
}
*/

import 'package:camera/camera.dart';

// 임시 더미 구현
abstract class PoseEstimator {
  Future<void> load();
  void setThresholds(
      {required double downEnter,
      required double upExit,
      required int smoothWin});
  List<List<double>>? get lastKeypoints;
  double? get lastAngle;
  Future<int> process(CameraImage image);
  void dispose();
}

class MoveNetPoseEstimator implements PoseEstimator {
  @override
  Future<void> load() async {
    // TFLite API 호환성 문제로 임시 구현
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  void setThresholds(
      {required double downEnter,
      required double upExit,
      required int smoothWin}) {}

  @override
  List<List<double>>? get lastKeypoints => null;

  @override
  double? get lastAngle => null;

  @override
  Future<int> process(CameraImage image) async => 0;

  @override
  void dispose() {}
}
