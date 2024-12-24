import 'package:chess_puzzle_app/screens/home_page_screen.dart';
import 'package:flutter/material.dart';

import 'game_board.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/game': (context) => const GameBoard()
        });
  }
}
