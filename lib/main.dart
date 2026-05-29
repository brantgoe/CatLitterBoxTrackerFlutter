import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/database.dart';
import 'data/repository.dart';
import 'network/network_preferences.dart';
import 'network/sync_engine.dart';
import 'state/providers.dart';
import 'ui/main_screen.dart';
import 'ui/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase();
  final repository = Repository(db, prefs);
  final networkPrefs = NetworkPreferences(prefs);
  final engine = SyncEngine(db: db, repository: repository, prefs: networkPrefs);
  await engine.start();

  runApp(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(db),
      repositoryProvider.overrideWithValue(repository),
      networkPreferencesProvider.overrideWithValue(networkPrefs),
      syncEngineProvider.overrideWithValue(engine),
    ],
    child: const CatLitterBoxApp(),
  ));
}

class CatLitterBoxApp extends StatelessWidget {
  const CatLitterBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Litter Box Tracker',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const MainScreen(),
    );
  }
}
