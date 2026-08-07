import 'package:flutter/material.dart';

import '../services/db_helper.dart';
import '../theme.dart';
import '../utils/sound.dart';

class HomePageSettingsScreen extends StatefulWidget {
  const HomePageSettingsScreen({super.key});

  @override
  State<HomePageSettingsScreen> createState() =>
      _HomePageSettingsScreenState();
}

class _HomePageSettingsScreenState extends State<HomePageSettingsScreen> {
  bool _hideBalance = false;
  bool _hideHomeTotals = false;
  bool _soundOn = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = DBHelper.instance;
    final hide = await db.getBool('hide_balance');
    final hideHome = await db.getBool('hide_home_totals');
    final sound = await db.getBool('sound_on', fallback: true);
    if (!mounted) return;
    setState(() {
      _hideBalance = hide;
      _hideHomeTotals = hideHome;
      _soundOn = sound;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home page settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  value: _hideBalance,
                  title: const Text('Hide balance'),
                  subtitle: const Text(
                    'Masks the totals on the history screen. Tap the eye icon '
                    'there to reveal them temporarily.',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textDim),
                  ),
                  onChanged: (v) async {
                    setState(() => _hideBalance = v);
                    await DBHelper.instance.setBool('hide_balance', v);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _hideHomeTotals,
                  title: const Text('Hide totals on home page'),
                  subtitle: const Text(
                    'Masks the monthly expense and income figures at the top '
                    'of the home screen.',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textDim),
                  ),
                  onChanged: (v) async {
                    setState(() => _hideHomeTotals = v);
                    await DBHelper.instance.setBool('hide_home_totals', v);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _soundOn,
                  title: const Text('Sound effects'),
                  subtitle: const Text(
                    'Plays a click on taps and a chime when a transaction is '
                    'saved. Works even if your phone\'s touch sounds are off.',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textDim),
                  ),
                  onChanged: (v) async {
                    setState(() => _soundOn = v);
                    Sound.setEnabled(v);
                    await DBHelper.instance.setBool('sound_on', v);
                    if (v) Sound.tap();
                  },
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(18, 22, 18, 0),
                  child: Text(
                    'These only affect what is shown on screen. Nothing is '
                    'deleted or hidden from your records.',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textDim),
                  ),
                ),
              ],
            ),
    );
  }
}
