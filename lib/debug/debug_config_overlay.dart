import 'dart:convert';

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/arm_layout_config.dart';
import '../game/enemy_config.dart';
import '../game/joint_config.dart';
import '../game/part_config.dart';
import '../game/game_config.dart';
import '../game/hp_bar_config.dart';

enum _HpOwner {
  enemy('enemy', '敵');

  final String prefix;
  final String displayName;
  const _HpOwner(this.prefix, this.displayName);
}

class _FieldMeta {
  final String label;
  final String displayName;
  final List<double> steps;
  final double value;
  final ValueChanged<double> onChanged;

  const _FieldMeta({
    required this.label,
    required this.displayName,
    required this.steps,
    required this.value,
    required this.onChanged,
  });
}

class DebugConfigOverlay extends StatefulWidget {
  final GameConfig initialConfig;
  final ArmLayoutConfig initialLayout;
  final EnemyConfig initialEnemyConfig;
  final HpBarConfig initialEnemyHpConfig;
  final ValueChanged<GameConfig> onConfigChanged;
  final ValueChanged<ArmLayoutConfig> onLayoutChanged;
  final ValueChanged<EnemyConfig> onEnemyConfigChanged;
  final ValueChanged<HpBarConfig> onEnemyHpConfigChanged;
  final VoidCallback onClose;

  const DebugConfigOverlay({
    super.key,
    required this.initialConfig,
    required this.initialLayout,
    required this.initialEnemyConfig,
    required this.initialEnemyHpConfig,
    required this.onConfigChanged,
    required this.onLayoutChanged,
    required this.onEnemyConfigChanged,
    required this.onEnemyHpConfigChanged,
    required this.onClose,
  });

  @override
  State<DebugConfigOverlay> createState() => _DebugConfigOverlayState();
}

class _DebugConfigOverlayState extends State<DebugConfigOverlay>
    with SingleTickerProviderStateMixin {
  late GameConfig _config = widget.initialConfig;
  late ArmLayoutConfig _layout = widget.initialLayout;
  late EnemyConfig _enemyConfig = widget.initialEnemyConfig;
  late HpBarConfig _enemyHpConfig = widget.initialEnemyHpConfig;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateConfig(GameConfig Function(GameConfig) updater) {
    setState(() => _config = updater(_config));
    widget.onConfigChanged(_config);
  }

  void _updateLayout(ArmLayoutConfig Function(ArmLayoutConfig) updater) {
    setState(() => _layout = updater(_layout));
    widget.onLayoutChanged(_layout);
  }

  void _updateEnemyConfig(EnemyConfig Function(EnemyConfig) updater) {
    setState(() => _enemyConfig = updater(_enemyConfig));
    widget.onEnemyConfigChanged(_enemyConfig);
  }

  void _updateEnemyHpConfig(HpBarConfig Function(HpBarConfig) updater) {
    setState(() => _enemyHpConfig = updater(_enemyHpConfig));
    widget.onEnemyHpConfigChanged(_enemyHpConfig);
  }

  Future<void> _export() async {
    final allJson = <String, dynamic>{
      'gameConfig': _config.toJson(),
      'armLayout': _layout.toJson(),
      'enemyConfig': _enemyConfig.toJson(),
      'enemyHpConfig': _enemyHpConfig.toJson(),
    };
    final json = const JsonEncoder.withIndent('  ').convert(allJson);
    await Clipboard.setData(ClipboardData(text: json));
    if (mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('JSONをクリップボードにコピーしました'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _reset() {
    final defaultConfig = GameConfig.defaultConfig();
    final defaultLayout = ArmLayoutConfig();
    final defaultEnemyConfig = EnemyConfig();
    final defaultHpConfig = HpBarConfig();
    setState(() {
      _config = defaultConfig;
      _layout = defaultLayout;
      _enemyConfig = defaultEnemyConfig;
      _enemyHpConfig = defaultHpConfig;
    });
    widget.onConfigChanged(defaultConfig);
    widget.onLayoutChanged(defaultLayout);
    widget.onEnemyConfigChanged(defaultEnemyConfig);
    widget.onEnemyHpConfigChanged(defaultHpConfig);
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      width: 360,
      child: Material(
        color: Colors.black.withValues(alpha: 0.85),
        child: Column(
          children: [
            _ConfigHeader(
              onReset: _reset,
              onExport: _export,
              onClose: widget.onClose,
            ),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Game'),
                Tab(text: 'Layout'),
                Tab(text: 'HP'),
              ],
              labelColor: Colors.cyanAccent,
              unselectedLabelColor: Colors.white54,
              indicatorColor: Colors.cyanAccent,
              labelStyle: const TextStyle(fontSize: 12),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildGameTab(), _buildLayoutTab(), _buildHpTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_FieldMeta> _gameConfigFields() => [
    _FieldMeta(
      label: 'gravity.y',
      displayName: '重力Y',
      steps: const [0.5, 5, 50],
      value: _config.gravity.y,
      onChanged: (v) =>
          _updateConfig((c) => c.copyWith(gravity: Vector2(c.gravity.x, v))),
    ),
    _FieldMeta(
      label: 'zoom',
      displayName: 'ズーム',
      steps: const [0.5, 5, 50],
      value: _config.zoom,
      onChanged: (v) => _updateConfig((c) => c.copyWith(zoom: v)),
    ),
    _FieldMeta(
      label: 'shoulderTorque',
      displayName: '肩トルク',
      steps: const [500, 5000],
      value: _config.shoulderTorque,
      onChanged: (v) => _updateConfig((c) => c.copyWith(shoulderTorque: v)),
    ),
    _FieldMeta(
      label: 'elbowTorque',
      displayName: '肘トルク',
      steps: const [500, 5000],
      value: _config.elbowTorque,
      onChanged: (v) => _updateConfig((c) => c.copyWith(elbowTorque: v)),
    ),
    _FieldMeta(
      label: 'armLength',
      displayName: '腕の長さ',
      steps: const [0.5, 5],
      value: _config.armLength,
      onChanged: (v) => _updateConfig((c) => c.copyWith(armLength: v)),
    ),
    _FieldMeta(
      label: 'tipRadius',
      displayName: '先端半径',
      steps: const [0.1, 0.5],
      value: _config.tipRadius,
      onChanged: (v) => _updateConfig((c) => c.copyWith(tipRadius: v)),
    ),
    _FieldMeta(
      label: 'enemyRadius',
      displayName: '敵半径',
      steps: const [0.5, 5],
      value: _config.enemyRadius,
      onChanged: (v) => _updateConfig((c) => c.copyWith(enemyRadius: v)),
    ),
    _FieldMeta(
      label: 'straighteningDuration',
      displayName: '伸ばし時間',
      steps: const [0.05, 0.5],
      value: _config.straighteningDuration,
      onChanged: (v) =>
          _updateConfig((c) => c.copyWith(straighteningDuration: v)),
    ),
    _FieldMeta(
      label: 'randomChangeInterval',
      displayName: 'ランダム間隔',
      steps: const [0.05, 0.5],
      value: _config.randomChangeInterval,
      onChanged: (v) =>
          _updateConfig((c) => c.copyWith(randomChangeInterval: v)),
    ),
    _FieldMeta(
      label: 'shoulderSpeedRange',
      displayName: '肩速度範囲',
      steps: const [1, 5],
      value: _config.shoulderSpeedRange,
      onChanged: (v) => _updateConfig((c) => c.copyWith(shoulderSpeedRange: v)),
    ),
    _FieldMeta(
      label: 'elbowSpeedRange',
      displayName: '肘速度範囲',
      steps: const [1, 5],
      value: _config.elbowSpeedRange,
      onChanged: (v) => _updateConfig((c) => c.copyWith(elbowSpeedRange: v)),
    ),
    _FieldMeta(
      label: 'spriteScale',
      displayName: '敵スプライト倍率',
      steps: const [0.1, 0.5],
      value: _enemyConfig.spriteScale,
      onChanged: (v) => _updateEnemyConfig((c) => c.copyWith(spriteScale: v)),
    ),
  ];

  Widget _buildGameTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: _gameConfigFields()
          .map(
            (f) => _ConfigStepperTile(
              label: f.label,
              displayName: f.displayName,
              value: f.value,
              steps: f.steps,
              onChanged: f.onChanged,
            ),
          )
          .toList(),
    );
  }

  List<Widget> _partSteppers(
    String label,
    String displayName,
    PartConfig part,
    void Function(PartConfig) onChanged,
  ) {
    return [
      _ConfigStepperTile(
        label: '$label.posX',
        displayName: '$displayName.位置X',
        value: part.positionX,
        steps: const [0.5, 5],
        onChanged: (v) => onChanged(part.copyWith(positionX: v)),
      ),
      _ConfigStepperTile(
        label: '$label.posY',
        displayName: '$displayName.位置Y',
        value: part.positionY,
        steps: const [0.5, 5],
        onChanged: (v) => onChanged(part.copyWith(positionY: v)),
      ),
      _ConfigStepperTile(
        label: '$label.sizeX',
        displayName: '$displayName.幅',
        value: part.sizeX,
        steps: const [0.5, 5],
        onChanged: (v) => onChanged(part.copyWith(sizeX: v)),
      ),
      _ConfigStepperTile(
        label: '$label.sizeY',
        displayName: '$displayName.高さ',
        value: part.sizeY,
        steps: const [0.5, 5],
        onChanged: (v) => onChanged(part.copyWith(sizeY: v)),
      ),
    ];
  }

  List<Widget> _jointSteppers(
    String label,
    String displayName,
    JointConfig joint,
    void Function(JointConfig) onChanged,
  ) {
    return [
      _ConfigStepperTile(
        label: '$label.anchorAX',
        displayName: '$displayName.接続A-X',
        value: joint.anchorAX,
        steps: const [0.5, 5],
        onChanged: (v) => onChanged(joint.copyWith(anchorAX: v)),
      ),
      _ConfigStepperTile(
        label: '$label.anchorAY',
        displayName: '$displayName.接続A-Y',
        value: joint.anchorAY,
        steps: const [0.5, 5],
        onChanged: (v) => onChanged(joint.copyWith(anchorAY: v)),
      ),
      _ConfigStepperTile(
        label: '$label.anchorBX',
        displayName: '$displayName.接続B-X',
        value: joint.anchorBX,
        steps: const [0.5, 5],
        onChanged: (v) => onChanged(joint.copyWith(anchorBX: v)),
      ),
      _ConfigStepperTile(
        label: '$label.anchorBY',
        displayName: '$displayName.接続B-Y',
        value: joint.anchorBY,
        steps: const [0.5, 5],
        onChanged: (v) => onChanged(joint.copyWith(anchorBY: v)),
      ),
    ];
  }

  Widget _buildLayoutTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        _sectionHeader('上腕'),
        ..._partSteppers(
          'upperArm',
          '上腕',
          _layout.upperArm,
          (p) => _updateLayout((l) => l.copyWith(upperArm: p)),
        ),
        _sectionHeader('前腕'),
        ..._partSteppers(
          'foreArm',
          '前腕',
          _layout.foreArm,
          (p) => _updateLayout((l) => l.copyWith(foreArm: p)),
        ),
        _sectionHeader('肩'),
        ..._partSteppers(
          'shoulder',
          '肩',
          _layout.shoulder,
          (p) => _updateLayout((l) => l.copyWith(shoulder: p)),
        ),
        _sectionHeader('肩関節'),
        ..._jointSteppers(
          'shoulderJoint',
          '肩関節',
          _layout.shoulderJoint,
          (j) => _updateLayout((l) => l.copyWith(shoulderJoint: j)),
        ),
        _sectionHeader('肘関節'),
        ..._jointSteppers(
          'elbowJoint',
          '肘関節',
          _layout.elbowJoint,
          (j) => _updateLayout((l) => l.copyWith(elbowJoint: j)),
        ),
        _sectionHeader('先端'),
        _ConfigStepperTile(
          label: 'tipOffsetX',
          displayName: '先端オフセットX',
          value: _layout.tipOffsetX,
          steps: const [0.5, 5],
          onChanged: (v) => _updateLayout((l) => l.copyWith(tipOffsetX: v)),
        ),
        _ConfigStepperTile(
          label: 'tipOffsetY',
          displayName: '先端オフセットY',
          value: _layout.tipOffsetY,
          steps: const [0.5, 5],
          onChanged: (v) => _updateLayout((l) => l.copyWith(tipOffsetY: v)),
        ),
        _ConfigStepperTile(
          label: 'armTipLocalY',
          displayName: '先端ローカルY',
          value: _layout.armTipLocalY,
          steps: const [0.5, 5],
          onChanged: (v) => _updateLayout((l) => l.copyWith(armTipLocalY: v)),
        ),
      ],
    );
  }

  List<_FieldMeta> _hpConfigFields({
    required _HpOwner owner,
    required HpBarConfig config,
    required void Function(HpBarConfig Function(HpBarConfig)) onUpdate,
  }) => [
    _FieldMeta(
      label: '${owner.prefix}.maxHp',
      displayName: '${owner.displayName}.最大HP',
      steps: const [5, 50],
      value: config.maxHp,
      onChanged: (v) => onUpdate((c) => c.copyWith(maxHp: v)),
    ),
    _FieldMeta(
      label: '${owner.prefix}.barPosX',
      displayName: '${owner.displayName}.バー位置X',
      steps: const [0.5, 5],
      value: config.barPositionX,
      onChanged: (v) => onUpdate((c) => c.copyWith(barPositionX: v)),
    ),
    _FieldMeta(
      label: '${owner.prefix}.barPosY',
      displayName: '${owner.displayName}.バー位置Y',
      steps: const [0.5, 5],
      value: config.barPositionY,
      onChanged: (v) => onUpdate((c) => c.copyWith(barPositionY: v)),
    ),
    _FieldMeta(
      label: '${owner.prefix}.barSizeX',
      displayName: '${owner.displayName}.バー幅',
      steps: const [5, 50],
      value: config.barSizeX,
      onChanged: (v) => onUpdate((c) => c.copyWith(barSizeX: v)),
    ),
    _FieldMeta(
      label: '${owner.prefix}.barSizeY',
      displayName: '${owner.displayName}.バー高さ',
      steps: const [1, 5],
      value: config.barSizeY,
      onChanged: (v) => onUpdate((c) => c.copyWith(barSizeY: v)),
    ),
  ];

  Widget _buildHpTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        _sectionHeader('敵HP'),
        ..._hpConfigFields(
          owner: _HpOwner.enemy,
          config: _enemyHpConfig,
          onUpdate: _updateEnemyHpConfig,
        ).map(
          (f) => _ConfigStepperTile(
            label: f.label,
            displayName: f.displayName,
            value: f.value,
            steps: f.steps,
            onChanged: f.onChanged,
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.cyanAccent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ConfigHeader extends StatelessWidget {
  final VoidCallback onReset;
  final VoidCallback onExport;
  final VoidCallback onClose;

  const _ConfigHeader({
    required this.onReset,
    required this.onExport,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          const Text(
            'Config',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.restart_alt, color: Colors.orange, size: 20),
            onPressed: onReset,
            tooltip: 'Reset',
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.cyan, size: 20),
            onPressed: onExport,
            tooltip: 'Export JSON',
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _ConfigStepperTile extends StatelessWidget {
  final String label;
  final String displayName;
  final double value;
  final List<double> steps;
  final ValueChanged<double> onChanged;

  const _ConfigStepperTile({
    required this.label,
    required this.displayName,
    required this.value,
    required this.steps,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              displayName,
              style: const TextStyle(color: Colors.white70, fontSize: 9),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final step in steps.reversed)
                  _StepButton(
                    label: '-${_formatStep(step)}',
                    onTap: () => onChanged(value - step),
                  ),
                Container(
                  width: 46,
                  alignment: Alignment.center,
                  child: Text(
                    _formatValue(value),
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 10,
                    ),
                  ),
                ),
                for (final step in steps)
                  _StepButton(
                    label: '+${_formatStep(step)}',
                    onTap: () => onChanged(value + step),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatStep(double step) {
    if (step >= 1000) return '${(step / 1000).toStringAsFixed(0)}k';
    if (step == step.roundToDouble()) return step.toInt().toString();
    return step.toString();
  }

  String _formatValue(double v) {
    if (v.abs() >= 100) return v.toStringAsFixed(0);
    if (v.abs() >= 10) return v.toStringAsFixed(1);
    return v.toStringAsFixed(2);
  }
}

class _StepButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _StepButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 8),
        ),
      ),
    );
  }
}
