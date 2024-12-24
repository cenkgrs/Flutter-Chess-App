import 'package:chess_puzzle_app/game_board.dart';
import 'package:chess_puzzle_app/values/colors.dart';
import 'package:chess_puzzle_app/widgets/bottomNavbar.dart';
import 'package:chess_puzzle_app/widgets/fastPuzzles.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'Chess Puzzle',
      home: Scaffold(
          floatingActionButton: FloatingActionButton(
              backgroundColor: themeSecondaryColor,
              heroTag: UniqueKey(),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GameBoard()),
                );
              },
              child: const Icon(Icons.person_search_sharp)),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          appBar: AppBar(
              backgroundColor: themeColor, title: const Text('Chess Puzzle')),
          body: ListView(
            children: const <Widget>[FastPuzzles()],
          ),
          bottomNavigationBar: const BottomNavbar()));
}
