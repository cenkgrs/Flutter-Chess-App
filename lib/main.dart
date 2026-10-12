import 'package:flutter/material.dart';

import 'backend/app_backend.dart';
import 'screens/home_menu_screen.dart';
import 'route_observer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppBackend.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ROK',
        navigatorObservers: [appRouteObserver],
        theme: ThemeData(
            useMaterial3: true,
            colorScheme:
                ColorScheme.fromSeed(seedColor: const Color(0xff202120)),
            scaffoldBackgroundColor: const Color(0xfff5f3ee)),
        home: const HomeMenuScreen());
  }
}
