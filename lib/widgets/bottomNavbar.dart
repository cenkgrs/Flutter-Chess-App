import 'package:chess_puzzle_app/game_board.dart';
import 'package:chess_puzzle_app/values/colors.dart';
import 'package:flutter/material.dart';
import 'package:chess_puzzle_app/screens/home_page_screen.dart';
import 'package:chess_puzzle_app/main.dart';

class BottomNavbar extends StatefulWidget {
  const BottomNavbar({Key? key}) : super(key: key);

  final index = 0;

  @override
  State<BottomNavbar> createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar> {
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    navigationAction(selectedIndex) {
      switch (selectedIndex) {
        // Home Page
        case 0:
          if (widget.index == 0) {
            break;
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => GameBoard()),
          );
          break;

        case 1:
          if (widget.index == 1) {
            break;
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => GameBoard()),
          );
          break;

        case 2:
          if (widget.index == 2) {
            break;
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => GameBoard()),
          );
          break;

        case 3:
          if (widget.index == 3) {
            break;
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => GameBoard()),
          );
          break;
        // Log Out
        case 4:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyApp()),
          );
          break;
        default:
          break;
      }
    }

    adminBottomNavbar() {
      return BottomAppBar(
          notchMargin: 5,
          color: themeColor,
          shape: const CircularNotchedRectangle(),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                padding: const EdgeInsets.only(left: 20),
                icon: const Icon(Icons.home, color: Colors.white),
                onPressed: () {
                  navigationAction(0);
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.search,
                  color: Colors.white,
                ),
                onPressed: () {
                  navigationAction(1);
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.settings,
                  color: Colors.white,
                ),
                onPressed: () {
                  navigationAction(3);
                },
              ),
              IconButton(
                padding: const EdgeInsets.only(right: 20),
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () {
                  navigationAction(4);
                },
              )
            ],
          ));
    }

    return adminBottomNavbar();
  }
}
