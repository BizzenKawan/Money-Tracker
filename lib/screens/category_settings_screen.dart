import 'package:flutter/material.dart';

import '../models/category.dart';
import '../services/db_helper.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'category_edit_screen.dart';

class CategorySettingsScreen extends StatefulWidget {
  const CategorySettingsScreen({super.key});

  @override
  State<CategorySettingsScreen> createState() => _CategorySettingsScreenState();
}

class _CategorySettingsScreenState extends State<CategorySettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  List<Category> _expense = [];
  List<Category> _income = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() => setState(() {}));
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
    if (!mounted) return;
    setState(() {
      _expense = e;
      _income = i;
      _loading = false;
    });
  }

  String get _currentType => _tabs.index == 0 ? 'expense' : 'income';

  Future<void> _openEditor({Category? existing}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryEditScreen(
          existing: existing,
          initialType: _currentType,
        ),
      ),
    );
    if (changed == true) _load();
  }

  Future<void> _delete(Category c) async {
    final used = await DBHelper.instance.categoryUsageCount(c.id!);
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete "${c.name}"?'),
        content: Text(
          used == 0
              ? 'This category is not used by any transaction.'
              : '$used transaction${used == 1 ? '' : 's'} use this category. '
                  'They will be kept but shown as uncategorised.',
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
      await DBHelper.instance.deleteCategory(c.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category settings'),
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
                tabs: const [Tab(text: 'Expense'), Tab(text: 'Income')],
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
                _list(_expense, 'expense'),
                _list(_income, 'income'),
              ],
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
            label: const Text('Add category',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  Widget _list(List<Category> items, String type) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.category,
        message: 'No categories yet',
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: items.length,
      onReorder: (oldIndex, newIndex) async {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final moved = items.removeAt(oldIndex);
          items.insert(newIndex, moved);
        });
        await DBHelper.instance.reorderCategories(items);
      },
      itemBuilder: (context, i) {
        final c = items[i];
        return ListTile(
          key: ValueKey('cat${c.id}'),
          leading: RoundIcon(
            iconName: c.iconName,
            colorValue: c.colorValue,
            size: 38,
          ),
          title: Text(c.name),
          subtitle: c.isCustom
              ? const Text('Customized',
                  style: TextStyle(fontSize: 11, color: AppColors.textDim))
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.textDim,
                onPressed: () => _delete(c),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: AppColors.textDim,
                onPressed: () => _openEditor(existing: c),
              ),
              ReorderableDragStartListener(
                index: i,
                child: const Padding(
                  padding: EdgeInsets.only(left: 4, right: 4),
                  child: Icon(Icons.drag_handle, color: AppColors.textDim),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
