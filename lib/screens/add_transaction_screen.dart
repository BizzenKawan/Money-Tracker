import 'package:flutter/material.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart';
import 'package:nepali_utils/nepali_utils.dart';

import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/db_helper.dart';
import '../theme.dart';
import '../utils/nepali_months.dart';
import '../utils/sound.dart';
import '../widgets/calc_keypad.dart';
import '../widgets/common.dart';
import 'category_settings_screen.dart';

class AddTransactionScreen extends StatefulWidget {
  final MoneyTransaction? existing;

  /// Preselects the date, used when opening from the calendar so the entry
  /// lands on the day that was tapped.
  final NepaliDateTime? initialDate;

  const AddTransactionScreen({super.key, this.existing, this.initialDate});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  List<Category> _expenseCats = [];
  List<Category> _incomeCats = [];
  List<Account> _accounts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final initialTab = switch (widget.existing?.type) {
      'income' => 1,
      'transfer' => 2,
      _ => 0,
    };
    _tabs = TabController(length: 3, vsync: this, initialIndex: initialTab);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final db = DBHelper.instance;
    final e = await db.getCategories('expense');
    final i = await db.getCategories('income');
    final a = await db.getAccounts();
    if (!mounted) return;
    setState(() {
      _expenseCats = e;
      _incomeCats = i;
      _accounts = a;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit' : 'Add'),
        leading: TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel',
              style: TextStyle(color: AppColors.text, fontSize: 15)),
        ),
        leadingWidth: 80,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TabBar(
                controller: _tabs,
                indicator: BoxDecoration(
                  color: AppColors.text,
                  borderRadius: BorderRadius.circular(6),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.black,
                unselectedLabelColor: AppColors.text,
                tabs: const [
                  Tab(text: 'Expense'),
                  Tab(text: 'Income'),
                  Tab(text: 'Transfer'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _CategoryGrid(
                  categories: _expenseCats,
                  onPick: (c) => _openEntrySheet('expense', c),
                  onManage: _openCategorySettings,
                ),
                _CategoryGrid(
                  categories: _incomeCats,
                  onPick: (c) => _openEntrySheet('income', c),
                  onManage: _openCategorySettings,
                ),
                _TransferTab(
                  accounts: _accounts,
                  existing: widget.existing?.type == 'transfer'
                      ? widget.existing
                      : null,
                  initialDate: widget.initialDate,
                  onSaved: () => Navigator.pop(context, true),
                ),
              ],
            ),
    );
  }

  Future<void> _openCategorySettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CategorySettingsScreen()),
    );
    _load();
  }

  Future<void> _openEntrySheet(String type, Category category) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EntrySheet(
        type: type,
        category: category,
        accounts: _accounts,
        existing: widget.existing,
        initialDate: widget.initialDate,
      ),
    );
    if (saved == true && mounted) Navigator.pop(context, true);
  }
}

// ---------------------------------------------------------------- categories

class _CategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final ValueChanged<Category> onPick;
  final VoidCallback onManage;

  const _CategoryGrid({
    required this.categories,
    required this.onPick,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
      ),
      itemCount: categories.length + 1,
      itemBuilder: (context, i) {
        if (i == categories.length) {
          return _Tile(
            icon: Icons.settings,
            label: 'Settings',
            colorValue: 0xFF3A3A3A,
            onTap: onManage,
          );
        }
        final c = categories[i];
        return _Tile(
          iconName: c.iconName,
          label: c.name,
          colorValue: 0xFF2E2E2E,
          onTap: () => onPick(c),
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  final String? iconName;
  final IconData? icon;
  final String label;
  final int colorValue;
  final VoidCallback onTap;

  const _Tile({
    this.iconName,
    this.icon,
    required this.label,
    required this.colorValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        tapFeedback();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (iconName != null)
            RoundIcon(iconName: iconName!, colorValue: colorValue, size: 52)
          else
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Color(colorValue),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.text, size: 26),
            ),
          const SizedBox(height: 7),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- entry sheet

class _EntrySheet extends StatefulWidget {
  final String type;
  final Category category;
  final List<Account> accounts;
  final MoneyTransaction? existing;
  final NepaliDateTime? initialDate;

  const _EntrySheet({
    required this.type,
    required this.category,
    required this.accounts,
    this.existing,
    this.initialDate,
  });

  @override
  State<_EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends State<_EntrySheet> {
  final _note = TextEditingController();
  late NepaliDateTime _date;
  int? _accountId;
  double? _startingAmount;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    if (ex != null && ex.type == widget.type) {
      _startingAmount = ex.amount;
      _note.text = ex.note;
      _date = NepaliDateTime(ex.bsYear, ex.bsMonth, ex.bsDay);
      _accountId = ex.accountId;
    } else {
      _date = widget.initialDate ?? NepaliDateTime.now();
      _accountId = widget.accounts.isNotEmpty ? widget.accounts.first.id : null;
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final picked = await showNepaliDatePicker(
      context: context,
      initialDate: _date,
      firstDate: NepaliDateTime(2070),
      lastDate: NepaliDateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickAccount() async {
    FocusScope.of(context).unfocus();
    final picked = await showModalBottomSheet<int?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Accounts',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.surfaceHigh,
                child: Icon(Icons.block, size: 18, color: AppColors.textDim),
              ),
              title: const Text('Not associated with any account'),
              onTap: () => Navigator.pop(ctx, -1),
            ),
            for (final a in widget.accounts)
              ListTile(
                leading: RoundIcon(
                    iconName: a.iconName,
                    colorValue: a.colorValue,
                    size: 36),
                title: Text(a.name),
                onTap: () => Navigator.pop(ctx, a.id),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    setState(() => _accountId = picked == -1 ? null : picked);
  }

  /// Shows "Today" when the date is today, otherwise the BS date itself.
  String get _dateLabel {
    final now = NepaliDateTime.now();
    if (_date.year == now.year &&
        _date.month == now.month &&
        _date.day == now.day) {
      return 'Today';
    }
    return '${nepaliMonthsShort[_date.month - 1]} ${_date.day}';
  }

  Future<void> _save(double amount) async {
    final tx = MoneyTransaction(
      id: widget.existing?.id,
      type: widget.type,
      amount: amount,
      categoryId: widget.category.id,
      accountId: _accountId,
      note: _note.text.trim(),
      adDate: _date.toDateTime(),
      bsYear: _date.year,
      bsMonth: _date.month,
      bsDay: _date.day,
    );

    final db = DBHelper.instance;
    if (tx.id == null) {
      await db.insertTransaction(tx);
    } else {
      await db.updateTransaction(tx);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    Account? selected;
    for (final a in widget.accounts) {
      if (a.id == _accountId) selected = a;
    }

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  RoundIcon(
                    iconName: widget.category.iconName,
                    colorValue: widget.category.colorValue,
                    size: 38,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.category.name,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600)),
                  ),
                  InkWell(
                    onTap: _pickAccount,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selected == null
                                ? Icons.credit_card_off
                                : Icons.credit_card,
                            size: 16,
                            color: AppColors.textDim,
                          ),
                          const SizedBox(width: 5),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 90),
                            child: Text(
                              selected?.name ?? 'No account',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _note,
                decoration: const InputDecoration(
                  hintText: 'Note (optional)',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 4),
            CalcKeypad(
              initialValue: _startingAmount,
              dateLabel: _dateLabel,
              onDatePressed: _pickDate,
              onConfirm: _save,
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ transfer

class _TransferTab extends StatefulWidget {
  final List<Account> accounts;
  final MoneyTransaction? existing;
  final NepaliDateTime? initialDate;
  final VoidCallback onSaved;

  const _TransferTab({
    required this.accounts,
    required this.existing,
    required this.initialDate,
    required this.onSaved,
  });

  @override
  State<_TransferTab> createState() => _TransferTabState();
}

class _TransferTabState extends State<_TransferTab> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late NepaliDateTime _date;
  int? _from;
  int? _to;
  String? _error;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    if (ex != null) {
      _amount.text = ex.amount.toStringAsFixed(0);
      _note.text = ex.note;
      _date = NepaliDateTime(ex.bsYear, ex.bsMonth, ex.bsDay);
      _from = ex.accountId;
      _to = ex.toAccountId;
    } else {
      _date = widget.initialDate ?? NepaliDateTime.now();
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showNepaliDatePicker(
      context: context,
      initialDate: _date,
      firstDate: NepaliDateTime(2070),
      lastDate: NepaliDateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final value = double.tryParse(_amount.text.trim());
    if (value == null || value <= 0) {
      setState(() => _error = 'Enter an amount greater than zero');
      return;
    }
    if (_from == null || _to == null) {
      setState(() => _error = 'Pick both accounts');
      return;
    }
    if (_from == _to) {
      setState(() => _error = 'Pick two different accounts');
      return;
    }

    final tx = MoneyTransaction(
      id: widget.existing?.id,
      type: 'transfer',
      amount: value,
      accountId: _from,
      toAccountId: _to,
      note: _note.text.trim(),
      adDate: _date.toDateTime(),
      bsYear: _date.year,
      bsMonth: _date.month,
      bsDay: _date.day,
    );

    final db = DBHelper.instance;
    if (tx.id == null) {
      await db.insertTransaction(tx);
    } else {
      await db.updateTransaction(tx);
    }
    saveFeedback();
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.accounts.length < 2) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: EmptyState(
          icon: Icons.account_balance,
          message:
              'Transfers need at least two accounts.\nAdd them under Profile → Accounts.',
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
      children: [
        Row(
          children: [
            Expanded(child: _picker('From', _from, (v) => setState(() => _from = v))),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward),
            ),
            Expanded(child: _picker('To', _to, (v) => setState(() => _to = v))),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixText: 'Rs. ',
            hintText: '0',
            errorText: _error,
          ),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          decoration: const InputDecoration(hintText: 'Note (optional)'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickDate,
          icon: const Icon(Icons.calendar_today, size: 16),
          label: Text(
            '${nepaliMonthsShort[_date.month - 1]} ${_date.day}, ${_date.year}',
          ),
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text('Save',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _picker(String label, int? value, ValueChanged<int?> onChanged) {
    Account? acc;
    for (final a in widget.accounts) {
      if (a.id == value) {
        acc = a;
        break;
      }
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final picked = await showModalBottomSheet<int>(
          context: context,
          builder: (ctx) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Accounts',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                for (final a in widget.accounts)
                  ListTile(
                    leading: RoundIcon(
                        iconName: a.iconName,
                        colorValue: a.colorValue,
                        size: 36),
                    title: Text(a.name),
                    onTap: () => Navigator.pop(ctx, a.id),
                  ),
              ],
            ),
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        height: 118,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (acc == null)
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add, color: Colors.black),
              )
            else
              RoundIcon(
                  iconName: acc.iconName,
                  colorValue: acc.colorValue,
                  size: 46),
            const SizedBox(height: 8),
            Text(acc?.name ?? label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
