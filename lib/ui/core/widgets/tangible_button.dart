import 'package:pipes/ui/core/haptics.dart';
import 'package:flutter/material.dart';
import 'package:pipes/ui/core/theme/app_colors.dart';

Color _darken(Color c, [double amount = 0.18]) {
  final hsl = HSLColor.fromColor(c);
  return hsl
      .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
      .toColor();
}

Color _lighten(Color c, [double amount = 0.12]) {
  final hsl = HSLColor.fromColor(c);
  return hsl
      .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
      .toColor();
}

/// 3D pressable block: glossy top face + solid "thickness" below it.
/// When pressed, the face sinks into its base.
class Button3DBase extends StatefulWidget {
  const Button3DBase({
    super.key,
    required this.onPressed,
    required this.color,
    required this.child,
    this.borderRadius = 16,
    this.depth = 6,
    this.width,
    this.height,
    this.shape = BoxShape.rectangle,
    this.padding = EdgeInsets.zero,
  });

  final VoidCallback? onPressed;
  final Color color;
  final Widget child;
  final double borderRadius;
  final double depth;
  final double? width;
  final double? height;
  final BoxShape shape;
  final EdgeInsetsGeometry padding;

  @override
  State<Button3DBase> createState() => _Button3DBaseState();
}

class _Button3DBaseState extends State<Button3DBase> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final pressed = _pressed && enabled;
    final depth = widget.depth;
    final offset = pressed ? depth * 0.75 : 0.0;
    final top = _lighten(widget.color);
    final bottom = widget.color;
    final lip = _darken(widget.color, 0.22);
    final isCircle = widget.shape == BoxShape.circle;
    final radius = BorderRadius.circular(widget.borderRadius);

    final face = Container(
      width: widget.width,
      height: widget.height,
      padding: widget.padding,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: widget.shape,
        borderRadius: isCircle ? null : radius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // glossy highlight on the upper half
          if (!isCircle)
            Positioned(
              left: 8,
              right: 8,
              top: 3,
              height: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white.withValues(alpha: 0.22),
                ),
              ),
            ),
          widget.child,
        ],
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        if (enabled) {
          setState(() => _pressed = true);
          AppHaptics.select();
        }
      },
      onTapUp: (_) {
        if (enabled) {
          setState(() => _pressed = false);
          widget.onPressed!();
        }
      },
      onTapCancel: () {
        if (enabled) setState(() => _pressed = false);
      },
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: SizedBox(
          width: widget.width,
          height: widget.height == null ? null : widget.height! + depth,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // base / thickness
              Positioned(
                left: 0,
                right: 0,
                top: depth,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    shape: widget.shape,
                    borderRadius: isCircle ? null : radius,
                    color: lip,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        offset: Offset(0, pressed ? 2 : 5),
                        blurRadius: pressed ? 3 : 8,
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 70),
                curve: Curves.easeOut,
                left: 0,
                right: 0,
                top: offset,
                height: widget.height,
                child: face,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TangibleButton extends StatelessWidget {
  const TangibleButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isSecondary = false,
    this.height = 48,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.icon,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isSecondary;
  final double height;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final Color buttonBg = backgroundColor ??
        (isSecondary ? AppColors.surface : AppColors.primary);
    final Color fg = textColor ?? AppColors.headingDark;

    return Button3DBase(
      onPressed: onPressed,
      color: buttonBg,
      height: height,
      depth: 5,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: fg,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Round 3D icon button (used for back / refresh / music / emoji etc).
class Round3DButton extends StatelessWidget {
  const Round3DButton({
    super.key,
    required this.onTap,
    this.icon,
    this.emoji,
    this.size = 46,
    this.iconSize = 20,
    this.color,
    this.iconColor,
    this.active = false,
  });

  final VoidCallback? onTap;
  final IconData? icon;
  final String? emoji;
  final double size;
  final double iconSize;
  final Color? color;
  final Color? iconColor;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final bg = active ? AppColors.accent : (color ?? AppColors.surface);
    final fg = active ? Colors.white : (iconColor ?? AppColors.headingDark);
    return Button3DBase(
      onPressed: onTap,
      color: bg,
      width: size,
      height: size,
      depth: 5,
      shape: BoxShape.circle,
      child: emoji != null
          ? Text(emoji!, style: TextStyle(fontSize: iconSize))
          : Icon(icon, size: iconSize, color: fg),
    );
  }
}
