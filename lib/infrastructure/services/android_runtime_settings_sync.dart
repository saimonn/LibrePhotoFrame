import '../../domain/interfaces/config_provider.dart';
import 'autostart_service.dart';
import 'keep_alive_service.dart';

abstract class AndroidRuntimeSettingsWriter {
  Future<void> setAutostartEnabled(bool enabled);

  Future<void> setKeepAliveEnabled(bool enabled);
}

class SharedPreferencesAndroidRuntimeSettingsWriter
    implements AndroidRuntimeSettingsWriter {
  @override
  Future<void> setAutostartEnabled(bool enabled) {
    return AutostartService.setEnabled(enabled);
  }

  @override
  Future<void> setKeepAliveEnabled(bool enabled) {
    return KeepAliveService.setEnabled(enabled);
  }
}

/// Bridges the config.json store and the Android SharedPreferences mirror.
///
/// Two stores hold autostart/keep-alive on Android:
///
///  * [ConfigProvider] (config.json) is the canonical store and the only one a
///    user edits.
///  * The SharedPreferences mirror written here is a *runtime copy*: the
///    Android BootReceiver and WakeReceiver run before Flutter starts and can
///    only read the platform preferences.
///
/// [syncFromConfig] is the single write funnel for the mirror - it is called
/// at boot (AppInitializer) and every time the settings are saved, so the two
/// stores cannot drift (issue 16).
class AndroidRuntimeSettingsSync {
  final AndroidRuntimeSettingsWriter _writer;

  AndroidRuntimeSettingsSync({AndroidRuntimeSettingsWriter? writer})
      : _writer = writer ?? SharedPreferencesAndroidRuntimeSettingsWriter();

  Future<void> syncFromConfig(ConfigProvider configProvider) async {
    await _writer.setAutostartEnabled(configProvider.autostartOnBoot);
    await _writer.setKeepAliveEnabled(configProvider.keepAliveEnabled);
  }
}