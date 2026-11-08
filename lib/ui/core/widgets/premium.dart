import 'package:pipes/ui/core/haptics.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pipes/ui/core/l10n.dart';
import 'package:pipes/ui/core/theme/app_colors.dart';
import 'package:pipes/ui/core/widgets/tangible_button.dart';

/// Makes a colour darker (negative [amount] = lighter).
Color shade(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl
      .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
      .toColor();
}

/// Soft animated background: gradient + two slowly drifting glows.
class PremiumBackground extends StatefulWidget {
  const PremiumBackground({super.key, required this.child});

  final Widget child;

  @override
  State<PremiumBackground> createState() => _PremiumBackgroundState();
}

class _PremiumBackgroundState extends State<PremiumBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _orb(double size, Color color, double alpha) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.bg,
                Color.lerp(AppColors.bg, AppColors.accent, 0.10)!,
                AppColors.bg,
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: -80 + 60 * t,
                top: -60 + 40 * t,
                child: _orb(260, AppColors.accent, 0.22),
              ),
              Positioned(
                right: -90 + 50 * (1 - t),
                bottom: 80 - 40 * t,
                child: _orb(300, AppColors.primary, 0.35),
              ),
              RepaintBoundary(child: child!),
            ],
          ),
        );
      },
    );
  }
}

/// A "slab" card with real thickness (solid lip + soft shadow).
class Panel3D extends StatelessWidget {
  const Panel3D({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.depth = 6,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double depth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = color ?? AppColors.surface;
    final lip = shade(base, 0.16);
    return Container(
      margin: EdgeInsets.only(bottom: depth),
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [shade(base, -0.06), base],
        ),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.7),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(color: lip, offset: Offset(0, depth)),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            offset: Offset(0, depth + 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Tilts its child in 3D while the finger is on it, and floats gently.
/// Uses raw pointer events, so it never blocks scrolling or taps.
class Tilt3D extends StatefulWidget {
  const Tilt3D({super.key, required this.child, this.maxTilt = 0.22});

  final Widget child;
  final double maxTilt;

  @override
  State<Tilt3D> createState() => _Tilt3DState();
}

class _Tilt3DState extends State<Tilt3D> with SingleTickerProviderStateMixin {
  Offset _tilt = Offset.zero;
  bool _active = false;

  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  void _update(Offset local) {
    final box = context.findRenderObject();
    if (box is! RenderBox || box.size.isEmpty) return;
    final dx = (local.dx / box.size.width * 2 - 1).clamp(-1.0, 1.0);
    final dy = (local.dy / box.size.height * 2 - 1).clamp(-1.0, 1.0);
    setState(() {
      _active = true;
      _tilt = Offset(dx * widget.maxTilt, -dy * widget.maxTilt);
    });
  }

  void _release() {
    setState(() {
      _active = false;
      _tilt = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (e) => _update(e.localPosition),
      onPointerMove: (e) => _update(e.localPosition),
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: AnimatedBuilder(
        animation: _float,
        child: widget.child,
        builder: (context, child) {
          final lift = math.sin(_float.value * math.pi) * 6;
          return Transform.translate(
            offset: Offset(0, -lift),
            child: AnimatedContainer(
              duration: Duration(milliseconds: _active ? 60 : 450),
              curve: Curves.easeOutCubic,
              transformAlignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0014)
                ..rotateX(_tilt.dy)
                ..rotateY(_tilt.dx),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

/// Round logo (the Mathra Pipes artwork) with a glow.
class LogoBadge extends StatelessWidget {
  const LogoBadge({super.key, this.size = 34});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.5),
            blurRadius: 12,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/icon.png',
          fit: BoxFit.cover,
          cacheWidth: (size * 3).round(),
        ),
      ),
    );
  }
}

/// Standard top bar: back button, title, optional trailing widget.
class PremiumHeader extends StatelessWidget {
  const PremiumHeader({
    super.key,
    required this.title,
    this.icon = Icons.arrow_back_ios_new_rounded,
    this.trailing,
    this.onBack,
  });

  final String title;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Round3DButton(
            icon: icon,
            iconSize: 18,
            onTap: onBack ?? () => Navigator.pop(context),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.headingDark,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 46, height: 46, child: trailing),
        ],
      ),
    );
  }
}

/// A titled card used in Settings.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.iconColor,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final c = iconColor ?? AppColors.accent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Panel3D(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [shade(c, -0.08), shade(c, 0.12)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: c.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 19, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.headingDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Wrap of selectable pills (language, effect, quality ...).
class OptionPills<T> extends StatelessWidget {
  const OptionPills({
    super.key,
    required this.items,
    required this.selected,
    required this.label,
    required this.onSelect,
    this.leading,
  });

  final List<T> items;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelect;
  final String Function(T)? leading;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: [
        for (final it in items) _pill(it),
      ],
    );
  }

  Widget _pill(T it) {
    final on = it == selected;
    final fg = on ? Colors.white : AppColors.headingDark;
    return GestureDetector(
      onTap: () {
        AppHaptics.select();
        onSelect(it);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: on
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [shade(AppColors.accent, -0.08), AppColors.accent],
                )
              : null,
          color: on ? null : AppColors.bg,
          border: Border.all(
            color: on ? Colors.white.withValues(alpha: 0.4) : AppColors.border,
            width: 1.2,
          ),
          boxShadow: on
              ? [
                  BoxShadow(
                    color: shade(AppColors.accent, 0.18),
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              Text(leading!(it), style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
            ],
            Text(
              label(it),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Label + optional hint + animated switch.
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final String? hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        AppHaptics.select();
        onChanged(!value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.headingDark,
                    ),
                  ),
                  if (hint != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        hint!,
                        style: TextStyle(fontSize: 11.5, color: AppColors.subtext),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 52,
              height: 30,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: value
                    ? AppColors.accent
                    : AppColors.headingDark.withValues(alpha: 0.14),
                border: Border.all(
                  color: value ? shade(AppColors.accent, 0.12) : AppColors.border,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        offset: const Offset(0, 2),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Big coloured 3D tile for the dashboard.
class DashTile extends StatelessWidget {
  const DashTile({
    super.key,
    required this.icon,
    required this.en,
    required this.si,
    required this.color,
    required this.onTap,
    this.height = 104,
  });

  final IconData icon;
  final String en;
  final String si;
  final Color color;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Button3DBase(
      onPressed: onTap,
      color: color,
      height: height,
      depth: 7,
      borderRadius: 22,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            ),
            child: Icon(icon, size: 22, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                L10n.d(en, si),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black38, blurRadius: 3)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small stat capsule (moves / time / progress).
class StatPill extends StatelessWidget {
  const StatPill({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.headingDark,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(fontSize: 10, color: AppColors.subtext),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon + tiny label 3D button used in the in-game dock.
class DockButton extends StatelessWidget {
  const DockButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.color,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;
  final Color? color;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final bg = active ? AppColors.accent : (color ?? AppColors.primary);
    final fg = active ? Colors.white : (iconColor ?? AppColors.headingDark);
    return Button3DBase(
      onPressed: onTap,
      color: bg,
      height: 54,
      depth: 5,
      borderRadius: 16,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: fg),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
