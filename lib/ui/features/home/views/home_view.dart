import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pipes/ui/core/l10n.dart';
import 'package:pipes/ui/core/theme/app_colors.dart';
import 'package:pipes/ui/core/widgets/premium.dart';
import 'package:pipes/ui/core/widgets/tangible_button.dart';
import 'package:pipes/ui/core/widgets/theme_picker_sheet.dart';
import 'package:pipes/ui/features/about/views/about_view.dart';
import 'package:pipes/ui/features/game/views/game_view.dart';
import 'package:pipes/ui/features/leaderboard/views/leaderboard_view.dart';
import 'package:pipes/ui/features/music/views/music_view.dart';
import 'package:pipes/ui/features/how_to_play/views/how_to_play_view.dart';
import 'package:pipes/ui/features/level_select/views/level_select_view.dart';
import 'package:pipes/ui/features/settings/views/settings_view.dart';
import 'package:pipes/ui/providers.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(homeViewModelProvider.notifier).loadProgress());
  }

  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final state = ref.watch(homeViewModelProvider);
    AppColors.currentTheme = settings.theme;
    final level = state.progress?.currentLevel ?? 1;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: PremiumBackground(
        child: SafeArea(
          child: Column(
            children: [
              _topBar(state.progress != null ? level : null),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                  child: Column(
                    children: [
                      _hero(),
                      const SizedBox(height: 22),
                      _playButton(state.isLoading, level),
                      const SizedBox(height: 22),
                      _tiles(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(int? level) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          Round3DButton(
            icon: Icons.emoji_events_rounded,
            iconColor: const Color(0xFFFF9800),
            onTap: () => _open(const LeaderboardView()),
          ),
          Expanded(
            child: Center(
              child: level == null
                  ? const SizedBox.shrink()
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.7),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: shade(AppColors.surface, 0.14),
                            offset: const Offset(0, 3),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            offset: const Offset(0, 6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flag_rounded, size: 16, color: AppColors.accent),
                          const SizedBox(width: 6),
                          Text(
                            L10n.t('Level $level', 'මට්ටම $level'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.headingDark,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          Round3DButton(
            icon: Icons.library_music_rounded,
            iconColor: const Color(0xFFE91E63),
            onTap: () => _open(const MusicView()),
          ),
        ],
      ),
    );
  }

  /// The logo, floating in 3D. Touch and drag on it to tilt it.
  Widget _hero() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Tilt3D(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.55),
                blurRadius: 34,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.30),
                blurRadius: 18,
                offset: const Offset(0, 22),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Image.asset(
              'assets/icon.png',
              width: 220,
              height: 220,
              cacheWidth: 660,
            ),
          ),
        ),
      ),
    );
  }

  Widget _playButton(bool loading, int level) {
    return TangibleButton(
      text: L10n.t('Play', 'ක්‍රීඩා කරන්න'),
      icon: Icons.play_arrow_rounded,
      height: 62,
      backgroundColor: AppColors.accent,
      textColor: Colors.white,
      onPressed: loading
          ? null
          : () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GameView(levelNumber: level),
                ),
              );
              ref.read(homeViewModelProvider.notifier).loadProgress();
            },
    );
  }

  Widget _tiles() {
    Widget row(List<Widget> items) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 14),
              Expanded(child: items[i]),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        row([
          DashTile(
            icon: Icons.grid_view_rounded,
            en: 'Levels',
            si: 'මට්ටම්',
            color: const Color(0xFF1E88E5),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LevelSelectView()),
              );
              ref.read(homeViewModelProvider.notifier).loadProgress();
            },
          ),
          DashTile(
            icon: Icons.casino_rounded,
            en: 'Random',
            si: 'අහඹු',
            color: const Color(0xFF8E24AA),
            onTap: () => _showDifficultyDialog(context),
          ),
        ]),
        row([
          DashTile(
            icon: Icons.music_note_rounded,
            en: 'Playlist',
            si: 'සිංදු',
            color: const Color(0xFFD81B60),
            onTap: () => _open(const MusicView()),
          ),
          DashTile(
            icon: Icons.emoji_events_rounded,
            en: 'Leaderboard',
            si: 'ප්‍රමුඛ පුවරුව',
            color: const Color(0xFFF57C00),
            onTap: () => _open(const LeaderboardView()),
          ),
        ]),
        row([
          DashTile(
            icon: Icons.help_rounded,
            en: 'How to Play',
            si: 'ක්‍රීඩා කරන ආකාරය',
            color: const Color(0xFF00897B),
            onTap: () => _open(const HowToPlayView()),
          ),
          DashTile(
            icon: Icons.palette_rounded,
            en: 'Themes',
            si: 'තේමා',
            color: const Color(0xFF5E35B1),
            onTap: () => showThemePickerSheet(context),
          ),
        ]),
        row([
          DashTile(
            icon: Icons.settings_rounded,
            en: 'Settings',
            si: 'සැකසුම්',
            color: const Color(0xFF546E7A),
            onTap: () => _open(const SettingsView()),
          ),
          DashTile(
            icon: Icons.info_rounded,
            en: 'About',
            si: 'ගැන',
            color: const Color(0xFF3949AB),
            onTap: () => _open(const AboutView()),
          ),
        ]),
      ],
    );
  }

  String _stageLabel(String stage) {
    const si = {
      'Easy': 'පහසු',
      'Medium': 'මධ්‍යම',
      'Hard': 'අමාරු',
      'Expert': 'විශේෂඥ',
      'Master': 'ශූරයා',
    };
    return L10n.t(stage, si[stage] ?? stage);
  }

  void _showDifficultyDialog(BuildContext context) {
    final stages = [
      'Easy',
      'Medium',
      'Hard',
      'Expert',
      'Master',
    ];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.border,
              width: 1.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  L10n.t('Choose Difficulty', 'දුෂ්කරතාව තෝරන්න'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.headingDark,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  L10n.d('Play a dynamically generated Pipes puzzle.', 'අහඹු ලෙස හදන Pipes ප්‍රහේලිකාවක් ක්‍රීඩා කරන්න.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.subtext,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              for (final stage in stages)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TangibleButton(
                    text: _stageLabel(stage),
                    height: 44,
                    isSecondary: true,
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GameView(
                            levelNumber: 0,
                            isRandom: true,
                            randomDifficulty: stage,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  L10n.t('Cancel', 'අවලංගු කරන්න'),
                  style: TextStyle(
                    color: AppColors.subtext,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
