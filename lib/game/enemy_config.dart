import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class EnemyConfig {
  static EnemyConfig instance = EnemyConfig();

  double spriteScale;

  EnemyConfig({
    double? spriteScale,
  }) : spriteScale = spriteScale ?? 2.5;

  factory EnemyConfig.fromJson(Map<String, dynamic> json) {
    return EnemyConfig(
      spriteScale: (json['spriteScale'] as num?)?.toDouble(),
    );
  }

  static Future<EnemyConfig> loadFromAsset() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/enemy_config.json');
      instance = EnemyConfig.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('Failed to load enemy_config.json, using defaults: $e');
      instance = EnemyConfig();
    }
    return instance;
  }
}
