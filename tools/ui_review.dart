// Local visual QA only; not the production entry point.
import 'package:flutter/material.dart';
import 'package:chess_puzzle_app/screens/auth_screen.dart';
import 'package:chess_puzzle_app/widgets/rok_style.dart';

void main() => runApp(MaterialApp(theme: rokTheme(), home: const _Preview()));

class _Preview extends StatelessWidget {
  const _Preview();
  @override
  Widget build(BuildContext context) => Stack(children: [
        const AuthScreen(),
        Positioned(
            right: 16,
            bottom: 32,
            child: FloatingActionButton(
                onPressed: () => showDialog<void>(
                    context: context,
                    builder: (ctx) => RokResultDialog(
                          title: const Text('Kaybettin'),
                          icon: const Icon(Icons.flag_outlined),
                          content: const Text('Şah mat · Bilgisayar kazandı'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Tahtayı incele')),
                            TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Motor analizi')),
                            FilledButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Menüye dön')),
                          ],
                        )),
                child: const Icon(Icons.preview))),
      ]);
}
