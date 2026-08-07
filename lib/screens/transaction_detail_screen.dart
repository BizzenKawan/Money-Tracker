import 'package:flutter/material.dart';

import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/db_helper.dart';
import '../theme.dart';
import '../utils/formatters.dart';
import '../utils/nepali_months.dart';
import '../widgets/common.dart';
import 'add_transaction_screen.dart';

/// What happened on this screen, so the caller knows whether to refresh.
enum DetailResult { none, edited, deleted }

class TransactionDetailScreen extends StatefulWidget {
  final MoneyTransaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late MoneyTransaction _tx = widget.transaction;

  Category? _category;
  Account? _account;
  Account? _toAccount;
  bool _loading = true;
  bool _edited = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = DBHelper.instance;
    final cats = await db.getCategoryLookup();
    final accounts = await db.getAccounts();

    Account? find(int? id) {
      if (id == null) return null;
      for (final a in accounts) {
        if (a.id == id) return a;
      }
      return null;
    }

    if (!mounted) return;
    setState(() {
      _category = _tx.categoryId == null ? null : cats[_tx.categoryId];
      _account = find(_tx.accountId);
      _toAccount = find(_tx.toAccountId);
      _loading = false;
    });
  }

  Future<void> _edit() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(existing: _tx),
      ),
    );
    if (saved != true) return;

    // Pull the updated row back so this screen shows the new values.
    final rows =
        await DBHelper.instance.transactionsForMonth(_tx.bsYear, _tx.bsMonth);
    MoneyTransaction? updated;
    for (final t in rows) {
      if (t.id == _tx.id) updated = t;
    }

    if (!mounted) return;
    if (updated == null) {
      // The edit moved it to another month, so there is nothing left to show.
      Navigator.pop(context, DetailResult.edited);
      return;
    }
    setState(() {
      _tx = updated!;
      _edited = true;
    });
    _load();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete this transaction?'),
        content: const Text('This cannot be undone.'),
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
    );

    if (confirmed != true) return;
    await DBHelper.instance.deleteTransaction(_tx.id!);
    if (mounted) Navigator.pop(context, DetailResult.deleted);
  }

  String get _typeLabel => switch (_tx.type) {
        'income' => 'Income',
        'expense' => 'Expense',
        _ => 'Transfer',
      };

  @override
  Widget build(BuildContext context) {
    final isTransfer = _tx.type == 'transfer';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.pop(
              context, _edited ? DetailResult.edited : DetailResult.none);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(
                context, _edited ? DetailResult.edited : DetailResult.none),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                children: [
                  Center(
                    child: Column(
                      children: [
                        RoundIcon(
                          iconName: isTransfer
                              ? 'currency_exchange'
                              : (_category?.iconName ?? 'category'),
                          colorValue: isTransfer
                              ? 0xFF616161
                              : (_category?.colorValue ?? 0xFF616161),
                          size: 58,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isTransfer
                              ? 'Transfer'
                              : (_category?.name ?? 'Uncategorised'),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 34),
                  _field('Type', _typeLabel),
                  _field('Amount', money(_tx.amount)),
                  _field(
                    'Date',
                    '${monthName(_tx.bsMonth)} ${_tx.bsDay}, ${_tx.bsYear} B.S.',
                    secondary: '${weekdayName(_tx.adDate)}  ·  '
                        '${_tx.adDate.year}-'
                        '${_tx.adDate.month.toString().padLeft(2, '0')}-'
                        '${_tx.adDate.day.toString().padLeft(2, '0')} A.D.',
                  ),
                  if (isTransfer)
                    _field(
                      'Accounts',
                      '${_account?.name ?? 'Unassigned'} → '
                          '${_toAccount?.name ?? 'Unassigned'}',
                    )
                  else
                    _field('Account', _account?.name ?? 'No account'),
                  if (_tx.note.isNotEmpty) _field('Note', _tx.note),
                ],
              ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _edit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('Edit',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _delete,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('Delete',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, String value, {String? secondary}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 15, color: AppColors.textDim)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 16)),
                if (secondary != null) ...[
                  const SizedBox(height: 3),
                  Text(secondary,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textDim)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
