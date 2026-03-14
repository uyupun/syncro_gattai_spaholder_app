# CLAUDE.md

## 概要

BLE対応M5Stack 2台の加速度センサーで操作するFlutter製物理演算ロボットアームゲーム。Flame + Forge2D + flutter_blue_plus。横向き固定モバイルアプリ。

## 技術スタック

| 項目 | 値 |
|------|-----|
| Flutter | 3.38.4 (mise管理) |
| Dart SDK | ^3.10.3 |
| Flame | ^1.34.0 + flame_forge2d ^0.19.2+2 |
| BLE | flutter_blue_plus ^2.0.2 |
| パッケージ名 | spajam2025_app |

## コマンド

**flutterコマンドは必ず `mise exec --` 経由で実行**

```bash
mise exec -- flutter pub get           # 依存関係
mise exec -- flutter analyze           # 静的解析
mise exec -- flutter test              # 全テスト
mise exec -- flutter test test/game/   # ディレクトリ指定
mise exec -- flutter run               # 実行
mise exec -- flutter devices           # デバイス一覧
```

## アーキテクチャ

### レイヤー構成

```
interfaces/    BleService (抽象)
game/          RobotArmGame, GameConfig, ArmLayoutConfig, EnemyConfig
  components/  ArmPart, Enemy
accessors/     BleMockAccessor (BleService mock実装)
models/        AccelData
resources/     GameAudio, GameImage (enum定数)
debug/         DebugConfigOverlay (ランタイムConfig調整)
```

- `lib/main.dart` - 画面管理(AppScreen enum) + UI + 旧版ゲームロジック(未抽出)
- `lib/ble_manager.dart` - BleService実装 (M5Stack BLE通信)
- `lib/ble_debug_page.dart` - BLEデバッグUI

### DI設計

GameConfig / ArmLayoutConfig / EnemyConfig はすべてコンストラクタ注入。シングルトンなし。JSONアセットから `loadFromAsset()` で生成可能。

### 画面遷移

```
Title → Countdown(3,2,1) → Game → GameClear → Title(ループ)
```

### ゲームロジック

- 3パーツ: shoulder(静的) → upperArm → foreArm(drill)、RevoluteJoint接続
- ランダムモード: モーター速度を0.3秒間隔でランダム適用
- 腕伸ばし: 前腕角度を上腕に強制同期(200ms)、ヒットチェック実行
- 敵ヒット → 物理停止 → 成功メッセージ → ポンプON(BLE送信)

### BLE通信

- `BleService`インターフェース → `BleManager`(実機) / `BleMockAccessor`(テスト)
- デバイス名 `uyupun-drill` のM5Stackを最大2台自動接続
- 受信: 加速度(4byte float LE) → `accelDataStream`
- 送信: ポンプ制御 → `sendBool()`
- 2台の加速度値が両方 >= 0.3 で腕伸ばし発動

### 設定ファイル(assets/)

| ファイル | 内容 |
|---------|------|
| `game_config.json` | 重力, zoom, トルク, アーム長, 物理パラメータ |
| `arm_layout.json` | パーツ位置/サイズ, ジョイントアンカー, 先端オフセット |
| `enemy_config.json` | spriteScale |
