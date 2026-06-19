import '../interfaces/json_exportable.dart';

class PartConfig implements JsonExportable {
  final double positionX;
  final double positionY;
  final double sizeX;
  final double sizeY;
  final double? imageAnchorX;
  final double? imageAnchorY;

  const PartConfig({
    required this.positionX,
    required this.positionY,
    required this.sizeX,
    required this.sizeY,
    this.imageAnchorX,
    this.imageAnchorY,
  });

  factory PartConfig.fromJson(Map<String, dynamic> json) {
    final position = json['position'] as Map<String, dynamic>;
    final size = json['size'] as Map<String, dynamic>;
    final imageAnchor = json['imageAnchor'] as Map<String, dynamic>?;
    return PartConfig(
      positionX: (position['x'] as num).toDouble(),
      positionY: (position['y'] as num).toDouble(),
      sizeX: (size['x'] as num).toDouble(),
      sizeY: (size['y'] as num).toDouble(),
      imageAnchorX: (imageAnchor?['x'] as num?)?.toDouble(),
      imageAnchorY: (imageAnchor?['y'] as num?)?.toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'position': {'x': positionX, 'y': positionY},
      'size': {'x': sizeX, 'y': sizeY},
    };
    if (imageAnchorX != null && imageAnchorY != null) {
      map['imageAnchor'] = {'x': imageAnchorX, 'y': imageAnchorY};
    }
    return map;
  }

  PartConfig copyWith({
    double? positionX,
    double? positionY,
    double? sizeX,
    double? sizeY,
    double? imageAnchorX,
    double? imageAnchorY,
  }) {
    return PartConfig(
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      sizeX: sizeX ?? this.sizeX,
      sizeY: sizeY ?? this.sizeY,
      imageAnchorX: imageAnchorX ?? this.imageAnchorX,
      imageAnchorY: imageAnchorY ?? this.imageAnchorY,
    );
  }
}
