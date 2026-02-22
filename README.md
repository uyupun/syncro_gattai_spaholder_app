# syncro_gattai_spaholder_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## BLEモックモード

M5Stack実機なしで開発・テストする場合、`--dart-define` で `USE_MOCK_BLE=true` を指定してモックBLEモードで起動できます。

```bash
# iOSシミュレータ
mise exec -- flutter run -d iPhone --dart-define=USE_MOCK_BLE=true

# Androidエミュレータ
mise exec -- flutter run -d emulator --dart-define=USE_MOCK_BLE=true
```

VSCodeの場合は、`.vscode/launch.json` に定義済みの「Mock BLE」起動構成を使用してください。
