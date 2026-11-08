import 'package:flutter/foundation.dart';

const kForceWrappedWindowOpen =
    kDebugMode && bool.fromEnvironment('FORCE_WRAPPED_WINDOW_OPEN');

final class WrappedWindowPolicy {
  const WrappedWindowPolicy({this.forceOpen = kForceWrappedWindowOpen});

  static const daysBeforeMonthEnd = 0;
  static const lastGraceDay = 7;
  static const limaOffset = Duration(hours: -5);

  final bool forceOpen;

  String? activePeriod(DateTime now) {
    final lima = now.toUtc().add(limaOffset);
    final lastDay = DateTime.utc(lima.year, lima.month + 1, 0).day;
    if (forceOpen || lima.day >= lastDay - daysBeforeMonthEnd) {
      return _format(lima);
    }
    if (lima.day <= lastGraceDay) {
      return _format(DateTime.utc(lima.year, lima.month, 0));
    }
    return null;
  }

  static String _format(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';
}
