import '../interfaces/json_exportable.dart';
import '../mixins/asset_loadable.dart';
import 'joint_config.dart';
import 'part_config.dart';

class ArmLayoutConfig implements JsonExportable {
  final PartConfig upperArm;
  final PartConfig foreArm;
  final PartConfig shoulder;
  final JointConfig shoulderJoint;
  final JointConfig elbowJoint;
  final double tipOffsetX;
  final double tipOffsetY;
  final double armTipLocalY;
  final double imageRenderWidth;
  final double imageRenderHeight;

  ArmLayoutConfig({
    PartConfig? upperArm,
    PartConfig? foreArm,
    PartConfig? shoulder,
    JointConfig? shoulderJoint,
    JointConfig? elbowJoint,
    double? tipOffsetX,
    double? tipOffsetY,
    double? armTipLocalY,
    double? imageRenderWidth,
    double? imageRenderHeight,
  }) : upperArm =
           upperArm ??
           const PartConfig(
             positionX: -7,
             positionY: -2.54,
             sizeX: 4,
             sizeY: 8,
             imageAnchorX: 0.4449,
             imageAnchorY: 0.3203,
           ),
       foreArm =
           foreArm ??
           const PartConfig(
             positionX: -1.84,
             positionY: -3.84,
             sizeX: 4,
             sizeY: 8,
             imageAnchorX: 0.7025,
             imageAnchorY: 0.2284,
           ),
       shoulder =
           shoulder ??
           const PartConfig(
             positionX: -12,
             positionY: -2.54,
             sizeX: 8,
             sizeY: 8,
             imageAnchorX: 0.1949,
             imageAnchorY: 0.3203,
           ),
       shoulderJoint =
           shoulderJoint ??
           const JointConfig(
             anchorAX: 5,
             anchorAY: 0,
             anchorBX: 0,
             anchorBY: 0,
           ),
       elbowJoint =
           elbowJoint ??
           const JointConfig(
             anchorAX: 5.16,
             anchorAY: -1.30,
             anchorBX: 0,
             anchorBY: 0,
           ),
       tipOffsetX = tipOffsetX ?? 5.81,
       tipOffsetY = tipOffsetY ?? -2.10,
       armTipLocalY = armTipLocalY ?? -2.10,
       imageRenderWidth = imageRenderWidth ?? 20.0,
       imageRenderHeight = imageRenderHeight ?? 14.14;

  factory ArmLayoutConfig.fromJson(Map<String, dynamic> json) {
    final upperArmJson = json['upperArm'] as Map<String, dynamic>?;
    final foreArmJson = json['foreArm'] as Map<String, dynamic>?;
    final shoulderJson = json['shoulder'] as Map<String, dynamic>?;
    final joints = json['joints'] as Map<String, dynamic>?;
    final shoulderJointJson = joints?['shoulder'] as Map<String, dynamic>?;
    final elbowJointJson = joints?['elbow'] as Map<String, dynamic>?;
    final tipOffsetJson = json['tipOffset'] as Map<String, dynamic>?;
    final imageRenderSizeJson =
        json['imageRenderSize'] as Map<String, dynamic>?;

    return ArmLayoutConfig(
      upperArm: upperArmJson != null ? PartConfig.fromJson(upperArmJson) : null,
      foreArm: foreArmJson != null ? PartConfig.fromJson(foreArmJson) : null,
      shoulder: shoulderJson != null ? PartConfig.fromJson(shoulderJson) : null,
      shoulderJoint: shoulderJointJson != null
          ? JointConfig.fromJson(shoulderJointJson)
          : null,
      elbowJoint: elbowJointJson != null
          ? JointConfig.fromJson(elbowJointJson)
          : null,
      tipOffsetX: (tipOffsetJson?['x'] as num?)?.toDouble(),
      tipOffsetY: (tipOffsetJson?['y'] as num?)?.toDouble(),
      armTipLocalY: (json['armTipLocalY'] as num?)?.toDouble(),
      imageRenderWidth: (imageRenderSizeJson?['x'] as num?)?.toDouble(),
      imageRenderHeight: (imageRenderSizeJson?['y'] as num?)?.toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'upperArm': upperArm.toJson(),
    'foreArm': foreArm.toJson(),
    'shoulder': shoulder.toJson(),
    'joints': {
      'shoulder': shoulderJoint.toJson(),
      'elbow': elbowJoint.toJson(),
    },
    'tipOffset': {'x': tipOffsetX, 'y': tipOffsetY},
    'armTipLocalY': armTipLocalY,
    'imageRenderSize': {'x': imageRenderWidth, 'y': imageRenderHeight},
  };

  ArmLayoutConfig copyWith({
    PartConfig? upperArm,
    PartConfig? foreArm,
    PartConfig? shoulder,
    JointConfig? shoulderJoint,
    JointConfig? elbowJoint,
    double? tipOffsetX,
    double? tipOffsetY,
    double? armTipLocalY,
    double? imageRenderWidth,
    double? imageRenderHeight,
  }) {
    return ArmLayoutConfig(
      upperArm: upperArm ?? this.upperArm,
      foreArm: foreArm ?? this.foreArm,
      shoulder: shoulder ?? this.shoulder,
      shoulderJoint: shoulderJoint ?? this.shoulderJoint,
      elbowJoint: elbowJoint ?? this.elbowJoint,
      tipOffsetX: tipOffsetX ?? this.tipOffsetX,
      tipOffsetY: tipOffsetY ?? this.tipOffsetY,
      armTipLocalY: armTipLocalY ?? this.armTipLocalY,
      imageRenderWidth: imageRenderWidth ?? this.imageRenderWidth,
      imageRenderHeight: imageRenderHeight ?? this.imageRenderHeight,
    );
  }

  static Future<ArmLayoutConfig> loadFromAsset() async {
    return AssetLoadable.loadFromAsset<ArmLayoutConfig>(
      'assets/arm_layout.json',
      ArmLayoutConfig.fromJson,
      ArmLayoutConfig.new,
    );
  }
}
