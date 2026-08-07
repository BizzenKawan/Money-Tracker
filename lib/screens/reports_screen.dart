import 'package:flutter/material.dart';
import 'package:nepali_utils/nepali_utils.dart';

import '../models/account.dart';
import '../services/db_helper.dart';
import '../theme.dart';
import '../utils/formatters.dart';
import '../utils/nepali_months.dart';
import '../widgets/common.dart';
import '../utils/sound.dart';
import 'accounts_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  late int _year;
  late int _month;

  double _expense = 0;
  double _income = 0;
  double? _budget;

  List<({Account account, double balance})> _accounts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final now = NepaliDateTime.now();
    _year = now.year;
    _month = now.month;
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = DBHelper.instance;
    final totals = await db.monthTotals(_year, _month);
    final budget = await db.getBudget(_year, _month);
    final accounts = await db.getAccounts();

    final withBalances = <({Account account, double balance})>[];
    for (final a in accounts) {
      withBalances.add((account: a, balance: await db.accountBalance(a.id!)));
    }

    if (!mounted) return;
    setState(() {
      _expense = totals.expense;
      _income = totals.income;
      _budget = budget;
      _accounts = withBalances;
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

  Future<void> _editBudget() async {
    final controller = TextEditingController(
      text: _budget == null ? '' : _budget!.toStringAsFixed(0),
    );

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Budget for ${monthName(_month)} $_year'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: 'Rs. ', hintText: '0'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, '__clear__'),
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;
    saveFeedback();
    final db = DBHelper.instance;
    if (result == '__clear__') {
      await db.clearBudget(_year, _month);
    } else {
      final value = double.tryParse(result);
      if (value == null || value <= 0) return;
      await db.setBudget(_year, _month, value);
    }
    _load();
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
          child: TabBar(
            controller: _tabs,
            isScrollable: false,
            indicator: BoxDecoration(
              color: AppColors.text,
              borderRadius: BorderRadius.circular(6),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.black,
            unselectedLabelColor: AppColors.text,
            labelPadding: const EdgeInsets.symmetric(horizontal: 22),
            tabs: const [Tab(text: 'Analytics'), Tab(text: 'Accounts')],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [_analytics(), _accountsTab()],
            ),
    );
  }

  Widget _analytics() {
    final remaining = (_budget ?? 0) - _expense;
    final progress =
        (_budget == null || _budget == 0) ? null : (_expense / _budget!);

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
      children: [
        _card(
          onTap: _changeMonth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Monthly Statistics — ${monthName(_month)} $_year',
                      style: const TextStyle(
                          fontSize: 15.5, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: AppColors.textDim),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _stat('Expenses', _expense)),
                  Expanded(child: _stat('Income', _income)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Net: ${money(_income - _expense)}',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textDim),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _card(
          onTap: _editBudget,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Monthly Budget',
                      style: TextStyle(
                          fontSize: 15.5, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: AppColors.textDim),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _budgetLine('Budget', money(_budget ?? 0)),
                        _budgetLine('Expenses', money(_expense)),
                        const Divider(height: 18),
                        _budgetLine(
                          'Remaining',
                          money(remaining),
                          color: remaining < 0
                              ? const Color(0xFFF2555A)
                              : AppColors.income,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 92,
                    height: 92,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 92,
                          height: 92,
                          child: CircularProgressIndicator(
                            value: progress?.clamp(0.0, 1.0).toDouble(),
                            strokeWidth: 6,
                            backgroundColor: AppColors.surfaceHigh,
                            valueColor: AlwaysStoppedAnimation(
                              (progress ?? 0) > 1
                                  ? const Color(0xFFF2555A)
                                  : AppColors.accent,
                            ),
                          ),
                        ),
                        Text(
                          progress == null
                              ? 'Set\nbudget'
                              : '${(progress * 100).toStringAsFixed(0)}%',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textDim),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _accountsTab() {
    final net = _accounts.fold(0.0, (s, a) => s + a.balance);

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Net worth',
                  style: TextStyle(fontSize: 14, color: AppColors.textDim)),
              const SizedBox(height: 6),
              Text('Rs. ${money(net)}',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final a in _accounts)
          ListTile(
            leading: RoundIcon(
              iconName: a.account.iconName,
              colorValue: a.account.colorValue,
              size: 40,
            ),
            title: Text(a.account.name),
            trailing: Text(
              money(a.balance),
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w500,
                color: a.balance < 0
                    ? const Color(0xFFF2555A)
                    : AppColors.text,
              ),
            ),
          ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountsScreen()),
            );
            _load();
          },
          icon: const Icon(Icons.tune, size: 18),
          label: const Text('Manage accounts'),
        ),
      ],
    );
  }

  Widget _card({required Widget child, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: child,
      ),
    );
  }

  Widget _stat(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13.5, color: AppColors.textDim)),
        const SizedBox(height: 4),
        Text(money(value),
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _budgetLine(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label :',
              style: const TextStyle(fontSize: 13.5, color: AppColors.textDim)),
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color ?? AppColors.text)),
        ],
      ),
    );
  }
}
