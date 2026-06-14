import '../mixins/asset_loadable.dart';

class ActionConfig {
  final String nameJa;
  final int power;

  ActionConfig({String? nameJa, int? power})
    : nameJa = nameJa ?? '',
      power = power ?? 0;

  factory ActionConfig.fromJson(Map<String, dynamic> json) {
    return ActionConfig(
      nameJa: json['nameJa'] as String?,
      power: (json['power'] as num?)?.toInt(),
    );
  }
}

class ActionsConfig {
  final ActionConfig synchroCharge;
  final ActionConfig synchroAttack;
  final ActionConfig synchroGuard;
  final ActionConfig yugarockRoll;
  final ActionConfig yugarockLandfill;
  final ActionConfig asyncStream;
  final ActionConfig asyncVacuum;
  final ActionConfig asyncPendulum;

  ActionsConfig({
    ActionConfig? synchroCharge,
    ActionConfig? synchroAttack,
    ActionConfig? synchroGuard,
    ActionConfig? yugarockRoll,
    ActionConfig? yugarockLandfill,
    ActionConfig? asyncStream,
    ActionConfig? asyncVacuum,
    ActionConfig? asyncPendulum,
  }) : synchroCharge =
           synchroCharge ?? ActionConfig(nameJa: 'シンクロ\nチャージ', power: 0),
       synchroAttack =
           synchroAttack ?? ActionConfig(nameJa: 'シンクロ\nアタック', power: 10),
       synchroGuard =
           synchroGuard ?? ActionConfig(nameJa: 'シンクロ\nガード', power: 25),
       yugarockRoll =
           yugarockRoll ?? ActionConfig(nameJa: 'ローリングアタック', power: 10),
       yugarockLandfill =
           yugarockLandfill ?? ActionConfig(nameJa: '土砂崩し', power: 20),
       asyncStream =
           asyncStream ?? ActionConfig(nameJa: 'アシンクストリーム', power: 20),
       asyncVacuum =
           asyncVacuum ?? ActionConfig(nameJa: 'アシンクバキューム', power: 30),
       asyncPendulum =
           asyncPendulum ?? ActionConfig(nameJa: 'アシンクペンデュラム', power: 0);

  /// ユガロックが繰り出す技の一覧
  List<ActionConfig> get yugarockActions => [yugarockRoll, yugarockLandfill];

  /// アシンクロンがランダム間隔で繰り出す技の一覧(asyncPendulumは戦闘開始時のみ発動するため含まない)
  List<ActionConfig> get asyncronActions => [asyncStream, asyncVacuum];

  factory ActionsConfig.fromJson(Map<String, dynamic> json) {
    final playerActions =
        (json['player'] as Map<String, dynamic>?)?['actions']
            as Map<String, dynamic>? ??
        {};
    final yugarockActions =
        ((json['enemies'] as Map<String, dynamic>?)?['yugarock']
                as Map<String, dynamic>?)?['actions']
            as Map<String, dynamic>? ??
        {};
    final asyncronActions =
        ((json['enemies'] as Map<String, dynamic>?)?['asyncron']
                as Map<String, dynamic>?)?['actions']
            as Map<String, dynamic>? ??
        {};

    return ActionsConfig(
      synchroCharge: ActionConfig.fromJson(
        playerActions['synchroCharge'] as Map<String, dynamic>? ?? {},
      ),
      synchroAttack: ActionConfig.fromJson(
        playerActions['synchroAttack'] as Map<String, dynamic>? ?? {},
      ),
      synchroGuard: ActionConfig.fromJson(
        playerActions['synchroGuard'] as Map<String, dynamic>? ?? {},
      ),
      yugarockRoll: ActionConfig.fromJson(
        yugarockActions['roll'] as Map<String, dynamic>? ?? {},
      ),
      yugarockLandfill: ActionConfig.fromJson(
        yugarockActions['landfill'] as Map<String, dynamic>? ?? {},
      ),
      asyncStream: ActionConfig.fromJson(
        asyncronActions['asyncStream'] as Map<String, dynamic>? ?? {},
      ),
      asyncVacuum: ActionConfig.fromJson(
        asyncronActions['asyncVacuum'] as Map<String, dynamic>? ?? {},
      ),
      asyncPendulum: ActionConfig.fromJson(
        asyncronActions['asyncPendulum'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  static Future<ActionsConfig> loadFromAsset() async {
    return AssetLoadable.loadFromAsset<ActionsConfig>(
      'assets/actions_config.json',
      ActionsConfig.fromJson,
      ActionsConfig.new,
    );
  }
}
