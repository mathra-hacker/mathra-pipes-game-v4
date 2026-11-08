import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pipes/data/services/leaderboard_service.dart';
import 'package:pipes/ui/core/theme/app_colors.dart';
import 'package:pipes/ui/core/widgets/tangible_button.dart';
import 'package:pipes/ui/providers.dart';

/// Asks for a player name and stores it. Returns the name (or null).
Future<String?> showPlayerNameDialog(
  BuildContext context,
  LeaderboardService board, {
  String title = 'ඔයාගේ නම දාන්න',
}) async {
  final controller = TextEditingController(text: board.playerName);
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.headingDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Leaderboard එකේ පේන්නේ මේ නමයි',
                style: TextStyle(fontSize: 12, color: AppColors.subtext),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 18,
                style: TextStyle(color: AppColors.headingDark),
                decoration: InputDecoration(
                  hintText: 'Player name',
                  hintStyle: TextStyle(color: AppColors.subtext),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.accent, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TangibleButton(
                      text: 'Cancel',
                      isSecondary: true,
                      height: 44,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TangibleButton(
                      text: 'Save',
                      height: 44,
                      backgroundColor: AppColors.accent,
                      textColor: Colors.white,
                      onPressed: () {
                        final v = controller.text.trim();
                        if (v.isNotEmpty) Navigator.pop(ctx, v);
                      },
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
  controller.dispose();
  if (result != null && result.trim().isNotEmpty) {
    await board.setPlayer(result);
    return board.playerName;
  }
  return null;
}

class LeaderboardView extends ConsumerStatefulWidget {
  const LeaderboardView({super.key});

  @override
  ConsumerState<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends ConsumerState<LeaderboardView> {
  late bool _showOnline;

  @override
  void initState() {
    super.initState();
    final board = ref.read(leaderboardProvider);
    _showOnline = board.onlineEnabled;
    if (_showOnline) {
      Future.microtask(() => board.refreshOnline());
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    AppColors.currentTheme = settings.theme;
    final board = ref.watch(leaderboardProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: board,
          builder: (context, _) {
            final online = _showOnline && board.onlineEnabled;
            final players =
                online ? (board.onlineBoard?.players ?? const <PlayerEntry>[]) : board.players;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Round3DButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        iconSize: 18,
                        onTap: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Leaderboard  🏆',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.headingDark,
                            ),
                          ),
                        ),
                      ),
                      Round3DButton(
                        icon: online
                            ? Icons.refresh_rounded
                            : Icons.person_add_alt_1_rounded,
                        iconSize: 20,
                        onTap: online
                            ? board.refreshOnline
                            : () => showPlayerNameDialog(
                                  context,
                                  board,
                                  title: 'Player නම / අලුත් player',
                                ),
                      ),
                    ],
                  ),
                ),
                if (board.onlineEnabled)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TangibleButton(
                            text: 'Online 🌍',
                            height: 40,
                            isSecondary: !online,
                            backgroundColor:
                                online ? AppColors.accent : AppColors.surface,
                            textColor:
                                online ? Colors.white : AppColors.headingDark,
                            onPressed: () {
                              setState(() => _showOnline = true);
                              board.refreshOnline();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TangibleButton(
                            text: 'This phone 📱',
                            height: 40,
                            isSecondary: online,
                            backgroundColor:
                                !online ? AppColors.accent : AppColors.surface,
                            textColor:
                                !online ? Colors.white : AppColors.headingDark,
                            onPressed: () => setState(() => _showOnline = false),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (online)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      board.onlineBoard == null
                          ? (board.onlineLoading ? 'Loading…' : '')
                          : '👥 ${board.onlineBoard!.totalPlayers} players',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                if (online && board.onlineError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    child: Text(
                      'Online board load කරන්න බැරි උනා. Internet / Firebase rules බලන්න.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Color(0xFFE53935)),
                    ),
                  ),
                Expanded(
                  child: online && board.onlineLoading && players.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : players.isEmpty
                          ? _empty(context, board)
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                              children: [
                                _Podium(players: players.take(3).toList()),
                                const SizedBox(height: 22),
                                for (var i = 0; i < players.length; i++)
                                  _row(context, board, players[i], i,
                                      canDelete: !online),
                              ],
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _empty(BuildContext context, LeaderboardService board) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text(
              'තාම කවුරුත් නෑ.\nනමක් දාලා level එකක් ගහන්න!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.subtext, fontSize: 14),
            ),
            const SizedBox(height: 20),
            TangibleButton(
              text: 'නම දාන්න',
              backgroundColor: AppColors.accent,
              textColor: Colors.white,
              onPressed: () => showPlayerNameDialog(context, board),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    LeaderboardService board,
    PlayerEntry p,
    int index, {
    bool canDelete = true,
  }) {
    final isMe = p.name.toLowerCase() == board.playerName.toLowerCase();
    final medal = index == 0
        ? '🥇'
        : index == 1
            ? '🥈'
            : index == 2
                ? '🥉'
                : '${index + 1}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? AppColors.accent.withValues(alpha: 0.16) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMe ? AppColors.accent : AppColors.border,
            width: isMe ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.headingDark.withValues(alpha: 0.10),
              offset: const Offset(0, 4),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(
                medal,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: index < 3 ? 22 : 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.headingDark,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMe ? '${p.name}  (you)' : p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.headingDark,
                    ),
                  ),
                  Text(
                    '${p.levels} levels solved',
                    style: TextStyle(fontSize: 11.5, color: AppColors.subtext),
                  ),
                ],
              ),
            ),
            Text(
              '${p.score}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 4),
            if (canDelete)
              GestureDetector(
                onTap: () => board.removePlayer(p.name),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.close_rounded, size: 18, color: AppColors.subtext),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 3D podium: three tilted columns with perspective, names on top.
class _Podium extends StatefulWidget {
  const _Podium({required this.players});
  final List<PlayerEntry> players;

  @override
  State<_Podium> createState() => _PodiumState();
}

class _PodiumState extends State<_Podium> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.players;
    // visual order: 2nd, 1st, 3rd
    final order = <int>[1, 0, 2];
    final heights = <int, double>{0: 130, 1: 100, 2: 76};
    final colors = <int, Color>{
      0: const Color(0xFFFFC107),
      1: const Color(0xFF90A4AE),
      2: const Color(0xFFCD7F32),
    };

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final tilt = (_c.value - 0.5) * 0.35;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateX(-0.28)
            ..rotateY(tilt),
          child: SizedBox(
            height: 230,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final rank in order)
                  if (rank < p.length)
                    Expanded(
                      child: _column(p[rank], rank, heights[rank]!, colors[rank]!),
                    )
                  else
                    const Expanded(child: SizedBox()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _column(PlayerEntry p, int rank, double h, Color color) {
    final hsl = HSLColor.fromColor(color);
    final dark = hsl.withLightness(math.max(0.0, hsl.lightness - 0.2)).toColor();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            rank == 0 ? '👑' : (rank == 1 ? '🥈' : '🥉'),
            style: const TextStyle(fontSize: 26),
          ),
          Text(
            p.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.headingDark,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: h,
            width: double.infinity,
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color, dark],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  offset: const Offset(0, 8),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              '${p.score}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black38, blurRadius: 3)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
