import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../common/services/firestore_service.dart';
import '../../services/meal_ai_service.dart';
import '../../widgets/app_bar_with_notifications.dart';

final _imageFileProvider = StateProvider<File?>((ref) => null);
final _aiResultProvider = StateProvider<FoodAnalysisResult?>((ref) => null);
final _isAnalyzingProvider = StateProvider<bool>((ref) => false);

class MealPage extends ConsumerStatefulWidget {
  const MealPage({super.key});

  @override
  ConsumerState<MealPage> createState() => _MealPageState();
}

class _MealPageState extends ConsumerState<MealPage> {
  late MealAIService _aiService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAI();
  }

  Future<void> _initializeAI() async {
    try {
      _aiService = MealAIService();
      await _aiService.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('AI 초기화 실패: $e');
      // AI 초기화 실패해도 기본 기능은 사용 가능
    }
  }

  @override
  void dispose() {
    _aiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final file = ref.watch(_imageFileProvider);
    final aiResult = ref.watch(_aiResultProvider);
    final isAnalyzing = ref.watch(_isAnalyzingProvider);

    return Scaffold(
      appBar: const AppBarWithNotifications(title: '식사 관리'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('사진 촬영/선택'),
                  onPressed: () async {
                    final picker = ImagePicker();
                    final x =
                        await picker.pickImage(source: ImageSource.camera);
                    if (x != null) {
                      ref.read(_imageFileProvider.notifier).state =
                          File(x.path);
                    }
                  },
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('갤러리에서 선택'),
                  onPressed: () async {
                    final picker = ImagePicker();
                    final x =
                        await picker.pickImage(source: ImageSource.gallery);
                    if (x != null) {
                      ref.read(_imageFileProvider.notifier).state =
                          File(x.path);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (file != null) ...[
              Image.file(file, height: 180, fit: BoxFit.cover),
              const SizedBox(height: 16),
              if (_isInitialized) ...[
                ElevatedButton.icon(
                  icon: isAnalyzing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.psychology),
                  label: Text(isAnalyzing ? 'AI 분석 중...' : 'AI로 음식 분석'),
                  onPressed: isAnalyzing ? null : () => _analyzeWithAI(file),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],

            // AI 분석 결과 표시
            if (aiResult != null) ...[
              _buildAIResultCard(aiResult),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('식사 기록 저장'),
                  onPressed: () async {
                    final uid =
                        FirebaseAuth.instance.currentUser?.uid ?? 'anon';
                    print('🔐 식사 기록 사용자 UID: $uid');
                    await Fs.instance.addMeal(uid, DateTime.now(),
                        aiResult.foodName, aiResult.calories, null);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('식사 기록이 저장되었습니다!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// AI로 음식 분석
  Future<void> _analyzeWithAI(File imageFile) async {
    ref.read(_isAnalyzingProvider.notifier).state = true;

    try {
      final result = await _aiService.analyzeFood(imageFile);
      ref.read(_aiResultProvider.notifier).state = result;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'AI 분석 완료: ${result.foodName} (${(result.confidence * 100).toStringAsFixed(1)}%)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI 분석 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      ref.read(_isAnalyzingProvider.notifier).state = false;
    }
  }

  /// AI 분석 결과 카드
  Widget _buildAIResultCard(FoodAnalysisResult result) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.psychology,
                      color: Colors.purple, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI 분석 결과',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${(result.confidence * 100).toStringAsFixed(1)}% 신뢰도',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 음식명
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.withOpacity(0.2)),
              ),
              child: Text(
                result.foodName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            // 영양소 정보
            const Text(
              '영양소 정보',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildNutritionChip(
                      '칼로리', '${result.calories} kcal', Colors.orange),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildNutritionChip('단백질',
                      '${result.protein.toStringAsFixed(1)}g', Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildNutritionChip('탄수화물',
                      '${result.carbs.toStringAsFixed(1)}g', Colors.green),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildNutritionChip(
                      '지방', '${result.fat.toStringAsFixed(1)}g', Colors.red),
                ),
              ],
            ),

            // 유사한 음식
            if (result.alternativeSuggestions.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                '유사한 음식',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: result.alternativeSuggestions
                    .map((suggestion) => Chip(
                          label: Text(suggestion),
                          backgroundColor: Colors.grey.shade100,
                          side: BorderSide(color: Colors.grey.shade300),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 영양소 칩 위젯
  Widget _buildNutritionChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
