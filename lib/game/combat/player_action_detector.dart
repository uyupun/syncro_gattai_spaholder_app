import '../../models/accel_data.dart';

enum PlayerActionType { none, attack, guard, charge }

class PlayerActionResult {
  final PlayerActionType type;

  /// [PlayerActionType.attack]時: 発動時点のチャージレベル(攻撃倍率算出用)
  /// その他: 現在のチャージレベル
  final int chargeLevel;

  const PlayerActionResult(this.type, this.chargeLevel);
}

/// BLE加速度センサー(2台分)の値からスパホルダーのシンクロ技の発動を検出する
class PlayerActionDetector {
  static const double thresholdX = 0.77;
  static const double thresholdY = 0.95;
  static const double thresholdZ = 1.65;
  static const int maxChargeLevel = 5;

  /// チャージレベルごとの攻撃倍率 (index = charge level)
  static const List<double> chargeMultipliers = [1.0, 1.5, 2.0, 3.0, 4.0, 5.0];

  int _chargeLevel = 0;
  bool _prevX = false;
  bool _prevY = false;
  bool _prevZ = false;

  /// 現在ガード姿勢(Y軸しきい値超え)が継続しているか
  bool get isGuarding => _prevY;

  /// 現在のチャージレベル(0〜maxChargeLevel)
  int get chargeLevel => _chargeLevel;

  /// チャージレベルを0にリセットする(ガード発動時などに使用)
  void resetCharge() => _chargeLevel = 0;

  PlayerActionResult detect(
    Map<String, AccelData> accelData,
    List<String> connectedIds, {
    bool isGuarding = false,
    bool isActionLocked = false,
  }) {
    final xVal = _minAxisValue(accelData, connectedIds, (d) => d.x);
    final yVal = _minAxisValue(accelData, connectedIds, (d) => d.y.abs());
    final zVal = _minAxisValue(accelData, connectedIds, (d) => d.z);

    final x = xVal != null && xVal >= thresholdX;
    final y = yVal != null && yVal >= thresholdY;
    final z = zVal != null && zVal >= thresholdZ;

    final prevX = _prevX;
    final prevY = _prevY;
    final prevZ = _prevZ;
    _prevX = x;
    _prevY = y;
    _prevZ = z;

    if (isActionLocked) {
      return PlayerActionResult(PlayerActionType.none, _chargeLevel);
    }

    // 各軸の立ち上がりエッジと発動条件を確認
    final xRising = x && !prevX && !isGuarding;
    final yRising = y && !prevY;
    final zRising = z && !prevZ && _chargeLevel < maxChargeLevel && !isGuarding;

    if (!xRising && !yRising && !zRising) {
      return PlayerActionResult(PlayerActionType.none, _chargeLevel);
    }

    // 複数軸が同時に立ち上がった場合、「値 - 閾値」が最大の軸の技を発動
    final xExcess = xRising ? xVal - thresholdX : double.negativeInfinity;
    final yExcess = yRising ? yVal - thresholdY : double.negativeInfinity;
    final zExcess = zRising ? zVal - thresholdZ : double.negativeInfinity;

    if (xExcess >= yExcess && xExcess >= zExcess) {
      final level = _chargeLevel;
      _chargeLevel = 0;
      return PlayerActionResult(PlayerActionType.attack, level);
    } else if (yExcess >= zExcess) {
      return PlayerActionResult(PlayerActionType.guard, _chargeLevel);
    } else {
      _chargeLevel++;
      return PlayerActionResult(PlayerActionType.charge, _chargeLevel);
    }
  }

  /// 接続デバイス全台の軸値の最小値を返す。2台未満またはデータ欠損時はnullを返す。
  double? _minAxisValue(
    Map<String, AccelData> accelData,
    List<String> connectedIds,
    double Function(AccelData) axis,
  ) {
    if (connectedIds.length < 2) return null;
    double? minVal;
    for (final id in connectedIds) {
      final data = accelData[id];
      if (data == null) return null;
      final val = axis(data);
      if (minVal == null || val < minVal) minVal = val;
    }
    return minVal;
  }
}
