import '../interfaces/json_exportable.dart';
import '../mixins/asset_loadable.dart';

class HpBarConfig implements JsonExportable {
  final double maxHp;
  final double barPositionX;
  final double barPositionY;
  final double barSizeX;
  final double barSizeY;

  HpBarConfig({
    double? maxHp,
    double? barPositionX,
    double? barPositionY,
    double? barSizeX,
    double? barSizeY,
  }) : maxHp = maxHp ?? 100,
       barPositionX = barPositionX ?? 0,
       barPositionY = barPositionY ?? 0,
       barSizeX = barSizeX ?? 100,
       barSizeY = barSizeY ?? 10;

  factory HpBarConfig.fromJson(Map<String, dynamic> json) {
    return HpBarConfig(
      maxHp: (json['maxHp'] as num?)?.toDouble(),
      barPositionX: (json['barPositionX'] as num?)?.toDouble(),
      barPositionY: (json['barPositionY'] as num?)?.toDouble(),
      barSizeX: (json['barSizeX'] as num?)?.toDouble(),
      barSizeY: (json['barSizeY'] as num?)?.toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'maxHp': maxHp,
    'barPositionX': barPositionX,
    'barPositionY': barPositionY,
    'barSizeX': barSizeX,
    'barSizeY': barSizeY,
  };

  HpBarConfig copyWith({
    double? maxHp,
    double? barPositionX,
    double? barPositionY,
    double? barSizeX,
    double? barSizeY,
  }) {
    return HpBarConfig(
      maxHp: maxHp ?? this.maxHp,
      barPositionX: barPositionX ?? this.barPositionX,
      barPositionY: barPositionY ?? this.barPositionY,
      barSizeX: barSizeX ?? this.barSizeX,
      barSizeY: barSizeY ?? this.barSizeY,
    );
  }

  // Why: JSONファイルにplayer/enemy 2エントリを持つ。将来のplayer HP実装に備える。
  // Recordで返すことで呼び出し側が必要な方だけ取得できる。
  static Future<({HpBarConfig player, HpBarConfig enemy})>
  loadFromAsset() async {
    return AssetLoadable.loadFromAsset(
      'assets/hp_bar_config.json',
      (json) => (
        player: HpBarConfig.fromJson(
          (json['player'] as Map<String, dynamic>?) ?? {},
        ),
        enemy: HpBarConfig.fromJson(
          (json['enemy'] as Map<String, dynamic>?) ?? {},
        ),
      ),
      () => (player: HpBarConfig(), enemy: HpBarConfig()),
    );
  }
}
