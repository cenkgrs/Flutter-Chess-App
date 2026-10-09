import 'package:flutter/material.dart';

import '../online/time_control.dart';
import '../prototype/play_screen.dart';

class HomeMenuScreen extends StatelessWidget {
  const HomeMenuScreen({super.key});

  static const bone = Color(0xfff3eee7);
  static const mutedBone = Color(0xffb9aea5);
  static const graphite = Color(0xff202120);
  static const ink = Color(0xff211712);
  static const divider = Color(0x66d8cec5);

  @override
  Widget build(BuildContext context) => Scaffold(
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
                          _header(context),
                          const SizedBox(height: 76),
                          const _RatingsStrip(),
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
                            onTap: () => _comingSoon(context),
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

  Widget _header(BuildContext context) => Row(
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
          const Icon(Icons.account_circle_outlined, color: mutedBone, size: 34),
          const SizedBox(width: 8),
          const SizedBox(
            width: 53,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Misafir',
                maxLines: 1,
                style: TextStyle(color: mutedBone, fontSize: 15),
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
            onTap: () => _comingSoon(context),
            borderRadius: BorderRadius.circular(4),
            child: const SizedBox(
              width: 38,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Giriş',
                  maxLines: 1,
                  style: TextStyle(
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

  void _showTimeControls(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _TimeControlSheet(),
    );
  }

  static void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: graphite,
        content: Text('Bu akış Supabase bağlantısıyla etkinleşecek.'),
      ),
    );
  }
}

class _RatingsStrip extends StatelessWidget {
  const _RatingsStrip();

  @override
  Widget build(BuildContext context) => Row(
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
                  const Text(
                    '1500',
                    style: TextStyle(
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
  const _TimeControlSheet();

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
                                  onPressed: () =>
                                      HomeMenuScreen._comingSoon(context),
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
