import 'package:cloud_firestore/cloud_firestore.dart';

class Fs {
  Fs._();
  static final Fs instance = Fs._();
  final _db = FirebaseFirestore.instance;

  Future<void> setHabitDone(String uid, DateTime day, bool done) async {
    final id = _dateId(day);
    await _db.collection('habits').doc('$uid-$id').set({
      'uid': uid,
      'date': id,
      'done': done,
      'ts': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> addWorkout(String uid, DateTime day, int reps) async {
    final id = _dateId(day);
    await _db.collection('workouts').add({
      'uid': uid,
      'date': id,
      'type': 'squat',
      'reps': reps,
      'ts': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addMeal(String uid, DateTime day, String label, int kcal,
      String? imageUrl) async {
    final id = _dateId(day);
    await _db.collection('meals').add({
      'uid': uid,
      'date': id,
      'label': label,
      'kcal': kcal,
      'imageUrl': imageUrl,
      'ts': FieldValue.serverTimestamp(),
    });
  }

  static String _dateId(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
