import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;

// 웹에서는 tflite_flutter를 사용하지 않음
import 'package:tflite_flutter/tflite_flutter.dart'
    if (dart.library.html) 'dart:html' as tflite;

/// 식사 AI 서비스 클래스
/// AI-Hub 서버 API 또는 TensorFlow Lite 모델을 사용하여 음식 인식 및 영양소 분석
class MealAIService {
  static const String _modelPath = 'assets/models/food_classification.tflite';
  static const String _labelsPath = 'assets/models/food_labels.txt';
  static const String _nutritionDbPath =
      'assets/models/nutrition_database.json';

  // AI-Hub 서버 API 설정
  static const String _aihubServerUrl = 'http://localhost:5001';
  static const bool _useAihubServer = true; // AI-Hub 더미 서버 사용 (800개 한국 음식)

  dynamic _interpreter; // 웹 호환성을 위해 dynamic 사용
  List<String> _labels = [];
  Map<String, dynamic> _nutritionDatabase = {};
  final bool _isWeb = kIsWeb;

  // 2단계 파이프라인을 위한 다중클래스 모델 (향후 추가)
  dynamic _multiclassInterpreter;
  final List<String> _multiclassLabels = [];

  /// 라벨을 파일에서 읽기 (Food-101 지원)
  Future<List<String>> _loadLabels() async {
    // Food-101 라벨 파일들 시도
    const labelPaths = [
      'assets/models/food_labels.txt', // 새로운 MobileNetV3 모델
      'assets/models/food_labels_multiclass.txt', // 기존 다중클래스 모델
    ];

    for (final path in labelPaths) {
      try {
        final content = await rootBundle.loadString(path);
        final lines = content
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (lines.isNotEmpty) {
          print('🏷️ 라벨 로드 성공: $path (${lines.length}개)');
          print('   예시: ${lines.take(5).toList()}');
          return lines;
        }
      } catch (e) {
        print('⚠️ 라벨 로드 실패: $path - $e');
      }
    }
    print('⚠️ 모든 라벨 파일 로드 실패, 폴백 사용');
    return [
      'apple_pie',
      'pizza',
      'hamburger',
      'sushi',
      'pasta'
    ]; // Food-101 기본 폴백
  }

  /// 영양소 데이터베이스에서 다중클래스 라벨 생성
  Future<void> _loadMulticlassLabels() async {
    try {
      final nutritionData = _nutritionDatabase;
      _multiclassLabels.clear();
      _multiclassLabels.addAll(nutritionData.keys.toList()..sort());
      print('🍽️ 다중클래스 라벨 로드 완료: ${_multiclassLabels.length}개');
      print('   예시: ${_multiclassLabels.take(5).toList()}');
    } catch (e) {
      print('❌ 다중클래스 라벨 로드 실패: $e');
      // 기본 라벨로 폴백
      _multiclassLabels
          .addAll(['pizza', 'hamburger', 'sushi', 'pasta', 'salad']);
    }
  }

  /// 모델 초기화
  Future<void> initialize() async {
    try {
      if (_isWeb) {
        // 웹에서는 모델 로드 생략
        print('🌐 웹 환경: TensorFlow Lite 모델 로드 생략');
      } else {
        // 모바일에서는 TensorFlow Lite 모델 로드
        _interpreter = await tflite.Interpreter.fromAsset(_modelPath);

        // 입력/출력 텐서 타입 및 크기 확인
        final inputTensor = _interpreter!.getInputTensor(0);
        final outputTensor = _interpreter!.getOutputTensor(0);
        print('📊 입력 텐서: type=${inputTensor.type}, shape=${inputTensor.shape}');
        print(
            '📊 출력 텐서: type=${outputTensor.type}, shape=${outputTensor.shape}');

        // 입력 텐서 크기 조정 및 할당
        _interpreter!.resizeInputTensor(0, [1, 224, 224, 3]);
        _interpreter!.allocateTensors();
        print('✅ 입력 텐서 크기 조정 및 할당 완료');
      }

      // 라벨 로드: 파일에서 읽기 (다중클래스 지원)
      _labels = await _loadLabels();
      print('🏷️ 라벨: $_labels');

      // 영양소 데이터베이스 로드
      final nutritionData = await rootBundle.loadString(_nutritionDbPath);
      _nutritionDatabase = json.decode(nutritionData);

      // 다중클래스 라벨 로드
      await _loadMulticlassLabels();

      print('🍽️ Meal AI Service 초기화 완료');
      print('🏷️ 라벨 개수: ${_labels.length}');
      print('🍎 영양소 DB 개수: ${_nutritionDatabase.length}');
      print('🍽️ 다중클래스 라벨 개수: ${_multiclassLabels.length}');
    } catch (e) {
      print('❌ Meal AI Service 초기화 실패: $e');
      // 초기화 실패해도 기본 기능은 사용 가능
      print('⚠️ 더미 모드로 실행됩니다.');
    }
  }

  /// 음식 이미지 분석
  Future<FoodAnalysisResult> analyzeFood(File imageFile) async {
    try {
      // AI-Hub 서버 사용 시
      if (_useAihubServer) {
        return await _analyzeWithAihubServer(imageFile);
      }

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

      // 출력 클래스 수를 모델에서 읽어옴
      final outputTensor = _interpreter!.getOutputTensor(0);
      final numClasses = outputTensor.shape.last;
      print('📊 출력 텐서 shape: ${outputTensor.shape}');
      print('📊 계산된 클래스 수: $numClasses');
      print('📊 라벨 수: ${_labels.length}');

      // 출력 버퍼 준비 [1, N]
      final output = List.filled(numClasses, 0.0).reshape([1, numClasses]);

      // ★ setTensor/getTensor 쓰지 마세요 - run 사용
      final input = flattenedInput.reshape([1, 224, 224, 3]);
      _interpreter!.run(input, output);

      final predictions = (output[0] as List).cast<double>();
      print('🔍 예측: ${predictions.take(5).toList()}...');

      // top-1 선택
      int selectedIndex = 0;
      double best = -1e9;
      for (int i = 0; i < predictions.length; i++) {
        if (predictions[i] > best) {
          best = predictions[i];
          selectedIndex = i;
        }
      }
      final selectedLabel = _labels[selectedIndex];
      final confidence = predictions[selectedIndex]; // softmax라면 0~1

      print(
          '🎯 선택: $selectedLabel (${(confidence * 100).toStringAsFixed(1)}%)');

      // 다중클래스 분류 결과 그대로 사용
      final finalFoodName = selectedLabel;

      final nutrition = _getNutritionInfo(finalFoodName);

      return FoodAnalysisResult(
        foodName: finalFoodName,
        confidence: confidence,
        calories: nutrition['calories'] ?? 0,
        protein: nutrition['protein'] ?? 0.0,
        carbs: nutrition['carbs'] ?? 0.0,
        fat: nutrition['fat'] ?? 0.0,
        alternativeSuggestions:
            _getAlternativeSuggestions(finalFoodName, predictions),
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
  /// 중앙 크롭으로 정사각형 이미지 만들기
  img.Image _centerCropSquare(img.Image src) {
    final s = src.width < src.height ? src.width : src.height;
    final x = (src.width - s) ~/ 2;
    final y = (src.height - s) ~/ 2;
    return img.copyCrop(src, x: x, y: y, width: s, height: s);
  }

  Future<List<List<List<List<double>>>>> _preprocessImage(
      File imageFile) async {
    try {
      print('🖼️ 이미지 전처리 시작: ${imageFile.path}');

      // 1. 이미지 파일 읽기
      final imageBytes = await imageFile.readAsBytes();
      print('📁 이미지 크기: ${imageBytes.length} bytes');

      if (imageBytes.isEmpty) {
        throw Exception('이미지 파일이 비어있습니다.');
      }

      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('이미지를 디코딩할 수 없습니다. 지원되지 않는 형식일 수 있습니다.');
      }

      print('✅ 이미지 형식: ${image.format}');

      print('✅ 이미지 디코딩 성공: ${image.width}x${image.height}');

      // 2. EXIF 회전 보정
      final orientedImage = img.bakeOrientation(image);
      print('✅ EXIF 회전 보정 완료: ${orientedImage.width}x${orientedImage.height}');

      // 3. 중앙 크롭으로 정사각형 만들기
      final croppedImage = _centerCropSquare(orientedImage);
      print('✅ 중앙 크롭 완료: ${croppedImage.width}x${croppedImage.height}');

      // 3. 224x224로 리사이즈
      final resizedImage = img.copyResize(
        croppedImage,
        width: 224,
        height: 224,
        interpolation: img.Interpolation.linear,
      );

      print('✅ 이미지 리사이즈 완료: ${resizedImage.width}x${resizedImage.height}');

      // 3. RGB로 변환 및 정규화 (0-1 범위) - 4차원 배열로 변환 [1, 224, 224, 3]
      final List<List<List<List<double>>>> processedImage = [];

      // 배치 차원 추가
      final List<List<List<double>>> batch = [];

      for (int y = 0; y < 224; y++) {
        final List<List<double>> row = [];
        for (int x = 0; x < 224; x++) {
          try {
            final pixel = resizedImage.getPixel(x, y);
            // MobileNetV3 스타일 정규화 [-1, 1]
            final r = (pixel.r / 127.5) - 1.0;
            final g = (pixel.g / 127.5) - 1.0;
            final b = (pixel.b / 127.5) - 1.0;
            row.add([r, g, b]); // [R, G, B]
          } catch (pixelError) {
            print('⚠️ 픽셀 접근 에러 at ($x, $y): $pixelError');
            // 에러 시 기본값 사용 ([-1, 1] 범위)
            row.add([0.0, 0.0, 0.0]);
          }
        }
        batch.add(row);
      }

      processedImage.add(batch); // [1, 224, 224, 3]

      return processedImage;
    } catch (e) {
      print('❌ 이미지 전처리 실패: $e');
      print('스택 트레이스: ${StackTrace.current}');
      // 실패 시 더미 데이터 반환 [1, 224, 224, 3] ([-1, 1] 범위)
      return List.generate(
          1,
          (_) => List.generate(
              224, (_) => List.generate(224, (_) => [0.0, 0.0, 0.0])));
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

  /// 다중클래스 모델 초기화 (향후 구현)
  Future<void> initializeMulticlassModel() async {
    try {
      // TODO: 다중클래스 모델 파일 로드
      // const multiclassModelPath = 'assets/models/food_classification_multiclass.tflite';
      // _multiclassInterpreter = await Interpreter.fromAsset(multiclassModelPath);

      print('🍽️ 다중클래스 모델 초기화 (현재 미구현)');
      print('   라벨 개수: ${_multiclassLabels.length}');
    } catch (e) {
      print('❌ 다중클래스 모델 초기화 실패: $e');
    }
  }

  /// 2단계: 다중클래스 모델로 구체적인 음식 분류
  Future<String> _classifySpecificFood(
      List<List<List<List<double>>>> inputImage) async {
    try {
      if (_multiclassInterpreter == null || _multiclassLabels.isEmpty) {
        // 다중클래스 모델이 없으면 기본값 반환
        return '피자';
      }

      // 4차원 배열을 1차원으로 평탄화
      final flattenedInput = inputImage
          .expand(
              (batch) => batch.expand((row) => row.expand((pixel) => pixel)))
          .toList();

      // 다중클래스 모델 추론
      final input = flattenedInput.reshape([1, 224, 224, 3]);
      final output = List.filled(_multiclassLabels.length, 0.0)
          .reshape([1, _multiclassLabels.length]);
      _multiclassInterpreter!.run(input, output);

      // 결과 파싱
      final predictions = List<double>.from(output[0]);
      final maxIndex =
          predictions.indexOf(predictions.reduce((a, b) => a > b ? a : b));
      final confidence = predictions[maxIndex];

      print('🍕 다중클래스 분류 결과:');
      print('   예측값: ${predictions.take(5).toList()}');
      print('   선택된 인덱스: $maxIndex');
      print('   선택된 음식: ${_multiclassLabels[maxIndex]}');
      print('   신뢰도: ${(confidence * 100).toStringAsFixed(1)}%');

      return _multiclassLabels[maxIndex];
    } catch (e) {
      print('❌ 다중클래스 분류 실패: $e');
      return '피자'; // 기본값
    }
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

  /// AI-Hub 서버를 통한 음식 분석
  Future<FoodAnalysisResult> _analyzeWithAihubServer(File imageFile) async {
    try {
      print('🌐 AI-Hub 서버로 음식 분석 요청...');

      // HTTP 요청 생성
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_aihubServerUrl/predict'),
      );

      // 이미지 파일 추가
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      // 요청 전송
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final result = json.decode(responseBody);

        if (result['success'] == true && result['predictions'].isNotEmpty) {
          final prediction = result['predictions'][0];
          final foodName = prediction['food_name'];
          final confidence = prediction['confidence'];

          print(
              '✅ AI-Hub 분석 완료: $foodName (${(confidence * 100).toStringAsFixed(1)}%)');

          // 영양소 정보 가져오기
          final nutrition = _getNutritionInfo(foodName);

          // 대안 제안 생성
          final alternativeSuggestions = result['predictions']
              .skip(1)
              .take(3)
              .map((p) => p['food_name'] as String)
              .toList();

          return FoodAnalysisResult(
            foodName: foodName,
            confidence: confidence,
            calories: nutrition['calories'] ?? 300,
            protein: nutrition['protein'] ?? 15.0,
            carbs: nutrition['carbs'] ?? 45.0,
            fat: nutrition['fat'] ?? 10.0,
            alternativeSuggestions: alternativeSuggestions,
          );
        } else {
          print('⚠️ AI-Hub 서버에서 분석 결과 없음');
          return _performDummyAnalysis();
        }
      } else {
        print('❌ AI-Hub 서버 응답 오류: ${response.statusCode}');
        return _performDummyAnalysis();
      }
    } catch (e) {
      print('❌ AI-Hub 서버 분석 실패: $e');
      return _performDummyAnalysis();
    }
  }

  /// AI-Hub 서버 상태 확인
  Future<bool> checkAihubServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_aihubServerUrl/health'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result['models_loaded'] == true;
      }
      return false;
    } catch (e) {
      print('❌ AI-Hub 서버 상태 확인 실패: $e');
      return false;
    }
  }

  /// AI-Hub 서버에서 사용 가능한 음식 클래스 가져오기
  Future<List<String>> getAihubClasses() async {
    try {
      final response = await http.get(
        Uri.parse('$_aihubServerUrl/classes'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          return List<String>.from(result['classes']);
        }
      }
      return [];
    } catch (e) {
      print('❌ AI-Hub 클래스 목록 가져오기 실패: $e');
      return [];
    }
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
