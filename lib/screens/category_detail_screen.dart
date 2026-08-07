import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/transaction.dart';
import '../services/db_helper.dart';
import '../theme.dart';
import '../utils/bs_calendar.dart';
import '../utils/formatters.dart';
import '../utils/nepali_months.dart';
import '../widgets/common.dart';
import 'transaction_detail_screen.dart';

/// Shows every transaction in one category for one BS month, with a daily
/// trend line and a sortable breakdown - the drill-down from the Charts tab.
class CategoryDetailScreen extends StatefulWidget {
  final Category category;
  final int initialYear;
  final int initialMonth;

  const CategoryDetailScreen({
    super.key,
    required this.category,
    required this.initialYear,
    required this.initialMonth,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  late int _year = widget.initialYear;
  late int _month = widget.initialMonth;

  List<MoneyTransaction> _txs = [];
  bool _sortByAmount = true;
  bool _loading = true;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final txs = await DBHelper.instance.transactionsForCategoryMonth(
      _year,
      _month,
      widget.category.id!,
    );
    if (!mounted) return;
    setState(() {
      _txs = txs;
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

  double get _total => _txs.fold(0.0, (s, t) => s + t.amount);

  /// Average spend per day across the whole month, which is what makes the
  /// figure comparable between a 30 and a 32 day month.
  double get _average {
    final days = daysInBsMonth(_year, _month);
    if (days == 0) return 0;
    return _total / days;
  }

  List<MoneyTransaction> get _sorted {
    final list = [..._txs];
    if (_sortByAmount) {
      list.sort((a, b) => b.amount.compareTo(a.amount));
    } else {
      list.sort((a, b) => b.bsDay.compareTo(a.bsDay));
    }
    return list;
  }

  Future<void> _openTransaction(MoneyTransaction t) async {
    final result = await Navigator.push<DetailResult>(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionDetailScreen(transaction: t),
      ),
    );
    if (result == DetailResult.edited || result == DetailResult.deleted) {
      _changed = true;
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.category.colorValue);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.category.name),
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
                    style:
                        const TextStyle(color: AppColors.text, fontSize: 15),
                  ),
                  const Icon(Icons.arrow_drop_down, color: AppColors.text),
                ],
              ),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _txs.isEmpty
                ? EmptyState(
                    icon: Icons.receipt_long,
                    message:
                        'Nothing in ${widget.category.name} for ${monthName(_month)} $_year',
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      _summary(),
                      _chart(color),
                      _sortBar(),
                      const Divider(height: 1),
                      for (final t in _sorted) _row(t, color),
                    ],
                  ),
      ),
    );
  }

  Widget _summary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total: ${money(_total)}',
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Average: ${_average.toStringAsFixed(2)} per day',
              style:
                  const TextStyle(fontSize: 14, color: AppColors.textDim)),
        ],
      ),
    );
  }

  /// One point per transaction, positioned by BS day of month.
  Widget _chart(Color color) {
    final dayCount = daysInBsMonth(_year, _month);

    // Sum multiple transactions that landed on the same day.
    final byDay = <int, double>{};
    for (final t in _txs) {
      byDay[t.bsDay] = (byDay[t.bsDay] ?? 0) + t.amount;
    }
    final days = byDay.keys.toList()..sort();
    final spots = [
      for (final d in days) FlSpot(d.toDouble(), byDay[d]!),
    ];

    if (spots.length < 2) {
      // A single point has no trend to show, so skip the chart entirely.
      return const SizedBox(height: 8);
    }

    final maxY = byDay.values.reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
      child: SizedBox(
        height: 170,
        child: LineChart(
          LineChartData(
            minX: 1,
            maxX: dayCount.toDouble(),
            minY: 0,
            maxY: maxY * 1.15,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => const FlLine(
                color: AppColors.divider,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  getTitlesWidget: (value, meta) {
                    if (value == 0 || value >= maxY) {
                      return Text(
                        money(value),
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textDim),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: 7,
                  getTitlesWidget: (value, meta) => Text(
                    '${nepaliMonthsShort[_month - 1]} ${value.toInt()}',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textDim),
                  ),
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => spots
                    .map((s) => LineTooltipItem(
                          '${nepaliMonthsShort[_month - 1]} ${s.x.toInt()}\n${money(s.y)}',
                          const TextStyle(
                              color: AppColors.text, fontSize: 12),
                        ))
                    .toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: false,
                color: color,
                barWidth: 2,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                    radius: 3.5,
                    color: color,
                    strokeWidth: 0,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: color.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sortBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 12, 10),
      child: Row(
        children: [
          Text(
            widget.category.type == 'income' ? 'Income' : 'Expenses',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _sortChip('Sort by amount', true),
                _sortChip('Sort by date', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sortChip(String label, bool byAmount) {
    final selected = _sortByAmount == byAmount;
    return GestureDetector(
      onTap: () => setState(() => _sortByAmount = byAmount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.textDim : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: selected ? Colors.black : AppColors.textDim,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _row(MoneyTransaction t, Color color) {
    final fraction = _total == 0 ? 0.0 : t.amount / _total;

    return InkWell(
      onTap: () => _openTransaction(t),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RoundIcon(
              iconName: widget.category.iconName,
              colorValue: widget.category.colorValue,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.note.isNotEmpty
                              ? t.note
                              : widget.category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(money(t.amount),
                          style: const TextStyle(
                              fontSize: 15.5, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 6,
                            backgroundColor: AppColors.surfaceHigh,
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${(fraction * 100).toStringAsFixed(2)}%',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textDim)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${monthName(t.bsMonth)} ${t.bsDay}, ${t.bsYear}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textDim),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
