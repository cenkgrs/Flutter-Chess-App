import 'package:chess_puzzle_app/l10n/app_language.dart';
import 'package:chess_puzzle_app/main.dart';
import 'package:chess_puzzle_app/screens/daily_puzzle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _start = '6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1';
const _mate = 'R5k1/5ppp/8/8/8/8/8/6K1 b - - 1 1';

Map<String, dynamic> _active() => {
      'attempt_id': 'today',
      'day': '2026-10-17',
      'fen': _start,
      'difficulty': 900,
      'theme': 'mate_in_1',
      'started_at': DateTime.now().toUtc().toIso8601String(),
      'step': 0,
      'mistakes': 0,
      'helped': false,
      'status': 'active',
      'awarded_points': 0,
      'points': 120,
      'solution': null,
      'current_streak': 2,
      'best_streak': 4,
    };

Future<void> _tapSquare(WidgetTester tester, String square) async {
  final board = tester.getRect(find.byType(GridView));
  final size = board.width / 8;
  final file = 'abcdefgh'.indexOf(square[0]);
  final rank = int.parse(square[1]);
  await tester.tapAt(board.topLeft +
      Offset(file * size + size / 2, (8 - rank) * size + size / 2));
  await tester.pump();
}

void main() {
  tearDown(() => AppLanguage.instance.locale = const Locale('tr'));

  testWidgets('daily puzzle requires login without exposing a board',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DailyPuzzleScreen()));
    expect(find.text('Günlük bulmaca için giriş yap'), findsOneWidget);
    expect(find.byType(GridView), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('home menu offers the daily puzzle to guests', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.scrollUntilVisible(find.text('Günlük bulmaca'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Her gün yeni bulmaca · Seri kur'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('menu entry shows today and the streak in every language',
      (tester) async {
    Future<Map<String, dynamic>> request(
            String name, Map<String, dynamic> params) async =>
        {
          'day': '2026-10-17',
          'status': 'solved',
          'solved': true,
          'awarded_points': 48,
          'current_streak': 5,
          'best_streak': 7,
        };
    Widget entry() => MaterialApp(
        home: Scaffold(
            backgroundColor: Colors.black,
            body: DailyPuzzleMenuEntry(signedIn: true, request: request)));

    await tester.pumpWidget(entry());
    await tester.pumpAndSettle();
    expect(find.text('Bugün çözüldü · Seri: 5 gün'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.byIcon(Icons.event_available_outlined), findsOneWidget);

    for (final (code, title, status) in [
      ('en', 'Daily puzzle', 'Solved today · Streak: 5 days'),
      ('de', 'Tagesaufgabe', 'Heute gelöst · Serie: 5 Tage'),
      ('ru', 'Задача дня', 'Решено сегодня · Серия: 5 дн.'),
    ]) {
      AppLanguage.instance.locale = Locale(code);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(entry());
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget, reason: code);
      expect(find.text(status), findsOneWidget, reason: code);
    }
  });

  testWidgets('unsolved day without a streak hides the streak badge',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: DailyPuzzleMenuEntry(
                signedIn: true,
                request: (name, params) async => {
                      'status': 'none',
                      'solved': false,
                      'current_streak': 0,
                      'best_streak': 3,
                    }))));
    await tester.pumpAndSettle();
    expect(find.text('Bugün çözülmedi · Seri: 0 gün'), findsOneWidget);
    expect(find.byIcon(Icons.local_fire_department_rounded), findsNothing);
  });

  testWidgets('solving sends only the move and shows the server streak',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final calls = <(String, Map<String, dynamic>)>[];

    await tester.pumpWidget(
        MaterialApp(home: DailyPuzzleScreen(request: (name, params) async {
      calls.add((name, params));
      if (name == 'start_daily_puzzle') return _active();
      return {
        'status': 'solved',
        'correct': true,
        'reply': null,
        'fen': _mate,
        'step': 1,
        'points': 168,
        'awarded_points': 48,
        'solution': null,
        'current_streak': 3,
        'best_streak': 4,
      };
    })));
    await tester.pumpAndSettle();
    expect(find.text('Seri: 2 gün'), findsOneWidget);
    expect(find.text('En uzun seri: 4 gün'), findsOneWidget);
    expect(find.text('Beyaz oynar · Matı bul'), findsOneWidget);

    await _tapSquare(tester, 'a1');
    await _tapSquare(tester, 'a8');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(calls.map((call) => call.$1),
        ['start_daily_puzzle', 'daily_puzzle_action']);
    expect(calls.last.$2, {
      'p_attempt_id': 'today',
      'p_action': 'move',
      'p_move': 'a1a8',
      'p_step': 0,
    });
    expect(find.text('Bugünün bulmacası çözüldü!'), findsOneWidget);
    expect(find.text('+48 puan'), findsOneWidget);
    await tester.tap(find.text('Kapat'));
    await tester.pumpAndSettle();
    expect(find.text('Seri: 3 gün'), findsOneWidget);
    expect(find.text('Çözüldü! +48 puan'), findsOneWidget);
    expect(find.text('İpucu'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('revealing asks first because it ends the day', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final actions = <String>[];

    await tester.pumpWidget(
        MaterialApp(home: DailyPuzzleScreen(request: (name, params) async {
      if (name == 'start_daily_puzzle') return _active();
      actions.add(params['p_action'] as String);
      return {
        'status': 'revealed',
        'correct': true,
        'step': 0,
        'points': 120,
        'awarded_points': 0,
        'solution': ['a1a8'],
        'initial_fen': _start,
        'current_streak': 0,
        'best_streak': 4,
      };
    })));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Çözümü göster'));
    await tester.tap(find.text('Çözümü göster'));
    await tester.pumpAndSettle();
    expect(find.text('Çözüm gösterilsin mi?'), findsOneWidget);
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(actions, isEmpty);

    await tester.tap(find.text('Çözümü göster'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Göster'));
    await tester.pumpAndSettle();
    expect(actions, ['reveal']);
    expect(find.text('Çözüm: Ra8# · Puan verilmedi'), findsOneWidget);
    expect(find.text('Seri: 0 gün'), findsOneWidget);
    expect(find.text('Yarın yeni bulmaca seni bekliyor.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
