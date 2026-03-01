# 真黒合体スパホルダー

## 環境構築

```bash
mise trust
mise install
flutter pub get
flutter run
```

### プリコミット

`mise install` のタイミングで以下が実行される。もし、実行されなかった場合は手動で実行する。

```bash
sh hooks/install-hooks.sh
```

## BLEモックモード

M5Stack実機なしで開発・テストする場合、`--dart-define` で `USE_MOCK_BLE=true` を指定してモックBLEモードで起動できます。

```bash
# iOSシミュレータ
mise exec -- flutter run -d iPhone --dart-define=USE_MOCK_BLE=true

# Androidエミュレータ
mise exec -- flutter run -d emulator --dart-define=USE_MOCK_BLE=true
```

VSCodeの場合は、`.vscode/launch.json` に定義済みの「Mock BLE」起動構成を使用してください。
