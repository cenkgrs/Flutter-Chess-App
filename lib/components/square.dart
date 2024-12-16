import 'package:chess_puzzle_app/components/piece.dart';
import 'package:chess_puzzle_app/values/colors.dart';
import 'package:flutter/material.dart';

class Square extends StatelessWidget {
  final bool isWhite;
  final ChessPiece? piece;
  final bool isSelected;
  final bool isValidMove;
  final void Function()? onTap;

  const Square(
      {super.key,
      required this.isWhite,
      required this.piece,
      required this.isSelected,
      required this.isValidMove,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color? squareColor;

    if (isSelected) {
      squareColor = selectedPieceColor;
    } else if (isValidMove) {
      squareColor = isWhite ? foregroundColor : backgroundColor;
    } else {
      squareColor = isWhite ? foregroundColor : backgroundColor;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
          color: squareColor,
          child: piece != null
              ? Image.asset(piece!.imagePath,
                  color: piece!.isWhite ? Colors.white : Colors.black)
              : (isValidMove
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: CircleAvatar(
                        backgroundColor: validMoveColor,
                      ),
                    )
                  : null)),
    );
  }
}
