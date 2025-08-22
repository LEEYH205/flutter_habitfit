import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../common/services/firestore_service.dart';

final _labelProvider = StateProvider<String?>((ref) => null);
final _kcalProvider = StateProvider<int>((ref) => 0);
final _imageFileProvider = StateProvider<File?>((ref) => null);

const FOOD_TABLE = {
  'bibimbap': 550,
  'ramen': 500,
  'kimchi_stew': 350,
  'salad': 180,
  'fried_rice': 520,
};

class MealPage extends ConsumerWidget {
  const MealPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = ref.watch(_imageFileProvider);
    final label = ref.watch(_labelProvider);
    final kcal = ref.watch(_kcalProvider);

    return SingleChildScrollView(
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
                  final x = await picker.pickImage(source: ImageSource.camera);
                  if (x != null) {
                    ref.read(_imageFileProvider.notifier).state = File(x.path);
                  }
                },
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.photo_library),
                label: const Text('갤러리에서 선택'),
                onPressed: () async {
                  final picker = ImagePicker();
                  final x = await picker.pickImage(source: ImageSource.gallery);
                  if (x != null) {
                    ref.read(_imageFileProvider.notifier).state = File(x.path);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (file != null) Image.file(file, height: 180, fit: BoxFit.cover),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: label,
            hint: const Text('음식 라벨 선택 (MVP)'),
            items: FOOD_TABLE.keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
            onChanged: (v) {
              ref.read(_labelProvider.notifier).state = v;
              ref.read(_kcalProvider.notifier).state = FOOD_TABLE[v] ?? 400;
            },
          ),
          const SizedBox(height: 8),
          Text('예상 칼로리: ${kcal > 0 ? "$kcal kcal" : "-"}'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Firestore 저장'),
            onPressed: label == null
                ? null
                : () async {
                    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
                    await Fs.instance.addMeal(uid, DateTime.now(), label!, ref.read(_kcalProvider), null);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('식사 기록 저장됨')));
                    }
                  },
          ),
          const SizedBox(height: 24),
          const Text('※ MVP: 자동 인식 대신 라벨 선택 → 평균 kcal 매핑', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
