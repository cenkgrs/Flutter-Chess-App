import 'package:flutter/material.dart';
import 'prototype/play_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Satranç Atölyesi',
        theme: ThemeData(
            useMaterial3: true,
            colorScheme:
                ColorScheme.fromSeed(seedColor: const Color(0xff326859)),
            scaffoldBackgroundColor: const Color(0xfff5f3ee)),
        home: const PlayScreen());
  }
}
