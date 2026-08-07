import 'package:nepali_utils/nepali_utils.dart';

import 'nepali_months.dart';

/// Number of days in a Bikram Sambat month.
///
/// BS months run 29-32 days and the pattern changes year to year, so this is
/// derived rather than hardcoded. Two independent methods are tried and each
/// result is sanity-checked, because a wrong answer here silently breaks the
/// whole calendar grid.
int daysInBsMonth(int year, int month) {
  // Method 1: measure the real gap between the 1st of this month and the 1st
  // of the next month in Gregorian days.
  try {
    final start = NepaliDateTime(year, month, 1).toDateTime();
    final next = shiftMonth(year, month, 1);
    final end = NepaliDateTime(next.year, next.month, 1).toDateTime();
    final days = (end.difference(start).inHours / 24).round();
    if (days >= 29 && days <= 32) return days;
  } catch (_) {
    // fall through to the second method
  }

  // Method 2: walk forward from day 1 until the month rolls over.
  try {
    for (var day = 29; day <= 32; day++) {
      final probe = NepaliDateTime(year, month, 1).add(Duration(days: day));
      if (probe.month != month) return day;
    }
  } catch (_) {
    // fall through to the floor below
  }

  // Never return something that would collapse the grid.
  return 30;
}

/// Which column the 1st of the month falls in, for a Sunday-first grid.
/// Dart weekday is 1 = Monday ... 7 = Sunday, so Sunday maps to column 0.
int firstWeekdayColumn(int year, int month) {
  try {
    return NepaliDateTime(year, month, 1).toDateTime().weekday % 7;
  } catch (_) {
    return 0;
  }
}

/// True when the given BS date is today.
bool isBsToday(int year, int month, int day) {
  final now = NepaliDateTime.now();
  return now.year == year && now.month == month && now.day == day;
}
