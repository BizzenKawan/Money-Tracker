import 'package:flutter/material.dart';
import 'package:nepali_utils/nepali_utils.dart';

import '../services/db_helper.dart';
import '../theme.dart';
import '../utils/bs_calendar.dart';
import '../utils/formatters.dart';
import '../utils/nepali_months.dart';
import '../widgets/common.dart';
import 'add_transaction_screen.dart';

class CalendarScreen extends StatefulWidget {
  final int initialYear;
  final int initialMonth;

  const CalendarScreen({
    super.key,
    required this.initialYear,
    required this.initialMonth,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late int _year = widget.initialYear;
  late int _month = widget.initialMonth;

  Map<int, ({double expense, double income})> _totals = {};
  bool _loading = true;
  bool _changed = false;

  static const _weekdayHeaders = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final totals = await DBHelper.instance.dailyTotals(_year, _month);
    if (!mounted) return;
    setState(() {
      _totals = totals;
      _loading = false;
    });
  }

  Future<void> _pickMonth() async {
    final picked = await pickBsMonth(context, year: _year, month: _month);
    if (picked == null) return;
    setState(() {
      _year = picked.year;
      _month = picked.month;
    });
    _load();
  }

  void _step(int delta) {
    final next = shiftMonth(_year, _month, delta);
    setState(() {
      _year = next.year;
      _month = next.month;
    });
    _load();
  }

  Future<void> _addForDay(int day) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          initialDate: NepaliDateTime(_year, _month, day),
        ),
      ),
    );
    if (saved == true) {
      _changed = true;
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayCount = daysInBsMonth(_year, _month);
    final leadingBlanks = firstWeekdayColumn(_year, _month);
    final cellCount = leadingBlanks + dayCount;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Calendar'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _changed),
          ),
          actions: [
            TextButton(
              onPressed: _pickMonth,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${nepaliMonthsShort[_month - 1]} $_year',
                    style: const TextStyle(
                        color: AppColors.text, fontSize: 15),
                  ),
                  const Icon(Icons.arrow_drop_down, color: AppColors.text),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _step(-1),
                ),
                Text(
                  '${monthName(_month)} $_year B.S.',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _step(1),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  for (final h in _weekdayHeaders)
                    Expanded(
                      child: Center(
                        child: Text(
                          h,
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.textDim),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_loading)
              const Expanded(
                  child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                  child: Column(
                    children: [
                      // A GridView lays the month out reliably. The previous
                      // hand-built Row/Column grid used stretch alignment
                      // inside an unbounded scroll view, which silently
                      // dropped every row after the first.
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisExtent: 68,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                        ),
                        itemCount: cellCount,
                        itemBuilder: (context, index) {
                          final day = index - leadingBlanks + 1;
                          if (day < 1) return const SizedBox.shrink();
                          return _cell(day);
                        },
                      ),
                      const SizedBox(height: 16),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Tap any day to record a transaction for that date - '
                          'useful for entries you forgot to log at the time.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textDim),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cell(int day) {
    final totals = _totals[day];
    final hasActivity =
        totals != null && (totals.expense > 0 || totals.income > 0);
    final today = isBsToday(_year, _month, day);

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => _addForDay(day),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
        decoration: BoxDecoration(
          color: hasActivity ? const Color(0xFF1B2A20) : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border:
              today ? Border.all(color: AppColors.accent, width: 1.4) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 14,
                fontWeight: today ? FontWeight.w700 : FontWeight.w500,
                color: today ? AppColors.accent : AppColors.text,
              ),
            ),
            const Spacer(),
            if (totals != null && totals.income > 0)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  money(totals.income),
                  style: const TextStyle(
                      fontSize: 10.5, color: Color(0xFF4CC38A)),
                ),
              ),
            if (totals != null && totals.expense > 0)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  money(totals.expense),
                  style: const TextStyle(
                      fontSize: 10.5, color: Color(0xFFE8615F)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
