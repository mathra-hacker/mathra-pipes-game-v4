import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pipes/data/services/settings_service.dart';
import 'package:pipes/domain/models/app_settings.dart';
import 'package:pipes/ui/core/haptics.dart';
import 'package:pipes/ui/core/l10n.dart';
import 'package:pipes/ui/core/theme/app_colors.dart';

class SettingsViewModel extends StateNotifier<AppSettings> {
  SettingsViewModel({required this.settingsService})
      : super(settingsService.getSettings()) {
    AppColors.currentTheme = state.theme;
    L10n.current = state.language;
    AppHaptics.enabled = state.haptics;
  }

  final SettingsService settingsService;

  Future<void> setTheme(AppThemePreset theme) async {
    AppColors.currentTheme = theme;
    state = state.copyWith(theme: theme);
    await settingsService.saveSettings(state);
  }

  Future<void> setLanguage(AppLanguage language) async {
    L10n.current = language;
    state = state.copyWith(language: language);
    await settingsService.saveSettings(state);
  }

  Future<void> toggleHintEnabled(bool value) async {
    state = state.copyWith(isHintEnabled: value);
    await settingsService.saveSettings(state);
  }

  Future<void> setEmojiSpeed(EmojiSpeed speed) async {
    state = state.copyWith(emojiSpeed: speed);
    await settingsService.saveSettings(state);
  }

  Future<void> setEmojiPack(String packId) async {
    state = state.copyWith(emojiPackId: packId);
    await settingsService.saveSettings(state);
  }

  Future<void> setAutoPlayMusic(bool value) async {
    state = state.copyWith(autoPlayMusic: value);
    await settingsService.saveSettings(state);
  }

  Future<void> setEffect(GameEffect effect) async {
    state = state.copyWith(effect: effect);
    await settingsService.saveSettings(state);
  }

  Future<void> setHaptics(bool value) async {
    AppHaptics.enabled = value;
    state = state.copyWith(haptics: value);
    await settingsService.saveSettings(state);
  }

  Future<void> setAudioQuality(AudioQuality quality) async {
    state = state.copyWith(audioQuality: quality);
    await settingsService.saveSettings(state);
  }
}
