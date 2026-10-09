import 'package:flutter/material.dart';
import 'screens/home_menu_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ROK',
        theme: ThemeData(
            useMaterial3: true,
            colorScheme:
                ColorScheme.fromSeed(seedColor: const Color(0xff202120)),
            scaffoldBackgroundColor: const Color(0xfff5f3ee)),
        home: const HomeMenuScreen());
  }
}
