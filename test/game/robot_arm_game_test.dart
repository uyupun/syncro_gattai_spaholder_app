import 'package:flutter_test/flutter_test.dart';
import 'package:spajam2025_app/accessors/ble_mock_accessor.dart';
import 'package:spajam2025_app/game/arm_layout_config.dart';
import 'package:spajam2025_app/game/enemy_config.dart';
import 'package:spajam2025_app/game/game_config.dart';
import 'package:spajam2025_app/game/robot_arm_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RobotArmGame', () {
    RobotArmGame gameFactory() => RobotArmGame(
      bleService: BleMockAccessor(),
      config: GameConfig(),
      layout: ArmLayoutConfig(),
      enemyConfig: EnemyConfig(),
    );

    test('初期状態でisRandomModeがfalse', () {
      final game = gameFactory();
      expect(game.isRandomMode, false);
    });

    test('showSuccessMessageの初期値がfalse', () {
      final game = gameFactory();
      expect(game.showSuccessMessage.value, false);
    });
  });
}
