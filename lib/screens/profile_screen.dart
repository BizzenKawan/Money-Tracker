import 'package:flutter/material.dart';
import 'package:nepali_utils/nepali_utils.dart';

import '../services/db_helper.dart';
import '../theme.dart';
import '../utils/nepali_months.dart';
import 'accounts_screen.dart';
import 'category_settings_screen.dart';
import 'home_page_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback onChanged;

  const ProfileScreen({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final today = NepaliDateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 90),
        children: [
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.accent,
                  child: Icon(Icons.person, color: Colors.black),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Today',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textDim)),
                    const SizedBox(height: 2),
                    Text(
                      '${monthName(today.month)} ${today.day}, ${today.year} B.S.',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _tile(
            context,
            icon: Icons.category_outlined,
            title: 'Category settings',
            subtitle: 'Add, edit, reorder and colour your categories',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CategorySettingsScreen()),
              );
              onChanged();
            },
          ),
          _tile(
            context,
            icon: Icons.account_balance_wallet_outlined,
            title: 'Accounts',
            subtitle: 'Manage your bank accounts, cash and wallets',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccountsScreen()),
              );
              onChanged();
            },
          ),
          _tile(
            context,
            icon: Icons.visibility_off_outlined,
            title: 'Home page settings',
            subtitle: 'Hide balances and totals from view',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const HomePageSettingsScreen()),
              );
              onChanged();
            },
          ),
          const Divider(height: 28),
          _tile(
            context,
            icon: Icons.delete_forever_outlined,
            title: 'Erase all transactions',
            subtitle: 'Keeps your categories and accounts',
            onTap: () => _confirmErase(context),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 22, 18, 0),
            child: Text(
              'All data is stored only on this phone. Nothing is uploaded '
              'anywhere, and the app works fully offline.',
              style: TextStyle(fontSize: 12, color: AppColors.textDim),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.text),
      title: Text(title),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textDim),
      onTap: onTap,
    );
  }

  Future<void> _confirmErase(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Erase all transactions?'),
        content: const Text(
          'Every transaction and budget will be permanently deleted. '
          'Your categories and accounts are kept. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Erase'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DBHelper.instance.eraseAllData();
      onChanged();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All transactions erased')),
        );
      }
    }
  }
}
