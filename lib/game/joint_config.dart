class JointConfig {
  final double anchorAX;
  final double anchorAY;
  final double anchorBX;
  final double anchorBY;

  const JointConfig({
    required this.anchorAX,
    required this.anchorAY,
    required this.anchorBX,
    required this.anchorBY,
  });

  factory JointConfig.fromJson(Map<String, dynamic> json) {
    final anchorA = json['anchorA'] as Map<String, dynamic>;
    final anchorB = json['anchorB'] as Map<String, dynamic>;
    return JointConfig(
      anchorAX: (anchorA['x'] as num).toDouble(),
      anchorAY: (anchorA['y'] as num).toDouble(),
      anchorBX: (anchorB['x'] as num).toDouble(),
      anchorBY: (anchorB['y'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'anchorA': {'x': anchorAX, 'y': anchorAY},
    'anchorB': {'x': anchorBX, 'y': anchorBY},
  };

  JointConfig copyWith({
    double? anchorAX,
    double? anchorAY,
    double? anchorBX,
    double? anchorBY,
  }) {
    return JointConfig(
      anchorAX: anchorAX ?? this.anchorAX,
      anchorAY: anchorAY ?? this.anchorAY,
      anchorBX: anchorBX ?? this.anchorBX,
      anchorBY: anchorBY ?? this.anchorBY,
    );
  }
}
