import 'dart:convert';

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/services.dart';

class GameConfig {
  final Vector2 gravity;
  final double zoom;
  final double shoulderTorque;
  final double elbowTorque;

  final double armLength;
  final Vector2 shoulderPos;
  final double tipRadius;

  final double enemyRadius;

  final double straighteningDuration;
  final double randomChangeInterval;

  final double shoulderSpeedRange;
  final double elbowSpeedRange;

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

  factory GameConfig.defaultConfig() => GameConfig();

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
      return GameConfig.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );
    } catch (_) {
      return GameConfig.defaultConfig();
    }
  }

  GameConfig copyWith({
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
  }) {
    return GameConfig(
      gravity: gravity ?? this.gravity,
      zoom: zoom ?? this.zoom,
      shoulderTorque: shoulderTorque ?? this.shoulderTorque,
      elbowTorque: elbowTorque ?? this.elbowTorque,
      armLength: armLength ?? this.armLength,
      shoulderPos: shoulderPos ?? this.shoulderPos,
      tipRadius: tipRadius ?? this.tipRadius,
      enemyRadius: enemyRadius ?? this.enemyRadius,
      straighteningDuration:
          straighteningDuration ?? this.straighteningDuration,
      randomChangeInterval:
          randomChangeInterval ?? this.randomChangeInterval,
      shoulderSpeedRange: shoulderSpeedRange ?? this.shoulderSpeedRange,
      elbowSpeedRange: elbowSpeedRange ?? this.elbowSpeedRange,
    );
  }
}
