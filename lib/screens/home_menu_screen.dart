import '../l10n/app_language.dart';
import '../widgets/rok_style.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend/app_backend.dart';
import '../backend/auth_repository.dart';
import '../backend/game_repository.dart';
import '../online/time_control.dart';
import '../prototype/play_screen.dart';
import 'auth_screen.dart';
import 'chess_leaderboard_screen.dart';
import 'daily_puzzle_screen.dart';
import 'friend_room_screen.dart';
import 'matchmaking_screen.dart';
import 'online_game_screen.dart';
import 'friends_screen.dart';
import 'profile_screen.dart';
import 'subscription_screen.dart';
import 'puzzle_screen.dart';
import 'puzzle_duel_screen.dart';
import '../route_observer.dart';

class HomeMenuScreen extends StatefulWidget {
  const HomeMenuScreen({super.key});

  static const bone = Color(0xfff3eee7);
  static const mutedBone = Color(0xffb9aea5);
  static const graphite = Color(0xff202120);
  static const ink = Color(0xff211712);
  static const divider = Color(0x66d8cec5);

  @override
  State<HomeMenuScreen> createState() => _HomeMenuScreenState();
}

class _HomeMenuScreenState extends State<HomeMenuScreen>
    with RouteAware, WidgetsBindingObserver {
  static const bone = HomeMenuScreen.bone;
  static const divider = HomeMenuScreen.divider;
  String? _activeGameId;
  bool _checkingActiveGame = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkActiveGame();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkActiveGame();
  }

  Future<void> _checkActiveGame() async {
    if (_checkingActiveGame || AppBackend.currentUser == null) return;
    _checkingActiveGame = true;
    try {
      final id = await GameRepository().findActiveGame();
      if (mounted) setState(() => _activeGameId = id);
    } catch (_) {
      // Keep the menu usable while offline; the next resume retries.
    } finally {
      _checkingActiveGame = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) appRouteObserver.subscribe(this, route);
  }

  @override
  void didPopNext() {
    if (mounted) {
      setState(() {});
      _checkActiveGame();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AppBackend.isConfigured) return _menu(context, null);
    return StreamBuilder<AuthState>(
      stream: AuthRepository().changes,
      initialData: AuthState(AuthChangeEvent.initialSession,
          AppBackend.client.auth.currentSession),
      builder: (context, snapshot) =>
          _menu(context, snapshot.data?.session?.user),
    );
  }

  Widget _menu(BuildContext context, User? user) => Scaffold(
        backgroundColor: const Color(0xff32180d),
        drawer: _drawer(context, user),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('lib/images/wood/background.png'),
              fit: BoxFit.cover,
              colorFilter:
                  ColorFilter.mode(Color(0x30000000), BlendMode.darken),
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
                    child: _header(context),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(22, 52, 22, 28),
                            child: Column(
                              children: [
                                _RatingsStrip(user: user),
                                if (user != null && _activeGameId != null) ...[
                                  const SizedBox(height: 22),
                                  _ActiveGameCard(
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => OnlineGameScreen(
                                            gameId: _activeGameId!,
                                          ),
                                        ),
                                      );
                                      _checkActiveGame();
                                    },
                                  ),
                                ],
                                const SizedBox(height: 45),
                                _PrimaryAction(
                                  key: const ValueKey('online-play'),
                                  onTap: () => _showPlayModes(context),
                                ),
                                const SizedBox(height: 36),
                                _SecondaryAction(
                                    icon: Icons.bolt_outlined,
                                    title: 'Bulmaca Düellosu',
                                    subtitle:
                                        '10 bulmaca · Sıra tabanlı rekabet',
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const PuzzleDuelScreen()))),
                                const _MenuDivider(),
                                _SecondaryAction(
                                  key: const ValueKey('assistant-play'),
                                  icon: Icons.auto_awesome_outlined,
                                  title: 'Asistan',
                                  subtitle: 'Hamlelerini stratejistinle planla',
                                  onTap: () =>
                                      PlayScreen.launchAssistant(context),
                                ),
                                const _MenuDivider(),
                                _SecondaryAction(
                                  icon: Icons.extension_outlined,
                                  title: 'Bulmacalar',
                                  subtitle: 'Seviyene uygun taktikleri çöz',
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const PuzzleScreen())),
                                ),
                                const _MenuDivider(),
                                DailyPuzzleMenuEntry(
                                    key: ValueKey('daily-${user?.id}'),
                                    signedIn: user != null),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  /// The panel behind the header's one button: who you are, and the
  /// screens that belong to an account rather than to a game.
  Widget _drawer(BuildContext context, User? user) {
    final username = user?.userMetadata?['username'] as String?;
    return Drawer(
      backgroundColor: const Color(0xff2a1a10),
      child: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
            child: Row(children: [
              const Icon(Icons.account_circle_outlined, color: bone, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: LText(
                  username ?? 'Misafir',
                  key: const ValueKey('drawer-name'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: bone, fontSize: 19, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),
          const Divider(height: 1, color: divider),
          _DrawerLink(
            icon: Icons.person_outline_rounded,
            label: 'Profil',
            onTap: () {
              Navigator.pop(context);
              _openProfile(context);
            },
          ),
          // An account is what gives these three something to show: a
          // subscription to hold, games already played, friends already
          // made. Signed out they would each only lead to the login page,
          // which the panel already offers at the bottom.
          if (user != null) ...[
            _DrawerLink(
              key: const ValueKey('drawer-premium'),
              icon: Icons.workspace_premium_rounded,
              label: 'ROK Premium',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SubscriptionScreen()));
              },
            ),
            _DrawerLink(
              key: const ValueKey('drawer-recent-games'),
              icon: Icons.history_rounded,
              label: 'Son Maçlar',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RecentGamesScreen()));
              },
            ),
            _DrawerLink(
              key: const ValueKey('drawer-friends'),
              icon: Icons.people_outline_rounded,
              label: 'Arkadaşlar',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const FriendsScreen()));
              },
            ),
          ],
          _DrawerLink(
            key: const ValueKey('chess-leaderboard'),
            icon: Icons.leaderboard_outlined,
            label: 'Sıralama',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ChessLeaderboardScreen()));
            },
          ),
          const Spacer(),
          const Divider(height: 1, color: divider),
          _DrawerLink(
            key: const ValueKey('login'),
            icon: user == null
                ? Icons.login_rounded
                : Icons.logout_rounded,
            label: user == null ? 'Giriş yap' : 'Çıkış yap',
            onTap: () {
              Navigator.pop(context);
              user == null ? _openAuth(context) : _showAccountActions(context);
            },
          ),
          const SizedBox(height: 10),
        ]),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.castle_rounded, color: bone, size: 33),
        const SizedBox(width: 11),
        const SizedBox(
          width: 78,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: LText(
              'ROK',
              maxLines: 1,
              style: TextStyle(
                color: bone,
                fontSize: 25,
                fontWeight: FontWeight.w500,
                letterSpacing: 5.5,
              ),
            ),
          ),
        ),
        const Spacer(),
        // The name, the profile and signing in and out used to crowd this
        // corner and still said little. One button now opens a panel where
        // each of them has room to be named.
        Builder(
          builder: (scaffoldContext) => IconButton(
            key: const ValueKey('menu-drawer'),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: tr(context, 'Menü'),
            onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
            icon: const Icon(Icons.menu_rounded, color: bone, size: 32),
          ),
        ),
      ],
    );
  }

  Future<void> _showAccountActions(BuildContext context) async {
    final signOut = await showDialog<bool>(
      context: context,
      builder: (context) => RokDialog(
        title: const LText('Oturumu kapat'),
        content: const LText('ROK hesabından çıkmak istiyor musun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const LText('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const LText('Çıkış yap'),
          ),
        ],
      ),
    );
    if (signOut != true) return;
    await AuthRepository().signOut();
    // The header reads `AppBackend.currentUser`, so it has to be rebuilt by
    // hand: nothing in the backend notifies listeners of an auth change.
    if (mounted) setState(() {});
  }

  /// Opens the sign-in screen and rebuilds the header afterwards, so the
  /// 'Giriş' label becomes 'Çıkış' the moment the user comes back.
  Future<void> _openAuth(BuildContext context) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openProfile(BuildContext context) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
    if (mounted) setState(() {});
  }

  /// The three ways to start a game, and whatever that choice needs next,
  /// all in one sheet. Picking a mode used to close it and open another, so
  /// changing your mind meant starting over from the card.
  void _showPlayModes(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheet) => _PlayModeSheet(
        onOnline: (control) {
          Navigator.pop(sheet);
          _startOnline(context, control);
        },
        onFriend: () {
          Navigator.pop(sheet);
          _openFriends(context);
        },
        onComputer: (elo) {
          Navigator.pop(sheet);
          PlayScreen.launch(context, elo: elo);
        },
      ),
    );
  }

  Future<void> _startOnline(BuildContext context, TimeControl control) async {
    if (AppBackend.currentUser == null) {
      final authenticated = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      if (!context.mounted || authenticated != true) return;
    }
    if (!context.mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => MatchmakingScreen(control: control),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openFriends(BuildContext context) async {
    if (AppBackend.currentUser == null) {
      final authenticated = await Navigator.push<bool>(
          context, MaterialPageRoute(builder: (_) => const AuthScreen()));
      if (!context.mounted || authenticated != true) return;
    }
    if (context.mounted) {
      await Navigator.push<void>(
          context, MaterialPageRoute(builder: (_) => const FriendRoomScreen()));
      if (mounted) setState(() {});
    }
  }
}

class _RatingsStrip extends StatelessWidget {
  const _RatingsStrip({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    if (user == null) return _ratings(RatingSnapshot.initial);
    return FutureBuilder<RatingSnapshot>(
      future: GameRepository().loadRatings(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const LText('Rating yüklenemedi',
              style: TextStyle(color: HomeMenuScreen.bone));
        }
        if (!snapshot.hasData) {
          return const SizedBox(
              height: 46, child: Center(child: CircularProgressIndicator()));
        }
        return _ratings(snapshot.data!);
      },
    );
  }

  Widget _ratings(RatingSnapshot ratings) => Row(
        children: [
          for (var index = 0; index < SpeedPool.values.length; index++) ...[
            if (index > 0)
              Container(width: 1, height: 46, color: HomeMenuScreen.divider),
            Expanded(
              child: Column(
                children: [
                  LText(
                    SpeedPool.values[index].label,
                    style: const TextStyle(
                      color: HomeMenuScreen.mutedBone,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 5),
                  LText(
                    '${ratings.ratingFor(SpeedPool.values[index])}',
                    style: const TextStyle(
                      color: HomeMenuScreen.bone,
                      fontSize: 23,
                      fontWeight: FontWeight.w500,
                      letterSpacing: .4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            height: 102,
            decoration: BoxDecoration(
              color: HomeMenuScreen.graphite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xff666765), width: .8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 12,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 25),
                const Icon(Icons.timer_outlined,
                    color: HomeMenuScreen.bone, size: 42),
                Container(
                  width: 1,
                  height: 54,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  color: const Color(0xff777775),
                ),
                const Expanded(
                  child: LText(
                    'OYUNA BAŞLA',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: HomeMenuScreen.bone,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.7,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: HomeMenuScreen.bone, size: 31),
                const SizedBox(width: 18),
              ],
            ),
          ),
        ),
      );
}

class _ActiveGameCard extends StatelessWidget {
  const _ActiveGameCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('resume-online-game'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xff744326),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xffd9b77e)),
            ),
            child: const Row(
              children: [
                Icon(Icons.sync_rounded, color: HomeMenuScreen.bone),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LText(
                        'DEVAM EDEN MAÇ',
                        style: TextStyle(
                          color: HomeMenuScreen.bone,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 3),
                      LText(
                        'Tahtaya dön ve güncel konumdan devam et',
                        style: TextStyle(color: HomeMenuScreen.mutedBone),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: HomeMenuScreen.bone),
              ],
            ),
          ),
        ),
      );
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 85,
            child: Row(
              children: [
                const SizedBox(width: 8),
                SizedBox(
                  width: 45,
                  child: Icon(icon, color: HomeMenuScreen.bone, size: 34),
                ),
                const SizedBox(width: 17),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LText(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: const TextStyle(
                          color: HomeMenuScreen.bone,
                          fontSize: 19,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LText(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: HomeMenuScreen.mutedBone,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: HomeMenuScreen.bone, size: 30),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      );
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        color: HomeMenuScreen.divider,
      );
}

/// The clock presets, grouped by pool. Used on its own and as a step.
class TimeControlOptions extends StatelessWidget {
  const TimeControlOptions({super.key, required this.onSelected});

  final ValueChanged<TimeControl> onSelected;

  @override
  Widget build(BuildContext context) => ListView(
        shrinkWrap: true,
        children: SpeedPool.values.map((pool) {
          final controls = TimeControl.presets
              .where((control) => control.pool == pool)
              .toList();
          return Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LText(
                  '${pool.label} · ${pool.description}',
                  style: const TextStyle(
                    color: RokSheet.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: controls
                      .map(
                        (control) => OutlinedButton(
                          key: ValueKey('time-${control.label}'),
                          onPressed: () => onSelected(control),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: rokBone,
                            backgroundColor: const Color(0x33000000),
                            side: const BorderSide(color: RokSheet.border),
                          ),
                          child: LText(
                            control.label,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          );
        }).toList(),
      );
}

class _PlayModeSheet extends StatefulWidget {
  const _PlayModeSheet({
    required this.onOnline,
    required this.onFriend,
    required this.onComputer,
  });

  final ValueChanged<TimeControl> onOnline;
  final VoidCallback onFriend;
  final ValueChanged<int> onComputer;

  @override
  State<_PlayModeSheet> createState() => _PlayModeSheetState();
}

enum _PlayStep { modes, clocks, strength, friend }

class _PlayModeSheetState extends State<_PlayModeSheet> {
  _PlayStep step = _PlayStep.modes;

  void _back() => setState(() => step = _PlayStep.modes);

  @override
  Widget build(BuildContext context) => switch (step) {
        _PlayStep.modes => RokSheet(
            icon: Icons.sports_esports_outlined,
            title: 'NASIL OYNAYALIM?',
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              RokSheetRow(
                  key: const ValueKey('mode-online'),
                  icon: Icons.public_rounded,
                  title: 'Çevrimiçi oyna',
                  subtitle: 'Dereceli eşleşme',
                  onTap: () => setState(() => step = _PlayStep.clocks)),
              const SizedBox(height: 10),
              RokSheetRow(
                  key: const ValueKey('mode-friend'),
                  icon: Icons.group_outlined,
                  title: 'Arkadaşla oyna',
                  subtitle: 'Oda kur veya davet kodu gir',
                  // A room needs an account. Signing in is a page of its own,
                  // so that case leaves the sheet; everyone else stays in it.
                  onTap: () => AppBackend.currentUser == null
                      ? widget.onFriend()
                      : setState(() => step = _PlayStep.friend)),
              const SizedBox(height: 10),
              RokSheetRow(
                  key: const ValueKey('mode-computer'),
                  icon: Icons.memory_rounded,
                  title: 'Bilgisayara karşı oyna',
                  subtitle: 'Çevrimdışı antrenman',
                  onTap: () => setState(() => step = _PlayStep.strength)),
            ]),
          ),
        _PlayStep.clocks => RokSheet(
            icon: Icons.timer_outlined,
            title: 'SÜRE SEÇ',
            onBack: _back,
            child: TimeControlOptions(onSelected: widget.onOnline),
          ),
        _PlayStep.strength => RokSheet(
            icon: Icons.memory_rounded,
            title: 'RAKİP GÜCÜ',
            note: strengthNote,
            onBack: _back,
            child: StrengthOptions(onPick: widget.onComputer),
          ),
        _PlayStep.friend => RokSheet(
            icon: Icons.group_outlined,
            title: 'ARKADAŞLA OYNA',
            onBack: _back,
            child: const FriendRoomScreen(embedded: true),
          ),
      };
}

class _DrawerLink extends StatelessWidget {
  const _DrawerLink(
      {super.key,
      required this.icon,
      required this.label,
      required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: HomeMenuScreen.mutedBone, size: 26),
        title: LText(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: HomeMenuScreen.bone,
                fontSize: 17,
                fontWeight: FontWeight.w600)),
        onTap: onTap,
      );
}
