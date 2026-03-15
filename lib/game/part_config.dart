class PartConfig {
  final double positionX;
  final double positionY;
  final double sizeX;
  final double sizeY;

  const PartConfig({
    required this.positionX,
    required this.positionY,
    required this.sizeX,
    required this.sizeY,
  });

  factory PartConfig.fromJson(Map<String, dynamic> json) {
    final position = json['position'] as Map<String, dynamic>;
    final size = json['size'] as Map<String, dynamic>;
    return PartConfig(
      positionX: (position['x'] as num).toDouble(),
      positionY: (position['y'] as num).toDouble(),
      sizeX: (size['x'] as num).toDouble(),
      sizeY: (size['y'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'position': {'x': positionX, 'y': positionY},
    'size': {'x': sizeX, 'y': sizeY},
  };

  PartConfig copyWith({
    double? positionX,
    double? positionY,
    double? sizeX,
    double? sizeY,
  }) {
    return PartConfig(
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      sizeX: sizeX ?? this.sizeX,
      sizeY: sizeY ?? this.sizeY,
    );
  }
}
