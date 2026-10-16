import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'backend/app_backend.dart';
import 'screens/home_menu_screen.dart';
import 'route_observer.dart';
import 'widgets/rok_style.dart';
import 'ads/match_ads.dart';
import 'l10n/app_language.dart';
import 'legal/open_source_compliance.dart';
import 'audio/game_sounds.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  verifyReleaseSourceIsPinned();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      ['ROK', 'Stockfish 18 / Flutter stockfish 1.8.1'],
      await rootBundle.loadString('third_party/stockfish/LICENSE'),
    );
  });
  await AppBackend.initialize();
  await AppLanguage.instance.load();
  await GameSounds.instance.load();
  runApp(const MyApp());
  WidgetsBinding.instance
      .addPostFrameCallback((_) => MatchAds.instance.initialize());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: AppLanguage.instance,
        builder: (_, __) => MaterialApp(
            locale: AppLanguage.instance.locale,
            supportedLocales: AppLanguage.supported,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            localeResolutionCallback: (device, supported) => supported
                .firstWhere((l) => l.languageCode == device?.languageCode,
                    orElse: () => const Locale('en')),
            debugShowCheckedModeBanner: false,
            title: 'ROK',
            navigatorObservers: [appRouteObserver],
            theme: rokTheme(),
            home: const HomeMenuScreen()));
  }
}
