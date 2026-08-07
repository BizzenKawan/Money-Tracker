import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:nepali_utils/nepali_utils.dart';

import '../models/category.dart';
import '../services/db_helper.dart';
import '../theme.dart';
import '../utils/formatters.dart';
import '../utils/nepali_months.dart';
import '../widgets/common.dart';
import 'category_detail_screen.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  String _type = 'expense';
  late int _year;
  late int _month;

  List<({Category category, double total})> _rows = [];
  double _sum = 0;
  bool _loading = true;

  /// The twelve most recent BS months, oldest first, used as the period strip.
  late final List<({int year, int month})> _periods;

  @override
  void initState() {
    super.initState();
    final now = NepaliDateTime.now();
    _year = now.year;
    _month = now.month;
    _periods = List.generate(12, (i) {
      return shiftMonth(now.year, now.month, -(11 - i));
    });
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows =
        await DBHelper.instance.categoryBreakdown(_year, _month, _type);
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _sum = rows.fold(0.0, (s, r) => s + r.total);
      _loading = false;
    });
  }

  void _selectPeriod(({int year, int month}) p) {
    setState(() {
      _year = p.year;
      _month = p.month;
    });
    _load();
  }

  String _periodLabel(({int year, int month}) p) {
    final now = NepaliDateTime.now();
    if (p.year == now.year && p.month == now.month) return 'This Month';
    final last = shiftMonth(now.year, now.month, -1);
    if (p.year == last.year && p.month == last.month) return 'Last Month';
    return '${nepaliMonthsShort[p.month - 1]} ${p.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _toggle('Expenses', 'expense'),
              _toggle('Income', 'income'),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                for (final p in _periods.reversed)
                  _periodTab(p),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _rows.isEmpty
                    ? const EmptyState(
                        icon: Icons.pie_chart_outline,
                        message: 'Nothing recorded for this month',
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 90),
                        children: [
                          const SizedBox(height: 16),
                          _donut(),
                          const SizedBox(height: 20),
                          const Divider(height: 1),
                          for (final r in _rows) _breakdownRow(r),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _toggle(String label, String value) {
    final selected = _type == value;
    return GestureDetector(
      onTap: () {
        setState(() => _type = value);
        _load();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.text : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _periodTab(({int year, int month}) p) {
    final selected = p.year == _year && p.month == _month;
    return GestureDetector(
      onTap: () => _selectPeriod(p),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          _periodLabel(p),
          style: TextStyle(
            color: selected ? AppColors.text : AppColors.textDim,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _donut() {
    // Only the top five slices get their own colour; the rest roll up into
    // "Other" so the chart stays readable.
    final top = _rows.take(5).toList();
    final otherTotal = _rows.skip(5).fold(0.0, (s, r) => s + r.total);

    final sections = <PieChartSectionData>[
      for (final r in top)
        PieChartSectionData(
          value: r.total,
          color: Color(r.category.colorValue),
          radius: 26,
          showTitle: false,
        ),
      if (otherTotal > 0)
        PieChartSectionData(
          value: otherTotal,
          color: const Color(0xFF5A5A5A),
          radius: 26,
          showTitle: false,
        ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 48,
                    sectionsSpace: 2,
                    startDegreeOffset: -90,
                  ),
                ),
                Text(
                  money(_sum),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              children: [
                for (final r in top)
                  _legend(
                    Color(r.category.colorValue),
                    r.category.name,
                    r.total / _sum,
                  ),
                if (otherTotal > 0)
                  _legend(
                    const Color(0xFF5A5A5A),
                    'Other',
                    otherTotal / _sum,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label, double fraction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5)),
          ),
          Text('${(fraction * 100).toStringAsFixed(2)}%',
              style: const TextStyle(fontSize: 13.5)),
        ],
      ),
    );
  }

  Future<void> _openCategory(Category category) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryDetailScreen(
          category: category,
          initialYear: _year,
          initialMonth: _month,
        ),
      ),
    );
    if (changed == true) _load();
  }

  Widget _breakdownRow(({Category category, double total}) r) {
    final fraction = _sum == 0 ? 0.0 : r.total / _sum;
    final color = Color(r.category.colorValue);

    return InkWell(
      onTap: () => _openCategory(r.category),
      child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          RoundIcon(
            iconName: r.category.iconName,
            colorValue: r.category.colorValue,
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
                      child: Text(r.category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15.5)),
                    ),
                    Text(money(r.total),
                        style: const TextStyle(
                            fontSize: 15.5, fontWeight: FontWeight.w500)),
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
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right,
                        size: 16, color: AppColors.textDim),
                  ],
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
