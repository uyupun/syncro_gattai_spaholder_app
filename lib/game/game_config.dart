import 'dart:convert';

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class GameConfig {
  static GameConfig instance = GameConfig();

  // 物理パラメータ
  Vector2 gravity;
  double zoom;
  double shoulderTorque;
  double elbowTorque;

  // アーム
  double armLength;
  Vector2 shoulderPos;
  double tipRadius;

  // 敵
  double enemyRadius;

  // タイミング
  double straighteningDuration;
  double randomChangeInterval;

  // ランダム速度範囲
  double shoulderSpeedRange;
  double elbowSpeedRange;

  GameConfig({
    Vector2? gravity,
    double? zoom,
    double? shoulderTorque,
    double? elbowTorque,
    double? armLength,
    Vector2? shoulderPos,
    double? tipRadius,
    double? enemyRadius,
    double? straighteningDuration,
    double? randomChangeInterval,
    double? shoulderSpeedRange,
    double? elbowSpeedRange,
  })  : gravity = gravity ?? Vector2(0, 15),
        zoom = zoom ?? 20.0,
        shoulderTorque = shoulderTorque ?? 8000.0,
        elbowTorque = elbowTorque ?? 15000.0,
        armLength = armLength ?? 14.0,
        shoulderPos = shoulderPos ?? Vector2(-10, -7),
        tipRadius = tipRadius ?? 0.8,
        enemyRadius = enemyRadius ?? 6.0,
        straighteningDuration = straighteningDuration ?? 0.2,
        randomChangeInterval = randomChangeInterval ?? 0.3,
        shoulderSpeedRange = shoulderSpeedRange ?? 24.0,
        elbowSpeedRange = elbowSpeedRange ?? 36.0;

  factory GameConfig.fromJson(Map<String, dynamic> json) {
    return GameConfig(
      gravity: json['gravity'] != null
          ? Vector2(
              (json['gravity']['x'] as num).toDouble(),
              (json['gravity']['y'] as num).toDouble(),
            )
          : null,
      zoom: (json['zoom'] as num?)?.toDouble(),
      shoulderTorque: (json['shoulderTorque'] as num?)?.toDouble(),
      elbowTorque: (json['elbowTorque'] as num?)?.toDouble(),
      armLength: (json['armLength'] as num?)?.toDouble(),
      shoulderPos: json['shoulderPos'] != null
          ? Vector2(
              (json['shoulderPos']['x'] as num).toDouble(),
              (json['shoulderPos']['y'] as num).toDouble(),
            )
          : null,
      tipRadius: (json['tipRadius'] as num?)?.toDouble(),
      enemyRadius: (json['enemyRadius'] as num?)?.toDouble(),
      straighteningDuration:
          (json['straighteningDuration'] as num?)?.toDouble(),
      randomChangeInterval:
          (json['randomChangeInterval'] as num?)?.toDouble(),
      shoulderSpeedRange:
          (json['shoulderSpeedRange'] as num?)?.toDouble(),
      elbowSpeedRange:
          (json['elbowSpeedRange'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gravity': {'x': gravity.x, 'y': gravity.y},
      'zoom': zoom,
      'shoulderTorque': shoulderTorque,
      'elbowTorque': elbowTorque,
      'armLength': armLength,
      'shoulderPos': {'x': shoulderPos.x, 'y': shoulderPos.y},
      'tipRadius': tipRadius,
      'enemyRadius': enemyRadius,
      'straighteningDuration': straighteningDuration,
      'randomChangeInterval': randomChangeInterval,
      'shoulderSpeedRange': shoulderSpeedRange,
      'elbowSpeedRange': elbowSpeedRange,
    };
  }

  static Future<GameConfig> loadFromAsset() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/game_config.json');
      instance = GameConfig.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('Failed to load game_config.json, using defaults: $e');
      instance = GameConfig();
    }
    return instance;
  }

  void reset() {
    final defaults = GameConfig();
    gravity = defaults.gravity;
    zoom = defaults.zoom;
    shoulderTorque = defaults.shoulderTorque;
    elbowTorque = defaults.elbowTorque;
    armLength = defaults.armLength;
    shoulderPos = defaults.shoulderPos;
    tipRadius = defaults.tipRadius;
    enemyRadius = defaults.enemyRadius;
    straighteningDuration = defaults.straighteningDuration;
    randomChangeInterval = defaults.randomChangeInterval;
    shoulderSpeedRange = defaults.shoulderSpeedRange;
    elbowSpeedRange = defaults.elbowSpeedRange;
  }
}
