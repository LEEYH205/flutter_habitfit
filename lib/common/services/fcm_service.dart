
import 'package:firebase_messaging/firebase_messaging.dart';

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  Future<void> init() async {
    final messaging = FirebaseMessaging.instance;

    // iOS foreground permission
    await messaging.requestPermission(
      alert: true, badge: true, sound: true,
      provisional: false,
    );

    // Get token (for testing)
    final token = await messaging.getToken();
    // ignore: avoid_print
    print('FCM token: $token');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // ignore: avoid_print
      print('Foreground message: ${message.messageId}');
    });
  }
}
