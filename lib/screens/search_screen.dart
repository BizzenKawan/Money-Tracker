import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/transaction.dart';
import '../services/db_helper.dart';
import '../theme.dart';
import '../utils/formatters.dart';
import '../utils/nepali_months.dart';
import '../widgets/common.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<MoneyTransaction> _results = [];
  Map<int, Category> _categories = {};
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    DBHelper.instance.getCategoryLookup().then((c) {
      if (mounted) setState(() => _categories = c);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String term) async {
    final trimmed = term.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
      });
      return;
    }
    final rows = await DBHelper.instance.searchTransactions(trimmed);
    if (!mounted) return;
    setState(() {
      _results = rows;
      _searched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search notes and categories',
            border: InputBorder.none,
            filled: false,
          ),
          onChanged: _search,
        ),
      ),
      body: !_searched
          ? const EmptyState(
              icon: Icons.search,
              message: 'Type to search your transactions',
            )
          : _results.isEmpty
              ? const EmptyState(
                  icon: Icons.search_off,
                  message: 'No matches found',
                )
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, i) {
                    final t = _results[i];
                    final cat =
                        t.categoryId == null ? null : _categories[t.categoryId];
                    return ListTile(
                      leading: RoundIcon(
                        iconName: cat?.iconName ?? 'currency_exchange',
                        colorValue: cat?.colorValue ?? 0xFF616161,
                        size: 38,
                      ),
                      title: Text(
                        t.note.isNotEmpty
                            ? t.note
                            : (cat?.name ?? 'Transfer'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${nepaliMonthsShort[t.bsMonth - 1]} ${t.bsDay}, ${t.bsYear}'
                        '${cat != null && t.note.isNotEmpty ? ' · ${cat.name}' : ''}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textDim),
                      ),
                      trailing: Text(
                        signedMoney(t.amount, t.type),
                        style: TextStyle(
                          fontSize: 15.5,
                          color: t.type == 'income'
                              ? AppColors.income
                              : AppColors.text,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
