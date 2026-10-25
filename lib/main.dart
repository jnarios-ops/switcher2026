import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'screens/portal_screen.dart';
import 'screens/update_gate_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0B1220),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  runApp(const SwitcherGpsApp());
}

class SwitcherGpsApp extends StatelessWidget {
  const SwitcherGpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Switcher GPS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: SwColors.accent,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: SwColors.bg,
        useMaterial3: true,
      ),
      home: const UpdateGateScreen(child: PortalScreen()),
    );
  }
}
