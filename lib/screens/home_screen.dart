import 'package:flutter/material.dart';
import 'package:nepali_utils/nepali_utils.dart';

import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/db_helper.dart';
import '../theme.dart';
import '../utils/formatters.dart';
import '../utils/nepali_months.dart';
import '../widgets/common.dart';
import 'calendar_screen.dart';
import 'history_screen.dart';
import 'search_screen.dart';
import 'transaction_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onChanged;

  const HomeScreen({super.key, required this.onChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _year;
  late int _month;

  List<MoneyTransaction> _txs = [];
  Map<int, Category> _categories = {};
  Map<int, Account> _accounts = {};
  double _expense = 0;
  double _income = 0;
  bool _hideTotals = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final now = NepaliDateTime.now();
    _year = now.year;
    _month = now.month;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = DBHelper.instance;
    final txs = await db.transactionsForMonth(_year, _month);
    final cats = await db.getCategoryLookup();
    final accounts = await db.getAccounts();
    final totals = await db.monthTotals(_year, _month);
    final hideTotals = await db.getBool('hide_home_totals');

    if (!mounted) return;
    setState(() {
      _txs = txs;
      _categories = cats;
      _accounts = {for (final a in accounts) a.id!: a};
      _expense = totals.expense;
      _income = totals.income;
      _hideTotals = hideTotals;
      _loading = false;
    });
  }

  Future<void> _changeMonth() async {
    final picked = await pickBsMonth(context, year: _year, month: _month);
    if (picked == null) return;
    setState(() {
      _year = picked.year;
      _month = picked.month;
    });
    _load();
  }

  Future<void> _openCalendar() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CalendarScreen(
          initialYear: _year,
          initialMonth: _month,
        ),
      ),
    );
    if (changed == true) {
      await _load();
      widget.onChanged();
    }
  }

  Future<void> _openHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
    // The settings screen reached from here can change how totals display.
    _load();
  }

  Future<void> _openDetail(MoneyTransaction t) async {
    final result = await Navigator.push<DetailResult>(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionDetailScreen(transaction: t),
      ),
    );
    if (result == DetailResult.edited || result == DetailResult.deleted) {
      await _load();
      widget.onChanged();
    }
  }

  Future<void> _deleteTransaction(MoneyTransaction t) async {
    await DBHelper.instance.deleteTransaction(t.id!);
    await _load();
    widget.onChanged();
  }

  /// Groups transactions by BS day, newest day first, and computes per-day
  /// subtotals shown in the day header.
  List<_DayGroup> _grouped() {
    final byDay = <int, List<MoneyTransaction>>{};
    for (final t in _txs) {
      byDay.putIfAbsent(t.bsDay, () => []).add(t);
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    return days.map((d) {
      final items = byDay[d]!;
      double exp = 0, inc = 0;
      for (final t in items) {
        if (t.type == 'expense') exp += t.amount;
        if (t.type == 'income') inc += t.amount;
      }
      return _DayGroup(day: d, items: items, expense: exp, income: inc);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Money Tracker'),
        leading: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: _openCalendar,
          ),
        ],
      ),
      body: Column(
        children: [
          _header(),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _txs.isEmpty
                    ? const EmptyState(
                        icon: Icons.receipt_long,
                        message: 'No transactions this month yet',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.only(bottom: 90),
                          children: [
                            for (final g in _grouped()) ...[
                              _dayHeader(g),
                              for (final t in g.items) _row(t),
                            ],
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      child: Row(
        children: [
          InkWell(
            onTap: _changeMonth,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text('$_year',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textDim)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(nepaliMonthsShort[_month - 1],
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w600)),
                      const Icon(Icons.expand_more, size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: _openHistory,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Expanded(child: _total('Expenses', _expense)),
                  Expanded(child: _total('Income', _income)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _total(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: AppColors.textDim)),
        const SizedBox(height: 2),
        Text(_hideTotals ? '••••' : money(value),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _dayHeader(_DayGroup g) {
    final ad = NepaliDateTime(_year, _month, g.day).toDateTime();
    final parts = <String>[
      if (g.expense > 0) 'Expenses: ${money(g.expense)}',
      if (g.income > 0) 'Income: ${money(g.income)}',
    ];

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Row(
        children: [
          Text('${nepaliMonthsShort[_month - 1]} ${g.day}',
              style: const TextStyle(fontSize: 13, color: AppColors.textDim)),
          const SizedBox(width: 10),
          Text(weekdayName(ad),
              style: const TextStyle(fontSize: 13, color: AppColors.textDim)),
          const Spacer(),
          Text(parts.join('   '),
              style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
        ],
      ),
    );
  }

  Widget _row(MoneyTransaction t) {
    final isTransfer = t.type == 'transfer';
    final cat = t.categoryId == null ? null : _categories[t.categoryId];

    final title = isTransfer
        ? '${_accounts[t.accountId]?.name ?? 'Unassigned'} → '
            '${_accounts[t.toAccountId]?.name ?? 'Unassigned'}'
        : (t.note.isNotEmpty ? t.note : (cat?.name ?? 'Uncategorised'));

    final subtitle = isTransfer
        ? (t.note.isEmpty ? null : t.note)
        : (t.note.isNotEmpty ? cat?.name : null);

    final amountColor = switch (t.type) {
      'income' => AppColors.income,
      'expense' => AppColors.text,
      _ => AppColors.textDim,
    };

    return Dismissible(
      key: ValueKey('tx${t.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: const Color(0xFFB3261E),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.surface,
                title: const Text('Delete this transaction?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => _deleteTransaction(t),
      child: ListTile(
        onTap: () => _openDetail(t),
        leading: isTransfer
            ? const RoundIcon(iconName: 'currency_exchange', colorValue: 0xFF616161)
            : RoundIcon(
                iconName: cat?.iconName ?? 'category',
                colorValue: cat?.colorValue ?? 0xFF616161,
              ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: subtitle == null
            ? null
            : Text(subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
        trailing: Text(
          signedMoney(t.amount, t.type),
          style: TextStyle(
            color: amountColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _DayGroup {
  final int day;
  final List<MoneyTransaction> items;
  final double expense;
  final double income;

  _DayGroup({
    required this.day,
    required this.items,
    required this.expense,
    required this.income,
  });
}
