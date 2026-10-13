import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend/app_backend.dart';
import '../backend/auth_repository.dart';
import '../backend/game_repository.dart';
import '../online/time_control.dart';
import '../prototype/play_screen.dart';
import 'auth_screen.dart';
import 'friend_room_screen.dart';
import 'friends_screen.dart';
import 'matchmaking_screen.dart';
import 'profile_screen.dart';
import 'puzzle_screen.dart';
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

class _HomeMenuScreenState extends State<HomeMenuScreen> with RouteAware {
  static const bone = HomeMenuScreen.bone;
  static const mutedBone = HomeMenuScreen.mutedBone;
  static const divider = HomeMenuScreen.divider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) appRouteObserver.subscribe(this, route);
  }

  @override
  void didPopNext() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
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
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
                      child: Column(
                        children: [
                          _header(context, user),
                          Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                icon: const Icon(Icons.person_add_alt_1,
                                    color: bone),
                                label: user == null
                                    ? const Text('Arkadaşlar',
                                        style: TextStyle(color: bone))
                                    : FriendRequestLabel(
                                        key: ValueKey(user.id)),
                                onPressed: () => _openSocial(context),
                              )),
                          const SizedBox(height: 76),
                          _RatingsStrip(user: user),
                          const SizedBox(height: 45),
                          _PrimaryAction(
                            key: const ValueKey('online-play'),
                            onTap: () => _showTimeControls(context),
                          ),
                          const SizedBox(height: 36),
                          _SecondaryAction(
                            icon: Icons.group_outlined,
                            title: 'Arkadaşla oyna',
                            subtitle: 'Oda kur veya davet kodu gir',
                            onTap: () => _openFriends(context),
                          ),
                          const _MenuDivider(),
                          _SecondaryAction(
                            key: const ValueKey('computer-play'),
                            icon: Icons.memory_rounded,
                            title: 'Bilgisayara karşı',
                            subtitle: 'Çevrimdışı antrenman',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PlayScreen(),
                              ),
                            ),
                          ),
                          const _MenuDivider(),
                          _SecondaryAction(
                            icon: Icons.extension_outlined,
                            title: 'Bulmacalar',
                            subtitle: 'Seviyene uygun taktikleri çöz',
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const PuzzleScreen())),
                          ),
                          const _MenuDivider(),
                          _SecondaryAction(
                            icon: Icons.auto_awesome_outlined,
                            title: 'Asistan',
                            subtitle: 'Hamlelerini stratejistinle planla',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const PlayScreen(assistantMode: true),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _header(BuildContext context, User? user) {
    final username = user?.userMetadata?['username'] as String?;
    return Row(
      children: [
        const Icon(Icons.castle_rounded, color: bone, size: 33),
        const SizedBox(width: 11),
        const SizedBox(
          width: 78,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
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
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: user == null
              ? () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()))
              : () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen())),
          icon: const Icon(Icons.account_circle_outlined,
              color: mutedBone, size: 34),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 53,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              username ?? 'Misafir',
              maxLines: 1,
              style: const TextStyle(color: mutedBone, fontSize: 15),
            ),
          ),
        ),
        Container(
          width: 1,
          height: 27,
          margin: const EdgeInsets.symmetric(horizontal: 13),
          color: divider,
        ),
        InkWell(
          key: const ValueKey('login'),
          onTap: () => user == null
              ? Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                )
              : _showAccountActions(context),
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 38,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                user == null ? 'Giriş' : 'Çıkış',
                maxLines: 1,
                style: const TextStyle(
                  color: bone,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showAccountActions(BuildContext context) async {
    final signOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Oturumu kapat'),
        content: const Text('ROK hesabından çıkmak istiyor musun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Çıkış yap'),
          ),
        ],
      ),
    );
    if (signOut == true) await AuthRepository().signOut();
  }

  void _showTimeControls(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TimeControlSheet(
        onSelected: (control) {
          Navigator.pop(context);
          _startOnline(context, control);
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

  Future<void> _openSocial(BuildContext context) async {
    if (AppBackend.currentUser == null) {
      final authenticated = await Navigator.push<bool>(
          context, MaterialPageRoute(builder: (_) => const AuthScreen()));
      if (!context.mounted || authenticated != true) return;
    }
    if (context.mounted) {
      await Navigator.push<void>(
          context, MaterialPageRoute(builder: (_) => const FriendsScreen()));
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
          return const Text('Rating yüklenemedi',
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
                  Text(
                    SpeedPool.values[index].label,
                    style: const TextStyle(
                      color: HomeMenuScreen.mutedBone,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OYUNA BAŞLA',
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: TextStyle(
                          color: HomeMenuScreen.bone,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.7,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Dereceli çevrimiçi eşleşme',
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: TextStyle(
                          color: HomeMenuScreen.mutedBone,
                          fontSize: 14,
                        ),
                      ),
                    ],
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
                      Text(
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
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
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

class _TimeControlSheet extends StatelessWidget {
  const _TimeControlSheet({required this.onSelected});

  final ValueChanged<TimeControl> onSelected;

  @override
  Widget build(BuildContext context) => Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .78),
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
        decoration: const BoxDecoration(
          color: Color(0xfff3eee7),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xffb9aea5),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 17),
            const Row(
              children: [
                Icon(Icons.timer_outlined, color: HomeMenuScreen.ink),
                SizedBox(width: 10),
                Text(
                  'SÜRE SEÇ',
                  style: TextStyle(
                    color: HomeMenuScreen.ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
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
                        Text(
                          '${pool.label} · ${pool.description}',
                          style: const TextStyle(
                            color: Color(0xff665a52),
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
                                    foregroundColor: HomeMenuScreen.ink,
                                    side: const BorderSide(
                                        color: Color(0xffb9aea5)),
                                  ),
                                  child: Text(
                                    control.label,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
}
