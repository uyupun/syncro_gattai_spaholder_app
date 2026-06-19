import '../interfaces/json_exportable.dart';
import '../mixins/asset_loadable.dart';

class EnemyConfig implements JsonExportable {
  final double yugarockSpriteScale;
  final double asyncronSpriteScale;

  EnemyConfig({double? yugarockSpriteScale, double? asyncronSpriteScale})
    : yugarockSpriteScale = yugarockSpriteScale ?? 3.0,
      asyncronSpriteScale = asyncronSpriteScale ?? 2.5;

  factory EnemyConfig.fromJson(Map<String, dynamic> json) {
    return EnemyConfig(
      yugarockSpriteScale:
          (json['yugarockSpriteScale'] as num?)?.toDouble() ??
          (json['spriteScale'] as num?)?.toDouble(),
      asyncronSpriteScale:
          (json['asyncronSpriteScale'] as num?)?.toDouble() ??
          (json['spriteScale'] as num?)?.toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'yugarockSpriteScale': yugarockSpriteScale,
    'asyncronSpriteScale': asyncronSpriteScale,
  };

  EnemyConfig copyWith({
    double? yugarockSpriteScale,
    double? asyncronSpriteScale,
  }) {
    return EnemyConfig(
      yugarockSpriteScale: yugarockSpriteScale ?? this.yugarockSpriteScale,
      asyncronSpriteScale: asyncronSpriteScale ?? this.asyncronSpriteScale,
    );
  }

  static Future<EnemyConfig> loadFromAsset() async {
    return AssetLoadable.loadFromAsset<EnemyConfig>(
      'assets/enemy_config.json',
      EnemyConfig.fromJson,
      EnemyConfig.new,
    );
  }
}
