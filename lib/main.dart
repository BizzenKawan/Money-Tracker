import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/db_helper.dart';
import 'screens/root_shell.dart';
import 'theme.dart';
import 'utils/sound.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  // Respect the saved sound on/off preference from the very first frame.
  Sound.setEnabled(await DBHelper.instance.getBool('sound_on', fallback: true));
  runApp(const MoneyTrackerApp());
}

class MoneyTrackerApp extends StatelessWidget {
  const MoneyTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money Tracker',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const RootShell(),
    );
  }
}
