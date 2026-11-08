import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pipes/domain/models/app_settings.dart';
import 'package:pipes/ui/core/haptics.dart';
import 'package:pipes/ui/core/l10n.dart';
import 'package:pipes/ui/core/theme/app_colors.dart';
import 'package:pipes/ui/core/widgets/emoji_rain.dart';
import 'package:pipes/ui/core/widgets/premium.dart';
import 'package:pipes/ui/core/widgets/tangible_button.dart';
import 'package:pipes/ui/core/widgets/theme_picker_sheet.dart';
import 'package:pipes/ui/features/about/views/about_view.dart';
import 'package:pipes/ui/features/leaderboard/views/leaderboard_view.dart';
import 'package:pipes/ui/features/music/views/music_view.dart';
import 'package:pipes/ui/providers.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    AppColors.currentTheme = settings.theme;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: PremiumBackground(
        child: SafeArea(
          child: Column(
            children: [
              PremiumHeader(
                title: L10n.t('Settings', 'සැකසුම්'),
                icon: Icons.close_rounded,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                  children: [
                    // ── Language ──
                    SectionCard(
                      title: L10n.t('Language', 'භාෂාව'),
                      icon: Icons.translate_rounded,
                      iconColor: const Color(0xFF1E88E5),
                      children: [
                        OptionPills<AppLanguage>(
                          items: AppLanguage.values,
                          selected: settings.language,
                          label: (l) => l.label,
                          onSelect: notifier.setLanguage,
                        ),
                      ],
                    ),

                    // ── Theme ──
                    SectionCard(
                      title: L10n.t('Theme', 'තේමාව'),
                      icon: Icons.palette_rounded,
                      iconColor: const Color(0xFF8E24AA),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                settings.theme.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.headingDark,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => showThemePickerSheet(context),
                              icon: Icon(
                                Icons.grid_view_rounded,
                                size: 18,
                                color: AppColors.accent,
                              ),
                              label: Text(
                                L10n.t('All themes', 'සියලු තේමා'),
                                style: TextStyle(color: AppColors.accent),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 50,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            itemCount: AppThemePreset.values.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final preset = AppThemePreset.values[index];
                              return _swatch(
                                preset,
                                settings.theme == preset,
                                () {
                                  AppHaptics.select();
                                  notifier.setTheme(preset);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    // ── Gameplay ──
                    SectionCard(
                      title: L10n.t('Gameplay', 'ක්‍රීඩාව'),
                      icon: Icons.sports_esports_rounded,
                      iconColor: const Color(0xFF43A047),
                      children: [
                        SwitchRow(
                          label: L10n.t('Hints', 'ඉඟි'),
                          hint: L10n.t(
                            'Shows the 💡 hint button in game',
                            'ක්‍රීඩාවේ 💡 ඉඟි බටන් එක ක්‍රියාත්මක වේ',
                          ),
                          value: settings.isHintEnabled,
                          onChanged: notifier.toggleHintEnabled,
                        ),
                        const SizedBox(height: 4),
                        SwitchRow(
                          label: L10n.t('Vibration', 'කම්පනය'),
                          hint: L10n.t(
                            'Small vibration when you tap',
                            'ඔබද්දී සුළු කම්පනයක්',
                          ),
                          value: settings.haptics,
                          onChanged: notifier.setHaptics,
                        ),
                      ],
                    ),

                    // ── Effects ──
                    SectionCard(
                      title: L10n.t('Effects', 'Effects'),
                      icon: Icons.auto_awesome_rounded,
                      iconColor: const Color(0xFFF57C00),
                      children: [
                        _label(L10n.t('When a level is completed', 'මට්ටම ජය ගත්විට')),
                        OptionPills<GameEffect>(
                          items: GameEffect.values,
                          selected: settings.effect,
                          label: (e) => L10n.t(e.label, e.sinhala),
                          leading: (e) => e.icon,
                          onSelect: notifier.setEffect,
                        ),
                        _label(L10n.t('Emoji pack', 'Emoji වර්ගය')),
                        OptionPills<EmojiPack>(
                          items: EmojiPack.all,
                          selected: settings.emojiPack,
                          label: (p) => p.name,
                          onSelect: (p) => notifier.setEmojiPack(p.id),
                        ),
                        _label(L10n.t('Speed', 'වේගය')),
                        OptionPills<EmojiSpeed>(
                          items: EmojiSpeed.values,
                          selected: settings.emojiSpeed,
                          label: (s) => L10n.t(s.label, s.sinhala),
                          onSelect: notifier.setEmojiSpeed,
                        ),
                        const SizedBox(height: 16),
                        EmojiRainPreview(
                          emojis: settings.emojiPack.emojis,
                          speed: settings.emojiSpeed,
                          button: (running, toggle) => TangibleButton(
                            text: running
                                ? L10n.t('Stop preview', 'නවත්වන්න')
                                : L10n.t('Preview effect', 'බලන්න'),
                            icon: running
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                            height: 44,
                            backgroundColor: running
                                ? const Color(0xFFE53935)
                                : AppColors.primary,
                            textColor:
                                running ? Colors.white : AppColors.headingDark,
                            onPressed: toggle,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          L10n.d(
                            'In game, use the ✨ Effects button to change these quickly.',
                            'ක්‍රීඩාවේදී ✨ Effects බටන් එකෙන් මේවා ඉක්මනින් මාරු කරන්න.',
                          ),
                          style: TextStyle(fontSize: 11.5, color: AppColors.subtext),
                        ),
                      ],
                    ),

                    // ── Music & downloads ──
                    SectionCard(
                      title: L10n.t('Music & Download', 'සිංදු සහ Download'),
                      icon: Icons.library_music_rounded,
                      iconColor: const Color(0xFFD81B60),
                      children: [
                        SwitchRow(
                          label: L10n.t('Auto-play in game', 'ක්‍රීඩාවේදී ස්වයංක්‍රීයව'),
                          hint: L10n.t(
                            'Starts the playlist when a game opens',
                            'ක්‍රීඩාව ඇරෙද්දී සිංදු පටන් ගනී',
                          ),
                          value: settings.autoPlayMusic,
                          onChanged: notifier.setAutoPlayMusic,
                        ),
                        _label(L10n.t('YouTube download quality', 'YouTube download quality')),
                        OptionPills<AudioQuality>(
                          items: AudioQuality.values,
                          selected: settings.audioQuality,
                          label: (q) => '${L10n.t(q.label, q.sinhala)}  ${q.hint}',
                          onSelect: notifier.setAudioQuality,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          L10n.d(
                            'Fast = smallest file, downloads in seconds.',
                            'Fast = කුඩාම file එක, තත්පර කිහිපයකින් download වේ.',
                          ),
                          style: TextStyle(fontSize: 11.5, color: AppColors.subtext),
                        ),
                        const SizedBox(height: 14),
                        TangibleButton(
                          text: L10n.t('Open Playlist', 'සිංදු ලැයිස්තුව'),
                          icon: Icons.queue_music_rounded,
                          isSecondary: true,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MusicView()),
                          ),
                        ),
                      ],
                    ),

                    // ── Player ──
                    SectionCard(
                      title: L10n.t('Player', 'ක්‍රීඩකයා'),
                      icon: Icons.person_rounded,
                      iconColor: const Color(0xFF00897B),
                      children: [
                        TangibleButton(
                          text: L10n.t('Change player name', 'නම වෙනස් කරන්න'),
                          icon: Icons.edit_rounded,
                          isSecondary: true,
                          onPressed: () => showPlayerNameDialog(
                            context,
                            ref.read(leaderboardProvider),
                            title: 'Player නම',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TangibleButton(
                          text: L10n.t('Leaderboard', 'ප්‍රමුඛ පුවරුව'),
                          icon: Icons.emoji_events_rounded,
                          isSecondary: true,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LeaderboardView()),
                          ),
                        ),
                      ],
                    ),

                    // ── About & reset ──
                    SectionCard(
                      title: L10n.t('More', 'තවත්'),
                      icon: Icons.more_horiz_rounded,
                      iconColor: const Color(0xFF546E7A),
                      children: [
                        TangibleButton(
                          text: L10n.t('About', 'ගැන'),
                          icon: Icons.info_rounded,
                          backgroundColor: AppColors.primary,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AboutView()),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TangibleButton(
                          text: L10n.t('Reset Progress', 'ප්‍රගතිය මකන්න'),
                          icon: Icons.delete_forever_rounded,
                          isSecondary: true,
                          height: 48,
                          backgroundColor: AppColors.surface,
                          textColor: const Color(0xFFFF5252),
                          onPressed: () => _confirmReset(context, ref),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),
                    Center(
                      child: Column(
                        children: [
                          const LogoBadge(size: 44),
                          const SizedBox(height: 8),
                          Text(
                            'Mathra Pipes  •  v1.1.0',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.subtext,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Denuwan Akash',
                            style: TextStyle(fontSize: 11, color: AppColors.subtext),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 10),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: AppColors.subtext,
          ),
        ),
      );

  Widget _swatch(AppThemePreset preset, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: preset.bg,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? preset.accent : preset.border,
            width: selected ? 3 : 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: preset.accent.withValues(alpha: 0.45),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: preset.accent,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFF5252).withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                L10n.t('Reset progress?', 'ප්‍රගතිය මකන්නද?'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.headingDark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                L10n.d('All solved puzzles, best times, and saved games will be permanently erased.', 'විසඳූ සියලු ප්‍රහේලිකා, හොඳම වේලාවන් සහ සුරකින ලද ක්‍රීඩා ස්ථිරවම මැකී යනු ඇත.'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                  color: AppColors.subtext,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TangibleButton(
                      text: L10n.t('Cancel', 'අවලංගු කරන්න'),
                      isSecondary: true,
                      height: 44,
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TangibleButton(
                      text: L10n.t('Reset', 'මකන්න'),
                      backgroundColor: const Color(0xFFD32F2F),
                      textColor: Colors.white,
                      borderColor: const Color(0xFFFF5252),
                      height: 44,
                      onPressed: () async {
                        await ref
                            .read(homeViewModelProvider.notifier)
                            .resetProgress();
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
