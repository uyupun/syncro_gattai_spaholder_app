# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter mobile game app built for SPAJAM 2025 hackathon. It's an interactive robot arm game that uses BLE (Bluetooth Low Energy) to connect with M5Stack devices. The game involves controlling a robot arm to hit targets, with real-time sensor data from connected devices triggering actions.

## Build & Run Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run on specific device
flutter run -d <device_id>

# Analyze code
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart
```

## Architecture

### Core Game Engine
- Uses **Flame** game engine with **Forge2D** physics
- `RobotArmGame` (lib/main.dart:687) - Main game class extending `Forge2DGame`
- Physics-based robot arm with shoulder and elbow joints (RevoluteJoint)
- Random movement mode with configurable intervals

### BLE Communication
- `BleManager` (lib/ble_manager.dart) - Singleton managing BLE connections
- Connects to M5Stack devices named "uyupun-drill"
- Two services:
  - Accelerometer service (UUID: 11111111-2222-...) - Receives float32 sensor data
  - Water pump service (UUID: 22222222-3333-...) - Sends boolean commands
- Supports up to 2 simultaneous device connections

### Screen Flow
```
TitleScreen → CountdownScreen → GameWrapper (game) → GameClearScreen
     ↓
BleDebugPage (alternative debug entry)
```

### Key Game Components
- `ArmPart` - Physics body component for arm segments (shoulder, upperArm, foreArm)
- `Enemy` - Target to hit, changes sprite on collision
- `GameWrapper` - Overlays Flutter UI on Flame game, handles BLE data → game actions

### Game Mechanics
- Arm straightening triggered when both BLE devices report values ≥ 0.5
- Hit detection uses tip radius (0.8) vs enemy radius (6)
- On hit: physics stops, success message displays, pump command sent via BLE

## Assets

- Images: `assets/images/` (robot parts, enemies, background)
- Audio: `assets/audio/` (title.mp3, game.mp3, clear.mp3)

## Dependencies

Key packages:
- `flame` / `flame_forge2d` - Game engine with physics
- `flame_audio` - BGM and sound effects
- `flutter_blue_plus` - BLE communication

## Language

Code comments and UI text are in Japanese.
