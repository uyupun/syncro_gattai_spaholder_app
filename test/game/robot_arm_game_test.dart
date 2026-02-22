import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spajam2025_app/accessors/ble_mock_accessor.dart';
import 'package:spajam2025_app/game/robot_arm_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RobotArmGame', () {
    RobotArmGame gameFactory() => RobotArmGame(
          bleService: BleMockAccessor(),
        );

    test('初期状態でisRandomModeがfalse', () {
      final game = gameFactory();
      expect(game.isRandomMode, false);
    });

    test('showSuccessMessageの初期値がfalse', () {
      final game = gameFactory();
      expect(game.showSuccessMessage.value, false);
    });

    testWithGame(
      'onLoad後にランダムモードが有効',
      gameFactory,
      (game) async {
        await game.ready();
        expect(game.isRandomMode, true);
      },
    );

    testWithGame(
      'startStraighteningで整列モード開始',
      gameFactory,
      (game) async {
        await game.ready();
        game.startStraightening();
        // stopStraighteningで解除
        game.stopStraightening();
        // ランダムモードは維持
        expect(game.isRandomMode, true);
      },
    );
  });
}
