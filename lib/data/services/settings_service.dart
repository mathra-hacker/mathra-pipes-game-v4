import 'package:hive_flutter/hive_flutter.dart';
import 'package:pipes/domain/models/app_settings.dart';

class SettingsService {
  static const String _boxName = 'pipes_settings';

  Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  Box get box => Hive.box(_boxName);

  AppSettings getSettings() {
    final b = box;
    final isHintEnabled = b.get('hint_enabled', defaultValue: false) as bool;
    final themeId = b.get('app_theme', defaultValue: 'pastelSky') as String?;
    return AppSettings(
      isHintEnabled: isHintEnabled,
      theme: AppThemePreset.fromId(themeId),
      emojiSpeed: EmojiSpeed.fromName(b.get('emoji_speed') as String?),
      emojiPackId: (b.get('emoji_pack', defaultValue: 'water') as String?) ?? 'water',
      autoPlayMusic: b.get('auto_play_music', defaultValue: false) as bool,
      language: AppLanguage.fromName(b.get('app_language') as String?),
      effect: GameEffect.fromName(b.get('game_effect') as String?),
      haptics: b.get('haptics', defaultValue: true) as bool,
      audioQuality: AudioQuality.fromName(b.get('audio_quality') as String?),
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final b = box;
    await b.put('hint_enabled', settings.isHintEnabled);
    await b.put('app_theme', settings.theme.id);
    await b.put('emoji_speed', settings.emojiSpeed.name);
    await b.put('emoji_pack', settings.emojiPackId);
    await b.put('auto_play_music', settings.autoPlayMusic);
    await b.put('app_language', settings.language.name);
    await b.put('game_effect', settings.effect.name);
    await b.put('haptics', settings.haptics);
    await b.put('audio_quality', settings.audioQuality.name);
  }
}
