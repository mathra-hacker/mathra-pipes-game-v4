import 'package:flutter/services.dart';

/// Haptic feedback that respects the "Vibration" switch in Settings.
class AppHaptics {
  AppHaptics._();

  static bool enabled = true;

  static void select() {
    if (enabled) HapticFeedback.selectionClick();
  }

  static void light() {
    if (enabled) HapticFeedback.lightImpact();
  }

  static void medium() {
    if (enabled) HapticFeedback.mediumImpact();
  }

  static void heavy() {
    if (enabled) HapticFeedback.heavyImpact();
  }
}
