
import 'healthkit_route_plugin_platform_interface.dart';

class HealthkitRoutePlugin {
  Future<String?> getPlatformVersion() {
    return HealthkitRoutePluginPlatform.instance.getPlatformVersion();
  }
}
