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
  static const double thresholdX = 1.0;
  static const double thresholdY = 0.75;
  static const double thresholdZ = 2.0;
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
  }) {
    final x = _bothExceed(accelData, connectedIds, (d) => d.x, thresholdX);
    final y = _bothExceed(
      accelData,
      connectedIds,
      (d) => d.y.abs(),
      thresholdY,
    );
    final z = _bothExceed(accelData, connectedIds, (d) => d.z, thresholdZ);

    PlayerActionResult result = PlayerActionResult(
      PlayerActionType.none,
      _chargeLevel,
    );

    if (x && !_prevX && !isGuarding) {
      final level = _chargeLevel;
      _chargeLevel = 0;
      result = PlayerActionResult(PlayerActionType.attack, level);
    } else if (y && !_prevY) {
      result = PlayerActionResult(PlayerActionType.guard, _chargeLevel);
    } else if (z && !_prevZ && _chargeLevel < maxChargeLevel && !isGuarding) {
      _chargeLevel++;
      result = PlayerActionResult(PlayerActionType.charge, _chargeLevel);
    }

    _prevX = x;
    _prevY = y;
    _prevZ = z;

    return result;
  }

  bool _bothExceed(
    Map<String, AccelData> accelData,
    List<String> connectedIds,
    double Function(AccelData) axis,
    double threshold,
  ) {
    if (connectedIds.length < 2) return false;
    return connectedIds.every((id) {
      final data = accelData[id];
      return data != null && axis(data) >= threshold;
    });
  }
}
