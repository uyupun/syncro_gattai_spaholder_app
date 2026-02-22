import 'dart:convert';

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ArmLayoutConfig {
  static ArmLayoutConfig instance = ArmLayoutConfig();

  // 上腕
  Vector2 upperArmPosition;
  Vector2 upperArmSize;

  // 前腕
  Vector2 foreArmPosition;
  Vector2 foreArmSize;

  // 肩
  Vector2 shoulderPosition;
  Vector2 shoulderSize;

  // ジョイント
  Vector2 shoulderAnchorA;
  Vector2 shoulderAnchorB;
  Vector2 elbowAnchorA;
  Vector2 elbowAnchorB;

  // 先端
  Vector2 tipOffset;
  double armTipLocalY;

  ArmLayoutConfig({
    Vector2? upperArmPosition,
    Vector2? upperArmSize,
    Vector2? foreArmPosition,
    Vector2? foreArmSize,
    Vector2? shoulderPosition,
    Vector2? shoulderSize,
    Vector2? shoulderAnchorA,
    Vector2? shoulderAnchorB,
    Vector2? elbowAnchorA,
    Vector2? elbowAnchorB,
    Vector2? tipOffset,
    double? armTipLocalY,
  })  : upperArmPosition = upperArmPosition ?? Vector2(-10, -4),
        upperArmSize = upperArmSize ?? Vector2(4.35, 8),
        foreArmPosition = foreArmPosition ?? Vector2(-8.5, 1.5),
        foreArmSize = foreArmSize ?? Vector2(4.85, 8),
        shoulderPosition = shoulderPosition ?? Vector2(-12, 0),
        shoulderSize = shoulderSize ?? Vector2(16, 16),
        shoulderAnchorA = shoulderAnchorA ?? Vector2(6, -4.5),
        shoulderAnchorB = shoulderAnchorB ?? Vector2(0, -4),
        elbowAnchorA = elbowAnchorA ?? Vector2(1.75, 3),
        elbowAnchorB = elbowAnchorB ?? Vector2(-1, -3.5),
        tipOffset = tipOffset ?? Vector2(2.0, 3.5),
        armTipLocalY = armTipLocalY ?? 3.5;

  static Vector2? _parseVector2(Map<String, dynamic>? json) {
    if (json == null) return null;
    return Vector2(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
    );
  }

  factory ArmLayoutConfig.fromJson(Map<String, dynamic> json) {
    final joints = json['joints'] as Map<String, dynamic>?;
    final shoulderJoint = joints?['shoulder'] as Map<String, dynamic>?;
    final elbowJoint = joints?['elbow'] as Map<String, dynamic>?;

    return ArmLayoutConfig(
      upperArmPosition: _parseVector2(
          (json['upperArm'] as Map<String, dynamic>?)?['position']
              as Map<String, dynamic>?),
      upperArmSize: _parseVector2(
          (json['upperArm'] as Map<String, dynamic>?)?['size']
              as Map<String, dynamic>?),
      foreArmPosition: _parseVector2(
          (json['foreArm'] as Map<String, dynamic>?)?['position']
              as Map<String, dynamic>?),
      foreArmSize: _parseVector2(
          (json['foreArm'] as Map<String, dynamic>?)?['size']
              as Map<String, dynamic>?),
      shoulderPosition: _parseVector2(
          (json['shoulder'] as Map<String, dynamic>?)?['position']
              as Map<String, dynamic>?),
      shoulderSize: _parseVector2(
          (json['shoulder'] as Map<String, dynamic>?)?['size']
              as Map<String, dynamic>?),
      shoulderAnchorA:
          _parseVector2(shoulderJoint?['anchorA'] as Map<String, dynamic>?),
      shoulderAnchorB:
          _parseVector2(shoulderJoint?['anchorB'] as Map<String, dynamic>?),
      elbowAnchorA:
          _parseVector2(elbowJoint?['anchorA'] as Map<String, dynamic>?),
      elbowAnchorB:
          _parseVector2(elbowJoint?['anchorB'] as Map<String, dynamic>?),
      tipOffset: _parseVector2(json['tipOffset'] as Map<String, dynamic>?),
      armTipLocalY: (json['armTipLocalY'] as num?)?.toDouble(),
    );
  }

  static Future<ArmLayoutConfig> loadFromAsset() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/arm_layout.json');
      instance = ArmLayoutConfig.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('Failed to load arm_layout.json, using defaults: $e');
      instance = ArmLayoutConfig();
    }
    return instance;
  }
}
