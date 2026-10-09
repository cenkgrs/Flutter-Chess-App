enum SpeedPool { bullet, blitz, rapid, classical }

extension SpeedPoolUi on SpeedPool {
  String get label => const ['Bullet', 'Blitz', 'Rapid', 'Klasik'][index];
  String get databaseName =>
      const ['bullet', 'blitz', 'rapid', 'classical'][index];
  String get description => const [
        'Çok hızlı',
        'Hızlı',
        'Düşünerek',
        'Uzun oyun',
      ][index];
}

class TimeControl {
  const TimeControl(this.minutes, this.increment, this.pool);

  final int minutes;
  final int increment;
  final SpeedPool pool;

  String get label => '$minutes+$increment';

  static const presets = <TimeControl>[
    TimeControl(1, 0, SpeedPool.bullet),
    TimeControl(1, 1, SpeedPool.bullet),
    TimeControl(2, 1, SpeedPool.bullet),
    TimeControl(3, 0, SpeedPool.blitz),
    TimeControl(3, 2, SpeedPool.blitz),
    TimeControl(5, 0, SpeedPool.blitz),
    TimeControl(5, 3, SpeedPool.blitz),
    TimeControl(10, 0, SpeedPool.rapid),
    TimeControl(10, 5, SpeedPool.rapid),
    TimeControl(15, 10, SpeedPool.rapid),
    TimeControl(30, 0, SpeedPool.classical),
    TimeControl(30, 20, SpeedPool.classical),
    TimeControl(45, 45, SpeedPool.classical),
    TimeControl(60, 0, SpeedPool.classical),
  ];
}
