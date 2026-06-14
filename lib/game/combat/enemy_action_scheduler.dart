import 'dart:math';

/// 敵が技を繰り出すタイミングをランダムな間隔(秒)で管理する
class EnemyActionScheduler {
  static const List<int> intervalSecondsOptions = [5, 6, 7, 8, 9, 10];

  final Random _random;
  double _timer = 0;
  double _nextInterval;

  EnemyActionScheduler({Random? random})
    : _random = random ?? Random(),
      _nextInterval = 0 {
    _nextInterval = _pickInterval();
  }

  double _pickInterval() {
    final index = _random.nextInt(intervalSecondsOptions.length);
    return intervalSecondsOptions[index].toDouble();
  }

  /// dt秒進める。技を繰り出すタイミングに達した場合はtrueを返し、次の間隔を再抽選する。
  bool update(double dt) {
    _timer += dt;
    if (_timer >= _nextInterval) {
      _timer = 0;
      _nextInterval = _pickInterval();
      return true;
    }
    return false;
  }
}
