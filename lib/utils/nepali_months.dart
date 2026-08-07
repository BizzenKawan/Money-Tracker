/// Bikram Sambat month names, index 0 = Baisakh (month 1).
const List<String> nepaliMonths = [
  'Baisakh',
  'Jestha',
  'Ashadh',
  'Shrawan',
  'Bhadra',
  'Ashwin',
  'Kartik',
  'Mangsir',
  'Poush',
  'Magh',
  'Falgun',
  'Chaitra',
];

/// Short forms used in tight spaces.
const List<String> nepaliMonthsShort = [
  'Bai',
  'Jes',
  'Ash',
  'Shr',
  'Bha',
  'Asw',
  'Kar',
  'Man',
  'Pou',
  'Mag',
  'Fal',
  'Cha',
];

String monthName(int bsMonth) => nepaliMonths[bsMonth - 1];

// Dart's DateTime.weekday is 1 = Monday ... 7 = Sunday. The calendar itself
// stays Bikram Sambat throughout the app - only the weekday label is in
// English, matching how most people actually say "Sunday", "Monday", etc.
const List<String> _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

String weekdayName(DateTime adDate) => _weekdayNames[adDate.weekday - 1];

/// Steps a (year, month) pair backwards or forwards, wrapping correctly.
({int year, int month}) shiftMonth(int year, int month, int delta) {
  var total = (year * 12) + (month - 1) + delta;
  return (year: total ~/ 12, month: (total % 12) + 1);
}
