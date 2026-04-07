import 'package:flutter_test/flutter_test.dart';
import 'package:spajam2025_app/interfaces/json_exportable.dart';

class _TestExportable implements JsonExportable {
  final String name;
  _TestExportable(this.name);

  @override
  Map<String, dynamic> toJson() => {'name': name};
}

void main() {
  group('JsonExportable', () {
    test('toJsonでMapを返す', () {
      final exportable = _TestExportable('test');
      final json = exportable.toJson();
      expect(json, {'name': 'test'});
    });
  });
}
