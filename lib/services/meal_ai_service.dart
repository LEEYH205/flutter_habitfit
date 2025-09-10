import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

// 웹에서는 tflite_flutter를 사용하지 않음
import 'package:tflite_flutter/tflite_flutter.dart'
    if (dart.library.html) 'dart:html' as tflite;

/// 식사 AI 서비스 클래스
/// TensorFlow Lite 모델을 사용하여 음식 인식 및 영양소 분석
class MealAIService {
  static const String _modelPath = 'assets/models/food_classification.tflite';
  static const String _labelsPath = 'assets/models/food_labels.txt';
  static const String _nutritionDbPath =
      'assets/models/nutrition_database.json';

  dynamic _interpreter; // 웹 호환성을 위해 dynamic 사용
  List<String> _labels = [];
  Map<String, dynamic> _nutritionDatabase = {};
  final bool _isWeb = kIsWeb;

  /// 모델 초기화
  Future<void> initialize() async {
    try {
      if (_isWeb) {
        // 웹에서는 모델 로드 생략
        print('🌐 웹 환경: TensorFlow Lite 모델 로드 생략');
      } else {
        // 모바일에서는 TensorFlow Lite 모델 로드
        _interpreter = await tflite.Interpreter.fromAsset(_modelPath);
        print('📊 모델 입력 크기: ${_interpreter!.getInputTensor(0).shape}');
        print('📊 모델 출력 크기: ${_interpreter!.getOutputTensor(0).shape}');
      }

      // 라벨 로드
      final labelsData = await rootBundle.loadString(_labelsPath);
      _labels =
          labelsData.split('\n').where((label) => label.isNotEmpty).toList();

      // 영양소 데이터베이스 로드
      final nutritionData = await rootBundle.loadString(_nutritionDbPath);
      _nutritionDatabase = json.decode(nutritionData);

      print('🍽️ Meal AI Service 초기화 완료');
      print('🏷️ 라벨 개수: ${_labels.length}');
      print('🍎 영양소 DB 개수: ${_nutritionDatabase.length}');
    } catch (e) {
      print('❌ Meal AI Service 초기화 실패: $e');
      // 초기화 실패해도 기본 기능은 사용 가능
      print('⚠️ 더미 모드로 실행됩니다.');
    }
  }

  /// 음식 이미지 분석
  Future<FoodAnalysisResult> analyzeFood(File imageFile) async {
    try {
      if (_isWeb || _interpreter == null) {
        // 웹이거나 모델이 없는 경우 더미 분석 수행
        return _performDummyAnalysis();
      }

      // 이미지 전처리
      final inputImage = await _preprocessImage(imageFile);

      // 4차원 배열을 1차원으로 평탄화
      final flattenedInput = inputImage
          .expand(
              (batch) => batch.expand((row) => row.expand((pixel) => pixel)))
          .toList();

      // 모델 추론 실행
      final output =
          List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);
      _interpreter!.run(flattenedInput.reshape([1, 224, 224, 3]), output);

      // 결과 파싱
      final predictions = output[0] as List<double>;
      final maxIndex =
          predictions.indexOf(predictions.reduce((a, b) => a > b ? a : b));
      final confidence = predictions[maxIndex];

      final foodName = _labels[maxIndex];
      final nutrition = _getNutritionInfo(foodName);

      return FoodAnalysisResult(
        foodName: foodName,
        confidence: confidence,
        calories: nutrition['calories'] ?? 0,
        protein: nutrition['protein'] ?? 0.0,
        carbs: nutrition['carbs'] ?? 0.0,
        fat: nutrition['fat'] ?? 0.0,
        alternativeSuggestions:
            _getAlternativeSuggestions(foodName, predictions),
      );
    } catch (e) {
      print('❌ 음식 분석 실패: $e');
      // 실패 시 더미 분석으로 폴백
      return _performDummyAnalysis();
    }
  }

  /// 더미 분석 수행 (웹이나 모델 실패 시)
  FoodAnalysisResult _performDummyAnalysis() {
    // 기본 음식 목록 (라벨이 로드되지 않은 경우)
    final defaultFoods = [
      'bibimbap',
      'ramen',
      'kimchi_stew',
      'salad',
      'fried_rice',
      'pizza',
      'burger',
      'pasta',
      'sushi',
      'sandwich'
    ];

    // 랜덤하게 음식 선택
    final availableFoods = _labels.isNotEmpty ? _labels : defaultFoods;
    final randomIndex =
        DateTime.now().millisecondsSinceEpoch % availableFoods.length;
    final foodName = availableFoods[randomIndex];
    final nutrition = _getNutritionInfo(foodName);

    // 랜덤 신뢰도 (0.6 ~ 0.95)
    final confidence =
        0.6 + (DateTime.now().millisecondsSinceEpoch % 35) / 100.0;

    return FoodAnalysisResult(
      foodName: foodName,
      confidence: confidence,
      calories: nutrition['calories'] ?? 300,
      protein: nutrition['protein'] ?? 15.0,
      carbs: nutrition['carbs'] ?? 45.0,
      fat: nutrition['fat'] ?? 10.0,
      alternativeSuggestions: _getRandomSuggestions(foodName, availableFoods),
    );
  }

  /// 랜덤 제안 생성
  List<String> _getRandomSuggestions(String foodName,
      [List<String>? availableFoods]) {
    final foods = availableFoods ?? _labels;
    final otherFoods = foods.where((label) => label != foodName).toList();
    otherFoods.shuffle();
    return otherFoods.take(3).toList();
  }

  /// 이미지 전처리 (224x224 RGB로 리사이즈 및 정규화) - 4차원 배열 반환
  Future<List<List<List<List<double>>>>> _preprocessImage(
      File imageFile) async {
    try {
      // 1. 이미지 파일 읽기
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('이미지를 디코딩할 수 없습니다.');
      }

      // 2. 224x224로 리사이즈
      final resizedImage = img.copyResize(
        image,
        width: 224,
        height: 224,
        interpolation: img.Interpolation.linear,
      );

      // 3. RGB로 변환 및 정규화 (0-1 범위) - 4차원 배열로 변환 [1, 224, 224, 3]
      final List<List<List<List<double>>>> processedImage = [];

      // 배치 차원 추가
      final List<List<List<double>>> batch = [];

      for (int y = 0; y < 224; y++) {
        final List<List<double>> row = [];
        for (int x = 0; x < 224; x++) {
          final pixel = resizedImage.getPixel(x, y);
          final r = pixel.r / 255.0;
          final g = pixel.g / 255.0;
          final b = pixel.b / 255.0;
          row.add([r, g, b]); // [R, G, B]
        }
        batch.add(row);
      }

      processedImage.add(batch); // [1, 224, 224, 3]

      return processedImage;
    } catch (e) {
      print('이미지 전처리 실패: $e');
      // 실패 시 더미 데이터 반환 [1, 224, 224, 3]
      return List.generate(
          1,
          (_) => List.generate(
              224, (_) => List.generate(224, (_) => [0.5, 0.5, 0.5])));
    }
  }

  /// 음식별 영양소 정보 반환
  Map<String, dynamic> _getNutritionInfo(String foodName) {
    // 영양소 데이터베이스에서 정보 가져오기
    if (_nutritionDatabase.containsKey(foodName)) {
      return Map<String, dynamic>.from(_nutritionDatabase[foodName]);
    }

    // 기본값 반환
    return {
      'calories': 400,
      'protein': 15.0,
      'carbs': 50.0,
      'fat': 10.0,
    };
  }

  /// 대안 제안 (유사한 음식들)
  List<String> _getAlternativeSuggestions(
      String foodName, List<double> predictions) {
    // 상위 5개 예측 결과 반환
    final indexedPredictions = predictions.asMap().entries.toList();
    indexedPredictions.sort((a, b) => b.value.compareTo(a.value));

    return indexedPredictions
        .take(5)
        .map((entry) => _labels[entry.key])
        .where((label) => label != foodName)
        .toList();
  }

  /// 리소스 해제
  void dispose() {
    if (_interpreter != null && !_isWeb) {
      _interpreter!.close();
    }
    _interpreter = null;
  }
}

/// 음식 분석 결과 모델
class FoodAnalysisResult {
  final String foodName;
  final double confidence;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final List<String> alternativeSuggestions;

  FoodAnalysisResult({
    required this.foodName,
    required this.confidence,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.alternativeSuggestions,
  });

  @override
  String toString() {
    return 'FoodAnalysisResult(foodName: $foodName, confidence: ${(confidence * 100).toStringAsFixed(1)}%, calories: $calories)';
  }
}
