import 'package:flutter/material.dart';

import '../models/account.dart';
import '../services/db_helper.dart';
import '../theme.dart';
import '../utils/color_palette.dart';
import '../utils/formatters.dart';
import '../utils/icon_catalog.dart';
import '../widgets/common.dart';
import '../utils/sound.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  List<({Account account, double balance})> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = DBHelper.instance;
    final accounts = await db.getAccounts();
    final result = <({Account account, double balance})>[];
    for (final a in accounts) {
      result.add((account: a, balance: await db.accountBalance(a.id!)));
    }
    if (!mounted) return;
    setState(() {
      _items = result;
      _loading = false;
    });
  }

  Future<void> _openEditor({Account? existing}) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AccountEditor(existing: existing),
    );
    if (changed == true) _load();
  }

  Future<void> _delete(Account a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete "${a.name}"?'),
        content: const Text(
          'Transactions linked to this account are kept, but will no longer '
          'belong to any account.',
        ),
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
    if (confirmed == true) {
      await DBHelper.instance.deleteAccount(a.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const EmptyState(
                  icon: Icons.account_balance_wallet,
                  message: 'No accounts yet',
                )
              : ReorderableListView.builder(
                  itemCount: _items.length,
                  onReorder: (oldIndex, newIndex) async {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final moved = _items.removeAt(oldIndex);
                      _items.insert(newIndex, moved);
                    });
                    await DBHelper.instance
                        .reorderAccounts(_items.map((e) => e.account).toList());
                  },
                  itemBuilder: (context, i) {
                    final item = _items[i];
                    return ListTile(
                      key: ValueKey('acc${item.account.id}'),
                      onTap: () => _openEditor(existing: item.account),
                      leading: RoundIcon(
                        iconName: item.account.iconName,
                        colorValue: item.account.colorValue,
                        size: 40,
                      ),
                      title: Text(item.account.name),
                      subtitle: Text(
                        'Balance: ${money(item.balance)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textDim),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            color: AppColors.textDim,
                            onPressed: () => _delete(item.account),
                          ),
                          ReorderableDragStartListener(
                            index: i,
                            child: const Icon(Icons.drag_handle,
                                color: AppColors.textDim),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: () => _openEditor(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add account',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

class _AccountEditor extends StatefulWidget {
  final Account? existing;

  const _AccountEditor({this.existing});

  @override
  State<_AccountEditor> createState() => _AccountEditorState();
}

class _AccountEditorState extends State<_AccountEditor> {
  final _name = TextEditingController();
  final _opening = TextEditingController();
  late int _color;
  late String _icon;
  String? _error;

  static const _accountIcons = [
    'wallet',
    'account_balance',
    'account_balance_wallet',
    'savings',
    'credit_card',
    'payments',
    'trending_up',
    'attach_money',
    'monetization_on',
    'currency_exchange',
    'paid',
    'business_center',
  ];

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _color = ex?.colorValue ?? kPalette[5];
    _icon = ex?.iconName ?? 'wallet';
    _name.text = ex?.name ?? '';
    _opening.text = ex == null ? '' : ex.openingBalance.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter an account name');
      return;
    }
    final opening = double.tryParse(_opening.text.trim()) ?? 0;

    saveFeedback();
    final db = DBHelper.instance;
    if (widget.existing == null) {
      await db.insertAccount(Account(
        name: name,
        iconName: _icon,
        colorValue: _color,
        openingBalance: opening,
      ));
    } else {
      await db.updateAccount(widget.existing!.copyWith(
        name: name,
        iconName: _icon,
        colorValue: _color,
        openingBalance: opening,
      ));
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existing == null ? 'Add account' : 'Edit account',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  RoundIcon(iconName: _icon, colorValue: _color, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _name,
                      decoration: InputDecoration(
                        hintText: 'Account name',
                        errorText: _error,
                      ),
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _opening,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Opening balance',
                  prefixText: 'Rs. ',
                  hintText: '0',
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final c in kPalette)
                    GestureDetector(
                      onTap: () => setState(() => _color = c),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                        ),
                        child: _color == c
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 17)
                            : null,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final name in _accountIcons)
                    GestureDetector(
                      onTap: () => setState(() => _icon = name),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _icon == name
                              ? Color(_color)
                              : AppColors.surfaceHigh,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          iconFor(name),
                          size: 21,
                          color: _icon == name
                              ? Colors.white
                              : AppColors.textDim,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Save',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
