import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

mixin AssetLoadable {
  static Future<T> loadFromAsset<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson,
    T Function() defaultFactory,
  ) async {
    try {
      final json = await rootBundle.loadString(path);
      return fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Failed to load $path: $e');
      return defaultFactory();
    }
  }
}
