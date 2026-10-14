import '../widgets/rok_style.dart';
import 'package:flutter/material.dart';
import '../backend/app_backend.dart';

class PuzzleLeaderboardScreen extends StatefulWidget {
  const PuzzleLeaderboardScreen({super.key, this.loader});
  final Future<Map<String, dynamic>> Function()? loader;

  @override
  State<PuzzleLeaderboardScreen> createState() =>
      _PuzzleLeaderboardScreenState();
}

class _PuzzleLeaderboardScreenState extends State<PuzzleLeaderboardScreen> {
  late Future<Map<String, dynamic>> _data;
  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<Map<String, dynamic>> _load() async => widget.loader != null
      ? await widget.loader!()
      : Map<String, dynamic>.from(
          await AppBackend.client.rpc('puzzle_leaderboard') as Map);

  Future<void> _refresh() async {
    setState(() {
      _data = _load();
    });
    try {
      await _data;
    } catch (_) {/* FutureBuilder displays the error. */}
  }

  Widget _entry(Map row, {bool own = false}) => Card(
        color: own ? const Color(0xff454645) : const Color(0xff2b2c2b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ListTile(
          textColor: const Color(0xfff3eee7),
          leading: Text('#${row['place']}',
              style: const TextStyle(fontSize: 20, color: Color(0xfff3eee7))),
          title: Text('${row['username']}${own ? ' · Sen' : ''}'),
          subtitle: Text("Seviye ${row['rating']} · ${row['played']} bulmaca",
              style: const TextStyle(color: Color(0xffb9aea5))),
          trailing: Text("${row['points']}\nPUAN",
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: Color(0xfff3eee7))),
        ),
      );

  @override
  Widget build(BuildContext context) => RokScaffold(
        backgroundColor: const Color(0xff202120),
        appBar: AppBar(
            title: const Text('Bulmaca sıralaması'),
            backgroundColor: const Color(0xff202120),
            foregroundColor: const Color(0xfff3eee7),
            actions: [
              IconButton(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Yenile')
            ]),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _data,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xfff3eee7)));
            }
            if (snapshot.hasError) {
              return Center(
                  child: TextButton(
                      onPressed: _refresh,
                      child: const Text('Sıralama yüklenemedi. Tekrar dene',
                          style: TextStyle(color: Color(0xfff3eee7)))));
            }
            final rows = snapshot.data!['leaders'] as List;
            final me = snapshot.data!['me'] as Map?;
            return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text('TÜM ZAMANLAR · İLK 100',
                        style: TextStyle(
                            color: Color(0xffb9aea5), letterSpacing: 1.5)),
                    const SizedBox(height: 16),
                    if (me != null)
                      _entry(me, own: true)
                    else
                      const Text('İlk bulmacanı tamamla, sıralamaya katıl.',
                          style: TextStyle(color: Color(0xfff3eee7))),
                    const Divider(height: 32, color: Color(0xff454645)),
                    if (rows.isEmpty)
                      const Text('Henüz sıralamada oyuncu yok.',
                          style: TextStyle(color: Color(0xfff3eee7))),
                    for (final row in rows) _entry(row as Map),
                  ],
                ));
          },
        ),
      );
}
