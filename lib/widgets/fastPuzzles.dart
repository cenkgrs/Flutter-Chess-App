import 'package:chess_puzzle_app/game_board.dart';
import 'package:flutter/material.dart';

class FastPuzzles extends StatelessWidget {
  const FastPuzzles({super.key});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Center(
        child: Padding(
      padding: const EdgeInsets.all(10),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GameBoard()),
          );
          ;
        },
        child: Container(
          width: width * 0.9,
          height: 125,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: GridView.builder(
            itemCount: 9,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, childAspectRatio: 3),
            itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  children: [
                    Text('Puzzle'),
                  ],
                )),
          ),
        ),
      ),
    ));
  }
}
