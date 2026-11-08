import 'package:pipes/ui/core/haptics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pipes/domain/models/app_settings.dart';
import 'package:pipes/ui/core/l10n.dart';
import 'package:pipes/ui/core/theme/app_colors.dart';
import 'package:pipes/ui/providers.dart';

/// Opens a bottom sheet with a button for every theme.
/// Tapping a button switches the whole app theme immediately.
void showThemePickerSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ThemePickerSheet(),
  );
}

class _ThemePickerSheet extends ConsumerWidget {
  const _ThemePickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(settingsProvider).theme;
    final light = AppThemePreset.values.where((t) => !t.isDark).toList();
    final dark = AppThemePreset.values.where((t) => t.isDark).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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
            Text(
              L10n.t('Themes', 'තේමා'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.headingDark,
              ),
            ),
            const SizedBox(height: 18),
            _sectionLabel(L10n.t('Light', 'ලා')),
            const SizedBox(height: 10),
            _grid(ref, light, current),
            const SizedBox(height: 20),
            _sectionLabel(L10n.t('Dark', 'තද')),
            const SizedBox(height: 10),
            _grid(ref, dark, current),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.subtext,
        ),
      );

  Widget _grid(WidgetRef ref, List<AppThemePreset> items, AppThemePreset current) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final t in items)
          _ThemeButton(
            preset: t,
            selected: t == current,
            onTap: () {
              AppHaptics.select();
              ref.read(settingsProvider.notifier).setTheme(t);
            },
          ),
      ],
    );
  }
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final AppThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 40 - 10) / 2;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: preset.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? preset.accent : preset.border,
            width: selected ? 2.5 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: preset.accent.withValues(alpha: 0.35),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: preset.accent,
                shape: BoxShape.circle,
                border: Border.all(color: preset.primary, width: 3),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                preset.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: preset.headingDark,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, size: 18, color: preset.accent),
          ],
        ),
      ),
    );
  }
}
