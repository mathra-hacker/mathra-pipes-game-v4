import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pipes/data/services/music_service.dart';
import 'package:pipes/domain/models/app_settings.dart';
import 'package:pipes/domain/models/game_level.dart';
import 'package:pipes/ui/core/haptics.dart';
import 'package:pipes/ui/core/l10n.dart';
import 'package:pipes/ui/core/theme/app_colors.dart';
import 'package:pipes/ui/core/widgets/confetti.dart';
import 'package:pipes/ui/core/widgets/emoji_rain.dart';
import 'package:pipes/ui/core/widgets/pipe_widget.dart';
import 'package:pipes/ui/core/widgets/premium.dart';
import 'package:pipes/ui/core/widgets/tangible_button.dart';
import 'package:pipes/ui/core/widgets/theme_picker_sheet.dart';
import 'package:pipes/ui/features/game/view_models/game_view_model.dart';
import 'package:pipes/ui/features/leaderboard/views/leaderboard_view.dart';
import 'package:pipes/ui/features/music/views/music_view.dart';
import 'package:pipes/ui/providers.dart';

class GameView extends ConsumerStatefulWidget {
  const GameView({
    super.key,
    required this.levelNumber,
    this.isRandom = false,
    this.randomDifficulty = 'Easy',
  });

  final int levelNumber;
  final bool isRandom;
  final String randomDifficulty;

  @override
  ConsumerState<GameView> createState() => _GameViewState();
}

class _GameViewState extends ConsumerState<GameView>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late AnimationController _shockwaveController;
  bool _emojiOn = false;
  int _lastPoints = 0;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _shockwaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    Future.microtask(() {
      if (!mounted) return;
      if (widget.isRandom) {
        ref
            .read(gameViewModelProvider.notifier)
            .loadRandomLevel(widget.randomDifficulty);
      } else {
        ref.read(gameViewModelProvider.notifier).loadLevel(widget.levelNumber);
      }
      // Optional: start the playlist automatically when a game opens.
      if (ref.read(settingsProvider).autoPlayMusic) {
        ref.read(musicProvider).startIfIdle();
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _shockwaveController.dispose();
    super.dispose();
  }

  /// Short label for the dock buttons (one language only, so it always fits).
  String _short(String en, String si) =>
      L10n.current == AppLanguage.si ? si : en;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final state = ref.watch(gameViewModelProvider);
    AppColors.currentTheme = settings.theme;

    ref.listen<GameViewModelState>(gameViewModelProvider, (prev, next) {
      if (next.isComplete && !(prev?.isComplete ?? false)) {
        _onLevelComplete(next);
      } else if (!next.isComplete && (prev?.isComplete ?? false)) {
        if (_lastPoints != 0) setState(() => _lastPoints = 0);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: PremiumBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildTopBar(state),
                  Expanded(child: _buildBody(state, settings)),
                ],
              ),
              Positioned.fill(
                child: ConfettiExplosion(
                  trigger: state.isComplete && settings.effect.hasConfetti,
                ),
              ),
              Positioned.fill(
                child: EmojiRain(
                  active: _emojiOn ||
                      (state.isComplete && settings.effect.hasEmoji),
                  emojis: settings.emojiPack.emojis,
                  speed: settings.emojiSpeed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── top bar ─────────────────────────

  Widget _buildTopBar(GameViewModelState state) {
    final title = state.isRandomMode
        ? (state.randomDifficulty ?? widget.randomDifficulty)
        : L10n.t('Level ${widget.levelNumber}', 'මට්ටම ${widget.levelNumber}');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Round3DButton(
            icon: Icons.arrow_back_ios_new_rounded,
            iconSize: 18,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
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
                    const LogoBadge(size: 30),
                    const SizedBox(width: 10),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          title,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.headingDark,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Round3DButton(
            icon: Icons.palette_rounded,
            iconSize: 20,
            iconColor: AppColors.accent,
            onTap: () => showThemePickerSheet(context),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── body ─────────────────────────

  Widget _buildBody(GameViewModelState state, AppSettings settings) {
    final loading = state.isLoading ||
        (!state.isRandomMode &&
            (state.level == null ||
                state.level!.levelNumber != widget.levelNumber));
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.error!,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 180,
              child: TangibleButton(
                text: L10n.t('Retry', 'නැවත උත්සාහ කරන්න'),
                onPressed: () =>
                    ref.read(gameViewModelProvider.notifier).resetLevel(),
              ),
            ),
          ],
        ),
      );
    }
    if (loading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }
    return _buildGame(state, settings);
  }

  Widget _buildGame(GameViewModelState state, AppSettings settings) {
    final level = state.level;
    if (level == null || state.board.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
          child: Row(
            children: [
              Expanded(
                child: StatPill(
                  icon: Icons.touch_app_rounded,
                  value: '${state.moveCount}',
                  label: L10n.t('Moves', 'ගමන්'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatPill(
                  icon: Icons.timer_rounded,
                  value: _formatTime(state.elapsedSeconds),
                  label: L10n.t('Time', 'කාලය'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatPill(
                  icon: Icons.water_drop_rounded,
                  value: '${state.connectedCount}',
                  label: L10n.t('Flowing', 'ගලනවා'),
                ),
              ),
            ],
          ),
        ),
        // The board always fits the free space, whatever the screen size.
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final side = math.max(
                120.0,
                math.min(c.maxWidth - 24, c.maxHeight - 8),
              );
              return Center(child: _buildBoard(state, level, side));
            },
          ),
        ),
        if (state.isComplete)
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 24 * (1.0 - value)),
                child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
              );
            },
            child: _buildCompletionBar(state),
          )
        else
          _buildDock(settings),
      ],
    );
  }

  Widget _buildBoard(GameViewModelState state, GameLevel level, double side) {
    const pad = 10.0;
    const depth = 6.0;
    final inner = side - depth - pad * 2 - 3;
    final cellColor = Color.lerp(AppColors.bg, AppColors.surface, 0.35)!;
    // Opaque colour with good contrast on every theme.
    final offPipe = Color.lerp(AppColors.surface, AppColors.headingDark, 0.34)!;
    final int id =
        state.isRandomMode ? (state.randomSeed ?? 0) : level.levelNumber;

    final panel = Panel3D(
      padding: const EdgeInsets.all(pad),
      radius: 26,
      depth: depth,
      child: SizedBox(
        width: inner,
        height: inner,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _BoardGridPainter(
                  count: level.gridSize,
                  color: cellColor,
                ),
              ),
            ),
            PipeGameBoard(
              key: ValueKey('board_$id'),
              levelId: id,
              gridSize: level.gridSize,
              board: state.board,
              waterFlow: state.waterFlow,
              sourceRow: level.sourceRow,
              sourceCol: level.sourceCol,
              hintCell: state.hintCell,
              bgColor: cellColor,
              pipeColor: offPipe,
              activeColor: AppColors.accent,
              onTileTap: state.isComplete
                  ? null
                  : (r, c) {
                      ref.read(gameViewModelProvider.notifier).rotateTile(r, c);
                    },
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _shockwaveController,
                  builder: (context, _) {
                    final v = _shockwaveController.value;
                    if (v <= 0.0 || v >= 1.0) return const SizedBox.shrink();
                    return CustomPaint(
                      painter: VictoryShockwavePainter(
                        progress: v,
                        gridSize: level.gridSize,
                        sourceRow: level.sourceRow,
                        sourceCol: level.sourceCol,
                        waveColor: AppColors.accent,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return SizedBox(
      width: side,
      height: side,
      child: AnimatedBuilder(
        animation: _shakeController,
        child: panel,
        builder: (context, child) {
          final t = _shakeController.value;
          final factor = 1.0 - t;
          final shakeX = math.sin(t * math.pi * 8) * 4.5 * factor;
          final shakeY = math.cos(t * math.pi * 6) * 3.0 * factor;
          return Transform.translate(
            offset: Offset(shakeX, shakeY),
            child: child,
          );
        },
      ),
    );
  }

  // ───────────────────────── dock ─────────────────────────

  Widget _buildDock(AppSettings settings) {
    final music = ref.watch(musicProvider);
    return ListenableBuilder(
      listenable: music,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
          child: Panel3D(
            padding: const EdgeInsets.all(10),
            radius: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (music.tracks.isNotEmpty) ...[
                  _buildMiniPlayer(music),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(
                      child: DockButton(
                        icon: Icons.lightbulb_rounded,
                        label: _short('Hint', 'ඉඟිය'),
                        iconColor: const Color(0xFFF9A825),
                        onTap: () => _onHint(settings),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DockButton(
                        icon: Icons.library_music_rounded,
                        label: _short('Music', 'සිංදු'),
                        iconColor: const Color(0xFFE91E63),
                        onTap: () => showPlaylistSheet(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DockButton(
                        icon: Icons.auto_awesome_rounded,
                        label: _short('Effects', 'Effects'),
                        active: _emojiOn,
                        onTap: _showEffectsSheet,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DockButton(
                        icon: Icons.emoji_events_rounded,
                        label: _short('Ranks', 'ප්‍රමුඛ'),
                        iconColor: const Color(0xFFFF9800),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LeaderboardView(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DockButton(
                        icon: Icons.refresh_rounded,
                        label: _short('Restart', 'නැවත'),
                        onTap: () => ref
                            .read(gameViewModelProvider.notifier)
                            .resetLevel(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniPlayer(MusicController music) {
    final current = music.current;
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent.withValues(alpha: 0.16),
          ),
          child: Icon(
            music.isPlaying
                ? Icons.equalizer_rounded
                : Icons.music_note_rounded,
            size: 20,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => showPlaylistSheet(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  current?.title ?? L10n.t('Tap ▶ to play', '▶ ඔබන්න'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.headingDark,
                  ),
                ),
                Text(
                  current?.author.isNotEmpty == true
                      ? current!.author
                      : 'Playlist  •  ${music.tracks.length}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: AppColors.subtext),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Round3DButton(
          icon: Icons.skip_previous_rounded,
          size: 36,
          iconSize: 20,
          onTap: music.previous,
        ),
        const SizedBox(width: 8),
        Round3DButton(
          icon: music.isPlaying
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          size: 42,
          iconSize: 24,
          color: const Color(0xFF43A047),
          iconColor: Colors.white,
          onTap: music.togglePlayPause,
        ),
        const SizedBox(width: 8),
        Round3DButton(
          icon: Icons.skip_next_rounded,
          size: 36,
          iconSize: 20,
          onTap: music.next,
        ),
      ],
    );
  }

  void _onHint(AppSettings settings) {
    if (!settings.isHintEnabled) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              L10n.t(
                'Turn on Hints in Settings',
                'සැකසුම් වලින් ඉඟි on කරන්න',
              ),
            ),
          ),
        );
      return;
    }
    ref.read(gameViewModelProvider.notifier).revealHint();
  }

  void _showEffectsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EffectsSheet(
        initialRain: _emojiOn,
        onRainChanged: (v) {
          if (mounted) setState(() => _emojiOn = v);
        },
      ),
    );
  }

  // ───────────────────────── completion ─────────────────────────

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _onLevelComplete(GameViewModelState state) async {
    _shakeController.forward(from: 0.0);
    _shockwaveController.forward(from: 0.0);
    AppHaptics.heavy();
    await ref.read(gameViewModelProvider.notifier).completeLevel();
    if (!mounted) return;

    // Leaderboard: ask for a name the first time, then add the points.
    final board = ref.read(leaderboardProvider);
    if (!board.hasPlayer) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      await showPlayerNameDialog(context, board);
      if (!mounted) return;
    }
    final level = state.level;
    final points = await board.addResult(
      gridSize: level?.gridSize ?? 4,
      moves: state.moveCount,
      seconds: state.elapsedSeconds,
    );
    if (mounted) setState(() => _lastPoints = points);
  }

  Widget _buildCompletionBar(GameViewModelState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      child: Panel3D(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        radius: 24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '🎉  ${L10n.t('Congratulations!', 'සුබ පැතුම්!')}',
                maxLines: 1,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.headingDark,
                ),
              ),
            ),
            if (_lastPoints > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  L10n.t('+$_lastPoints points ⭐', '+$_lastPoints ලකුණු ⭐'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TangibleButton(
                    text: L10n.t('Home', 'මුල් පිටුව'),
                    icon: Icons.home_rounded,
                    isSecondary: true,
                    height: 46,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TangibleButton(
                    text: state.isRandomMode
                        ? L10n.t('Play Again', 'නැවත ක්‍රීඩා කරන්න')
                        : L10n.t('Next Level', 'ඊළඟ මට්ටම'),
                    icon: Icons.arrow_forward_rounded,
                    height: 46,
                    backgroundColor: AppColors.accent,
                    textColor: Colors.white,
                    onPressed: () {
                      final notifier = ref.read(gameViewModelProvider.notifier);
                      if (state.isRandomMode) {
                        notifier.loadRandomLevel(state.randomDifficulty ?? 'Easy');
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                GameView(levelNumber: widget.levelNumber + 1),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── effects sheet ─────────────────────────

class _EffectsSheet extends ConsumerStatefulWidget {
  const _EffectsSheet({required this.initialRain, required this.onRainChanged});

  final bool initialRain;
  final ValueChanged<bool> onRainChanged;

  @override
  ConsumerState<_EffectsSheet> createState() => _EffectsSheetState();
}

class _EffectsSheetState extends ConsumerState<_EffectsSheet> {
  late bool _rain = widget.initialRain;

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 10),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.subtext,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    AppColors.currentTheme = settings.theme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  '✨  ${L10n.t('Effects', 'Effects')}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.headingDark,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Panel3D(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                radius: 18,
                depth: 4,
                child: SwitchRow(
                  label: L10n.t('Emoji rain now', 'Emoji වැස්ස දැන්'),
                  hint: L10n.t('Plays while you solve', 'ක්‍රීඩා කරද්දී වැටෙනවා'),
                  value: _rain,
                  onChanged: (v) {
                    setState(() => _rain = v);
                    widget.onRainChanged(v);
                  },
                ),
              ),
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
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── painters ─────────────────────────

/// Rounded "tile" background behind every cell of the board.
class _BoardGridPainter extends CustomPainter {
  _BoardGridPainter({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / count;
    final inset = cell * 0.05;
    final paint = Paint()..color = color;
    for (var r = 0; r < count; r++) {
      for (var c = 0; c < count; c++) {
        final rect = Rect.fromLTWH(
          c * cell + inset,
          r * cell + inset,
          cell - inset * 2,
          cell - inset * 2,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.2)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoardGridPainter oldDelegate) {
    return oldDelegate.count != count || oldDelegate.color != color;
  }
}

class VictoryShockwavePainter extends CustomPainter {
  VictoryShockwavePainter({
    required this.progress,
    required this.gridSize,
    required this.sourceRow,
    required this.sourceCol,
    required this.waveColor,
  });

  final double progress;
  final int gridSize;
  final int sourceRow;
  final int sourceCol;
  final Color waveColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;
    final cellSize = size.width / gridSize;
    final origin = Offset(
      (sourceCol + 0.5) * cellSize,
      (sourceRow + 0.5) * cellSize,
    );
    final maxRadius = size.width * 1.35;
    final currentRadius = maxRadius * progress;
    final ringWidth = cellSize * 0.75 * (1.0 - progress);
    final alpha = (0.55 * (1.0 - progress)).clamp(0.0, 1.0);

    final wavePaint = Paint()
      ..color = waveColor.withValues(alpha: alpha)
      ..strokeWidth = ringWidth
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

    canvas.drawCircle(origin, currentRadius, wavePaint);
  }

  @override
  bool shouldRepaint(covariant VictoryShockwavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
