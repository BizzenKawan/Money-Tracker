import 'package:flutter/material.dart';
import 'package:nepali_utils/nepali_utils.dart';

import '../theme.dart';
import '../utils/icon_catalog.dart';
import '../utils/nepali_months.dart';

/// Circular coloured icon used for categories and accounts.
class RoundIcon extends StatelessWidget {
  final String iconName;
  final int colorValue;
  final double size;

  const RoundIcon({
    super.key,
    required this.iconName,
    required this.colorValue,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color(colorValue),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconFor(iconName),
        color: Colors.white,
        size: size * 0.52,
      ),
    );
  }
}

/// Bottom sheet that lets the user pick a Bikram Sambat year + month.
Future<({int year, int month})?> pickBsMonth(
  BuildContext context, {
  required int year,
  required int month,
}) {
  return showModalBottomSheet<({int year, int month})>(
    context: context,
    builder: (ctx) => _MonthPickerSheet(initialYear: year, initialMonth: month),
  );
}

class _MonthPickerSheet extends StatefulWidget {
  final int initialYear;
  final int initialMonth;

  const _MonthPickerSheet({
    required this.initialYear,
    required this.initialMonth,
  });

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _year = widget.initialYear;

  @override
  Widget build(BuildContext context) {
    final thisYear = NepaliDateTime.now().year;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => setState(() => _year--),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  '$_year B.S.',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: _year >= thisYear + 5
                      ? null
                      : () => setState(() => _year++),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: List.generate(12, (i) {
                final m = i + 1;
                final selected =
                    m == widget.initialMonth && _year == widget.initialYear;
                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () =>
                      Navigator.pop(context, (year: _year, month: m)),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.accent
                          : AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      nepaliMonths[i],
                      style: TextStyle(
                        color: selected ? Colors.black : AppColors.text,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small helper for empty states.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textDim),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppColors.textDim)),
        ],
      ),
    );
  }
}
