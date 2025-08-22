
import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();
  final _rc = FirebaseRemoteConfig.instance;

  Future<void> init() async {
    await _rc.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    await _rc.setDefaults(const {
      'squat_down_enter': 100.0, // 내려갈 때 진입 각도(작을수록 더 내려감)
      'squat_up_exit': 160.0,    // 올라올 때 종료 각도(클수록 더 펴짐)
      'angle_smooth_window': 5,  // 이동평균 윈도우(프레임 수)
    });
    try {
      await _rc.fetchAndActivate();
    } catch (_) {
      // 네트워크 오류 등은 무시하고 기본값 사용
    }
  }

  double get downEnter => _rc.getDouble('squat_down_enter');
  double get upExit => _rc.getDouble('squat_up_exit');
  int get smoothWindow => _rc.getInt('angle_smooth_window');
}
