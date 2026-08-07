import 'package:flutter/material.dart';

import '../models/category.dart';
import '../services/db_helper.dart';
import '../theme.dart';
import '../utils/color_palette.dart';
import '../utils/icon_catalog.dart';
import '../widgets/common.dart';
import '../utils/sound.dart';

class CategoryEditScreen extends StatefulWidget {
  final Category? existing;
  final String initialType;

  const CategoryEditScreen({
    super.key,
    this.existing,
    required this.initialType,
  });

  @override
  State<CategoryEditScreen> createState() => _CategoryEditScreenState();
}

class _CategoryEditScreenState extends State<CategoryEditScreen> {
  final _name = TextEditingController();
  late String _type;
  late int _color;
  late String _icon;
  String? _error;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _type = ex?.type ?? widget.initialType;
    _color = ex?.colorValue ?? kPalette[8];
    _icon = ex?.iconName ?? 'category';
    _name.text = ex?.name ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter a category name');
      return;
    }

    final db = DBHelper.instance;
    saveFeedback();
    if (widget.existing == null) {
      await db.insertCategory(Category(
        name: name,
        type: _type,
        iconName: _icon,
        colorValue: _color,
        isCustom: true,
      ));
    } else {
      await db.updateCategory(widget.existing!.copyWith(
        name: name,
        type: _type,
        iconName: _icon,
        colorValue: _color,
        isCustom: true,
      ));
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit category' : 'Add category'),
        leading: TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel',
              style: TextStyle(color: AppColors.text, fontSize: 15)),
        ),
        leadingWidth: 80,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.accent),
            onPressed: _save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        children: [
          // Expense / income choice — locked while editing so existing
          // transactions can't silently flip sign.
          if (!editing)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _typeRadio('expense', 'Expense'),
                const SizedBox(width: 24),
                _typeRadio('income', 'Income'),
              ],
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              RoundIcon(iconName: _icon, colorValue: _color, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _name,
                  decoration: InputDecoration(
                    hintText: 'Please enter the category name',
                    errorText: _error,
                  ),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              for (final c in kPalette)
                GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                    ),
                    child: _color == c
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 20)
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 26),
          for (final entry in kIconGroups.entries) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 6),
              child: Text(
                entry.key,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textDim,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            GridView.count(
              crossAxisCount: 6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                for (final name in entry.value)
                  GestureDetector(
                    onTap: () => setState(() => _icon = name),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _icon == name
                            ? Color(_color)
                            : AppColors.surfaceHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        iconFor(name),
                        size: 22,
                        color: _icon == name
                            ? Colors.white
                            : AppColors.textDim,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Widget _typeRadio(String value, String label) {
    final selected = _type == value;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? AppColors.accent : AppColors.textDim,
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}
