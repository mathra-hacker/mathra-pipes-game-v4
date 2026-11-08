import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pipes/ui/core/theme/app_colors.dart';
import 'package:pipes/ui/core/widgets/tangible_button.dart';
import 'package:pipes/ui/providers.dart';

class AboutView extends ConsumerStatefulWidget {
  const AboutView({super.key});

  @override
  ConsumerState<AboutView> createState() => _AboutViewState();
}

class _AboutViewState extends ConsumerState<AboutView>
    with TickerProviderStateMixin {
  // Drag tilt (radians) and a slow idle float animation.
  double _tiltX = 0;
  double _tiltY = 0;
  bool _dragging = false;
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat();

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    AppColors.currentTheme = settings.theme;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
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
                        'About  •  ගැන',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.headingDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 46),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                children: [
                  _card3D(),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'කාඩ් එක ඇදලා කරකවන්න 👆',
                      style: TextStyle(fontSize: 11.5, color: AppColors.subtext),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Mathra Pipes Game',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.headingDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'Connect the Pipes… Clear the Level!',
                      style: TextStyle(fontSize: 13, color: AppColors.subtext),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'Version 1.0.1',
                      style: TextStyle(fontSize: 11.5, color: AppColors.subtext),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 14,
                    children: const [
                      _FeatureChip('🎮', 'Fun Gameplay'),
                      _FeatureChip('⭐', 'Challenging Levels'),
                      _FeatureChip('⚡', 'Smooth Control'),
                      _FeatureChip('🏆', 'Be the Best!'),
                    ],
                  ),
                  const SizedBox(height: 26),
                  _developerCard(),
                  const SizedBox(height: 18),
                  TangibleButton(
                    text: 'GitHub  •  denuvan-akash',
                    icon: Icons.code_rounded,
                    backgroundColor: const Color(0xFF24292F),
                    textColor: Colors.white,
                    onPressed: () => _open('https://github.com/denuvan-akash'),
                  ),
                  const SizedBox(height: 14),
                  TangibleButton(
                    text: 'TikTok  •  @mathra_quotes_1',
                    icon: Icons.music_note_rounded,
                    backgroundColor: const Color(0xFFFE2C55),
                    textColor: Colors.white,
                    onPressed: () =>
                        _open('https://www.tiktok.com/@mathra_quotes_1'),
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: Text(
                      'Based on the open-source "Pipes" game by sidhant947\n'
                      'Licensed under GPL-3.0',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.subtext,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card3D() {
    return AnimatedBuilder(
      animation: _idle,
      builder: (context, _) {
        // Gentle floating when the finger is not on the card.
        final t = _idle.value * 2 * math.pi;
        final floatX = _dragging ? 0.0 : math.sin(t) * 0.05;
        final floatY = _dragging ? 0.0 : math.cos(t) * 0.08;
        final floatDy = _dragging ? 0.0 : math.sin(t) * 6;
        final rx = _tiltX + floatX;
        final ry = _tiltY + floatY;

        return GestureDetector(
          onPanStart: (_) => setState(() => _dragging = true),
          onPanUpdate: (d) {
            setState(() {
              _tiltY = (_tiltY + d.delta.dx * 0.012).clamp(-0.6, 0.6);
              _tiltX = (_tiltX - d.delta.dy * 0.012).clamp(-0.5, 0.5);
            });
          },
          onPanEnd: (_) => _release(),
          onPanCancel: _release,
          child: Transform.translate(
            offset: Offset(0, floatDy),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0014)
                ..rotateX(rx)
                ..rotateY(ry),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2979FF).withValues(alpha: 0.55),
                      blurRadius: 28,
                      spreadRadius: 1,
                      offset: Offset(-ry * 40, rx * 40 + 12),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: Offset(-ry * 30, 16 + rx * 30),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset('assets/about.jpg', fit: BoxFit.cover),
                        // moving glossy light that follows the tilt
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(-1 + ry * 2.2, -1 - rx * 2.2),
                              end: Alignment(1 + ry * 2.2, 1 - rx * 2.2),
                              colors: [
                                Colors.white.withValues(alpha: 0.22),
                                Colors.transparent,
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.45, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _release() {
    // Spring the card back to rest.
    final startX = _tiltX;
    final startY = _tiltY;
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    final curve = CurvedAnimation(parent: controller, curve: Curves.elasticOut);
    curve.addListener(() {
      if (!mounted) return;
      setState(() {
        _tiltX = startX * (1 - curve.value);
        _tiltY = startY * (1 - curve.value);
      });
    });
    controller.addStatusListener((s) {
      if (s == AnimationStatus.completed) controller.dispose();
    });
    setState(() => _dragging = false);
    controller.forward();
  }

  Widget _developerCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.primary.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.headingDark.withValues(alpha: 0.14),
            offset: const Offset(0, 7),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('👑', style: TextStyle(fontSize: 34)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Developed by',
                  style: TextStyle(fontSize: 11.5, color: AppColors.subtext),
                ),
                Text(
                  'Denuwan Akash  (දෙනුවන් ආකාශ්)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.headingDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip(this.emoji, this.label);
  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Button3DBase(
        onPressed: () {},
        color: AppColors.surface,
        height: 46,
        depth: 5,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.headingDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
