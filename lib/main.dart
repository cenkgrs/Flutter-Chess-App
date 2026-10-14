import 'package:flutter/material.dart';

import 'backend/app_backend.dart';
import 'screens/home_menu_screen.dart';
import 'route_observer.dart';
import 'widgets/rok_style.dart';

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
        theme: rokTheme(),
        home: const HomeMenuScreen());
  }
}
