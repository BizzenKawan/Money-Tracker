import 'package:flutter/material.dart';

import '../models/account.dart';
import '../services/db_helper.dart';
import '../theme.dart';
import '../utils/formatters.dart';
import '../utils/nepali_months.dart';
import '../widgets/common.dart';
import 'home_page_settings_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<({int year, int month, double expense, double income})> _rows = [];
  List<Account> _accounts = [];
  int? _accountFilter;

  double _balance = 0;
  double _expense = 0;
  double _income = 0;

  bool _hideBalance = false;
  bool _revealed = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = DBHelper.instance;

    final rows = await db.monthlyHistory(accountId: _accountFilter);
    final accounts = await db.getAccounts();
    final totals = await db.lifetimeTotals(accountId: _accountFilter);
    final hide = await db.getBool('hide_balance');

    final balance = _accountFilter == null
        ? await db.totalBalance()
        : await db.accountBalance(_accountFilter!);

    if (!mounted) return;
    setState(() {
      _rows = rows;
      _accounts = accounts;
      _expense = totals.expense;
      _income = totals.income;
      _balance = balance;
      _hideBalance = hide;
      _loading = false;
    });
  }

  bool get _masked => _hideBalance && !_revealed;

  String _show(double value) => _masked ? '••••••' : money(value);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          PopupMenuButton<int?>(
            initialValue: _accountFilter,
            onSelected: (v) {
              setState(() => _accountFilter = v);
              _load();
            },
            itemBuilder: (context) => [
              const PopupMenuItem<int?>(value: null, child: Text('All')),
              for (final a in _accounts)
                PopupMenuItem<int?>(value: a.id, child: Text(a.name)),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _accountFilter == null
                      ? 'All'
                      : _accounts
                          .firstWhere((a) => a.id == _accountFilter)
                          .name,
                  style: const TextStyle(fontSize: 15),
                ),
                const Icon(Icons.arrow_drop_down),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _summary(),
                const Divider(height: 1),
                _tableHeader(),
                const Divider(height: 1),
                Expanded(
                  child: _rows.isEmpty
                      ? const EmptyState(
                          icon: Icons.history,
                          message: 'No transactions recorded yet',
                        )
                      : ListView(children: _buildRows()),
                ),
              ],
            ),
    );
  }

  Widget _summary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              const Spacer(),
              Column(
                children: [
                  const Text('Total balance',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textDim)),
                  const SizedBox(height: 4),
                  Text(
                    _show(_balance),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: _balance < 0 && !_masked
                          ? const Color(0xFFF2555A)
                          : AppColors.text,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                children: [
                  if (_hideBalance)
                    IconButton(
                      icon: Icon(_revealed
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      color: AppColors.textDim,
                      onPressed: () =>
                          setState(() => _revealed = !_revealed),
                    ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    color: AppColors.textDim,
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HomePageSettingsScreen()),
                      );
                      _revealed = false;
                      _load();
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text('Expenses',
                        style: TextStyle(
                            fontSize: 13.5, color: AppColors.textDim)),
                    const SizedBox(height: 3),
                    Text(_show(_expense),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(width: 1, height: 34, color: AppColors.divider),
              Expanded(
                child: Column(
                  children: [
                    const Text('Income',
                        style: TextStyle(
                            fontSize: 13.5, color: AppColors.textDim)),
                    const SizedBox(height: 3),
                    Text(_show(_income),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: const Row(
        children: [
          SizedBox(
            width: 70,
            child: Text('Month',
                style: TextStyle(fontSize: 14, color: AppColors.textDim)),
          ),
          Expanded(
            child: Text('Expenses',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 14, color: AppColors.textDim)),
          ),
          Expanded(
            child: Text('Income',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 14, color: AppColors.textDim)),
          ),
          Expanded(
            child: Text('Balance',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 14, color: AppColors.textDim)),
          ),
        ],
      ),
    );
  }

  /// Rows are grouped under a heading for each BS year.
  List<Widget> _buildRows() {
    final widgets = <Widget>[];
    int? lastYear;

    for (final r in _rows) {
      if (r.year != lastYear) {
        lastYear = r.year;
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              '${r.year} B.S.',
              style: const TextStyle(fontSize: 13, color: AppColors.textDim),
            ),
          ),
        );
      }

      final net = r.income - r.expense;
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  nepaliMonthsShort[r.month - 1],
                  style: const TextStyle(fontSize: 15.5),
                ),
              ),
              Expanded(
                child: Text(_show(r.expense),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 15.5)),
              ),
              Expanded(
                child: Text(_show(r.income),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 15.5)),
              ),
              Expanded(
                child: Text(
                  _show(net),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 15.5,
                    color: net < 0 && !_masked
                        ? const Color(0xFFF2555A)
                        : AppColors.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      widgets.add(const Divider(height: 1));
    }

    return widgets;
  }
}
