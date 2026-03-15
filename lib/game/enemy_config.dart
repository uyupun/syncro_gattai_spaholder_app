import '../interfaces/json_exportable.dart';
import '../mixins/asset_loadable.dart';

class EnemyConfig implements JsonExportable {
  final double spriteScale;

  EnemyConfig({double? spriteScale}) : spriteScale = spriteScale ?? 2.5;

  factory EnemyConfig.fromJson(Map<String, dynamic> json) {
    return EnemyConfig(spriteScale: (json['spriteScale'] as num?)?.toDouble());
  }

  @override
  Map<String, dynamic> toJson() => {'spriteScale': spriteScale};

  EnemyConfig copyWith({double? spriteScale}) {
    return EnemyConfig(spriteScale: spriteScale ?? this.spriteScale);
  }

  static Future<EnemyConfig> loadFromAsset() async {
    return AssetLoadable.loadFromAsset<EnemyConfig>(
      'assets/enemy_config.json',
      EnemyConfig.fromJson,
      EnemyConfig.new,
    );
  }
}
