import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/sound.dart';
import 'add_transaction_screen.dart';
import 'charts_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  /// Bumping this key forces the visible tab to rebuild and refetch after a
  /// transaction is added or edited elsewhere.
  int _refreshToken = 0;

  void _refresh() => setState(() => _refreshToken++);

  Future<void> _openAdd() async {
    tapFeedback();
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
    if (saved == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(key: ValueKey('home$_refreshToken'), onChanged: _refresh),
      ChartsScreen(key: ValueKey('charts$_refreshToken')),
      ReportsScreen(key: ValueKey('reports$_refreshToken')),
      ProfileScreen(key: ValueKey('profile$_refreshToken'), onChanged: _refresh),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppColors.surface,
        height: 62,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            _NavItem(
              icon: Icons.list_alt,
              label: 'Home',
              selected: _index == 0,
              onTap: () => setState(() => _index = 0),
            ),
            _NavItem(
              icon: Icons.pie_chart_outline,
              label: 'Charts',
              selected: _index == 1,
              onTap: () => setState(() => _index = 1),
            ),
            const SizedBox(width: 64),
            _NavItem(
              icon: Icons.receipt_long,
              label: 'Reports',
              selected: _index == 2,
              onTap: () => setState(() => _index = 2),
            ),
            _NavItem(
              icon: Icons.person_outline,
              label: 'Profile',
              selected: _index == 3,
              onTap: () => setState(() => _index = 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.textDim;
    return Expanded(
      child: InkWell(
        onTap: () {
          tapFeedback();
          onTap();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
