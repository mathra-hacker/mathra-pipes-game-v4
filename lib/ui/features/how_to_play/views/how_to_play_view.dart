import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pipes/ui/core/l10n.dart';
import 'package:pipes/ui/core/theme/app_colors.dart';
import 'package:pipes/ui/core/widgets/tangible_button.dart';
import 'package:pipes/ui/providers.dart';

class HowToPlayView extends ConsumerWidget {
  const HowToPlayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    AppColors.currentTheme = settings.theme;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        L10n.t('How to Play', 'ක්‍රීඩා කරන ආකාරය'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  _guideStep(
                    stepNumber: '1',
                    title: L10n.t('Goal', 'අරමුණ'),
                    description: L10n.d('Connect every pipe on the grid so water flows from the source to every single pipe.', 'ජලය මූලාශ්‍රයේ සිට සෑම පයිප්පයකටම ගලා යන ලෙස ජාලයේ සියලු පයිප්ප සම්බන්ධ කරන්න.'),
                  ),
                  const SizedBox(height: 16),
                  _guideStep(
                    stepNumber: '2',
                    title: L10n.t('Water Source', 'ජල මූලාශ්‍රය'),
                    description: L10n.d('The source is at the center tile. Water automatically flows through any aligned, matching pipe connections.', 'මූලාශ්‍රය මැද කොටුවේ තිබේ. ගැළපෙන පරිදි සම්බන්ධ වී ඇති පයිප්ප හරහා ජලය ස්වයංක්‍රීයව ගලා යයි.'),
                  ),
                  const SizedBox(height: 16),
                  _guideStep(
                    stepNumber: '3',
                    title: L10n.t('Rotate Pipes', 'පයිප්ප කරකවන්න'),
                    description: L10n.d('Tap any pipe tile to rotate it 90° clockwise. Align each pipe with adjacent neighbors to expand the water circuit.', 'ඕනෑම පයිප්ප කොටුවක් ඔබා දක්ෂිණාවර්තව අංශක 90 කින් කරකවන්න. ජල මාර්ගය දිගු කිරීමට පයිප්ප එකිනෙකට ගැළපෙන සේ සකසන්න.'),
                  ),
                  const SizedBox(height: 16),
                  _guideStep(
                    stepNumber: '4',
                    title: L10n.t('Completion', 'සම්පූර්ණ කිරීම'),
                    description: L10n.d('The puzzle is completed when all pipes are connected to the source without any loose, leaking ends.', 'සියලු පයිප්ප කිසිදු කාන්දු වන කෙළවරක් නොමැතිව මූලාශ්‍රයට සම්බන්ධ වූ විට ප්‍රහේලිකාව සම්පූර්ණ වේ.'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: TangibleButton(
                text: L10n.t('Got it', 'තේරුණා'),
                height: 44,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guideStep({
    required String stepNumber,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$stepNumber.',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.headingDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.headingDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.subtext,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
