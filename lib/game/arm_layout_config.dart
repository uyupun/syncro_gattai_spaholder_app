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

  ArmLayoutConfig({
    PartConfig? upperArm,
    PartConfig? foreArm,
    PartConfig? shoulder,
    JointConfig? shoulderJoint,
    JointConfig? elbowJoint,
    double? tipOffsetX,
    double? tipOffsetY,
    double? armTipLocalY,
  }) : upperArm =
           upperArm ??
           const PartConfig(
             positionX: -10,
             positionY: -4,
             sizeX: 4.35,
             sizeY: 8,
           ),
       foreArm =
           foreArm ??
           const PartConfig(
             positionX: -8.5,
             positionY: 1.5,
             sizeX: 4.85,
             sizeY: 8,
           ),
       shoulder =
           shoulder ??
           const PartConfig(positionX: -12, positionY: 0, sizeX: 16, sizeY: 16),
       shoulderJoint =
           shoulderJoint ??
           const JointConfig(
             anchorAX: 6,
             anchorAY: -4.5,
             anchorBX: 0,
             anchorBY: -4,
           ),
       elbowJoint =
           elbowJoint ??
           const JointConfig(
             anchorAX: 1.75,
             anchorAY: 3,
             anchorBX: -1,
             anchorBY: -3.5,
           ),
       tipOffsetX = tipOffsetX ?? 2.0,
       tipOffsetY = tipOffsetY ?? 3.5,
       armTipLocalY = armTipLocalY ?? 3.5;

  factory ArmLayoutConfig.fromJson(Map<String, dynamic> json) {
    final upperArmJson = json['upperArm'] as Map<String, dynamic>?;
    final foreArmJson = json['foreArm'] as Map<String, dynamic>?;
    final shoulderJson = json['shoulder'] as Map<String, dynamic>?;
    final joints = json['joints'] as Map<String, dynamic>?;
    final shoulderJointJson = joints?['shoulder'] as Map<String, dynamic>?;
    final elbowJointJson = joints?['elbow'] as Map<String, dynamic>?;
    final tipOffsetJson = json['tipOffset'] as Map<String, dynamic>?;

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
