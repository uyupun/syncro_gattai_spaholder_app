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

  Widget _buildGameTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        _ConfigStepperTile(
          label: 'gravity.y',
          value: _config.gravity.y,
          steps: const [0.5, 5, 50],
          onChanged: (v) => _updateConfig(
            (c) => c.copyWith(gravity: Vector2(c.gravity.x, v)),
          ),
        ),
        _ConfigStepperTile(
          label: 'zoom',
          value: _config.zoom,
          steps: const [0.5, 5, 50],
          onChanged: (v) => _updateConfig((c) => c.copyWith(zoom: v)),
        ),
        _ConfigStepperTile(
          label: 'shoulderTorque',
          value: _config.shoulderTorque,
          steps: const [500, 5000],
          onChanged: (v) => _updateConfig((c) => c.copyWith(shoulderTorque: v)),
        ),
        _ConfigStepperTile(
          label: 'elbowTorque',
          value: _config.elbowTorque,
          steps: const [500, 5000],
          onChanged: (v) => _updateConfig((c) => c.copyWith(elbowTorque: v)),
        ),
        _ConfigStepperTile(
          label: 'armLength',
          value: _config.armLength,
          steps: const [0.5, 5],
          onChanged: (v) => _updateConfig((c) => c.copyWith(armLength: v)),
        ),
        _ConfigStepperTile(
          label: 'tipRadius',
          value: _config.tipRadius,
          steps: const [0.1, 0.5],
          onChanged: (v) => _updateConfig((c) => c.copyWith(tipRadius: v)),
        ),
        _ConfigStepperTile(
          label: 'enemyRadius',
          value: _config.enemyRadius,
          steps: const [0.5, 5],
          onChanged: (v) => _updateConfig((c) => c.copyWith(enemyRadius: v)),
        ),
        _ConfigStepperTile(
          label: 'straighteningDuration',
          value: _config.straighteningDuration,
          steps: const [0.05, 0.5],
          onChanged: (v) =>
              _updateConfig((c) => c.copyWith(straighteningDuration: v)),
        ),
        _ConfigStepperTile(
          label: 'randomChangeInterval',
          value: _config.randomChangeInterval,
          steps: const [0.05, 0.5],
          onChanged: (v) =>
              _updateConfig((c) => c.copyWith(randomChangeInterval: v)),
        ),
        _ConfigStepperTile(
          label: 'shoulderSpeedRange',
          value: _config.shoulderSpeedRange,
          steps: const [1, 5],
          onChanged: (v) =>
              _updateConfig((c) => c.copyWith(shoulderSpeedRange: v)),
        ),
        _ConfigStepperTile(
          label: 'elbowSpeedRange',
          value: _config.elbowSpeedRange,
          steps: const [1, 5],
          onChanged: (v) =>
              _updateConfig((c) => c.copyWith(elbowSpeedRange: v)),
        ),
        _ConfigStepperTile(
          label: 'spriteScale',
          value: _enemyConfig.spriteScale,
          steps: const [0.1, 0.5],
          onChanged: (v) =>
              _updateEnemyConfig((c) => c.copyWith(spriteScale: v)),
        ),
      ],
    );
  }

  List<Widget> _partSteppers(
    String prefix,
    PartConfig part,
    void Function(PartConfig) onChanged,
  ) {
    return [
      _ConfigStepperTile(
        label: '$prefix.posX',
        value: part.positionX,
        steps: const [0.5, 5],
        onChanged: (v) => onChanged(part.copyWith(positionX: v)),
      ),
      _ConfigStepperTile(
        label: '$prefix.posY',
        value: part.positionY,
        steps: const [0.5, 5],
        onChanged: (v) => onChanged(part.copyWith(positionY: v)),
      ),
      _ConfigStepperTile(
        label: '$prefix.sizeX',
        value: part.sizeX,
        steps: const [0.5, 5],
        onChanged: (v) => onChanged(part.copyWith(sizeX: v)),
      ),
      _ConfigStepperTile(
        label: '$prefix.sizeY',
        value: part.sizeY,
        steps: const [0.5, 5],
        onChanged: (v) => onChanged(part.copyWith(sizeY: v)),
      ),
    ];
  }

  List<Widget> _jointSteppers(
    String prefix,
    JointConfig joint,
    void Function(JointConfig) onChanged,
  ) {
    return [
      _ConfigStepperTile(
        label: '$prefix.anchorAX',
        value: joint.anchorAX,
        steps: const [0.5, 5],
        onChanged: (v) => onChanged(joint.copyWith(anchorAX: v)),
      ),
      _ConfigStepperTile(
        label: '$prefix.anchorAY',
        value: joint.anchorAY,
        steps: const [0.5, 5],
        onChanged: (v) => onChanged(joint.copyWith(anchorAY: v)),
      ),
      _ConfigStepperTile(
        label: '$prefix.anchorBX',
        value: joint.anchorBX,
        steps: const [0.5, 5],
        onChanged: (v) => onChanged(joint.copyWith(anchorBX: v)),
      ),
      _ConfigStepperTile(
        label: '$prefix.anchorBY',
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
        _sectionHeader('Upper Arm'),
        ..._partSteppers(
          'upperArm',
          _layout.upperArm,
          (p) => _updateLayout((l) => l.copyWith(upperArm: p)),
        ),
        _sectionHeader('Fore Arm'),
        ..._partSteppers(
          'foreArm',
          _layout.foreArm,
          (p) => _updateLayout((l) => l.copyWith(foreArm: p)),
        ),
        _sectionHeader('Shoulder'),
        ..._partSteppers(
          'shoulder',
          _layout.shoulder,
          (p) => _updateLayout((l) => l.copyWith(shoulder: p)),
        ),
        _sectionHeader('Shoulder Joint'),
        ..._jointSteppers(
          'sJoint',
          _layout.shoulderJoint,
          (j) => _updateLayout((l) => l.copyWith(shoulderJoint: j)),
        ),
        _sectionHeader('Elbow Joint'),
        ..._jointSteppers(
          'eJoint',
          _layout.elbowJoint,
          (j) => _updateLayout((l) => l.copyWith(elbowJoint: j)),
        ),
        _sectionHeader('Tip'),
        _ConfigStepperTile(
          label: 'tipOffsetX',
          value: _layout.tipOffsetX,
          steps: const [0.5, 5],
          onChanged: (v) => _updateLayout((l) => l.copyWith(tipOffsetX: v)),
        ),
        _ConfigStepperTile(
          label: 'tipOffsetY',
          value: _layout.tipOffsetY,
          steps: const [0.5, 5],
          onChanged: (v) => _updateLayout((l) => l.copyWith(tipOffsetY: v)),
        ),
        _ConfigStepperTile(
          label: 'armTipLocalY',
          value: _layout.armTipLocalY,
          steps: const [0.5, 5],
          onChanged: (v) => _updateLayout((l) => l.copyWith(armTipLocalY: v)),
        ),
      ],
    );
  }

  Widget _buildHpTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        _sectionHeader('Enemy HP'),
        _ConfigStepperTile(
          label: 'enemy.maxHp',
          value: _enemyHpConfig.maxHp,
          steps: const [5, 50],
          onChanged: (v) => _updateEnemyHpConfig((c) => c.copyWith(maxHp: v)),
        ),
        _ConfigStepperTile(
          label: 'enemy.barPosX',
          value: _enemyHpConfig.barPositionX,
          steps: const [0.5, 5],
          onChanged: (v) =>
              _updateEnemyHpConfig((c) => c.copyWith(barPositionX: v)),
        ),
        _ConfigStepperTile(
          label: 'enemy.barPosY',
          value: _enemyHpConfig.barPositionY,
          steps: const [0.5, 5],
          onChanged: (v) =>
              _updateEnemyHpConfig((c) => c.copyWith(barPositionY: v)),
        ),
        _ConfigStepperTile(
          label: 'enemy.barSizeX',
          value: _enemyHpConfig.barSizeX,
          steps: const [5, 50],
          onChanged: (v) =>
              _updateEnemyHpConfig((c) => c.copyWith(barSizeX: v)),
        ),
        _ConfigStepperTile(
          label: 'enemy.barSizeY',
          value: _enemyHpConfig.barSizeY,
          steps: const [1, 5],
          onChanged: (v) =>
              _updateEnemyHpConfig((c) => c.copyWith(barSizeY: v)),
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
  final double value;
  final List<double> steps;
  final ValueChanged<double> onChanged;

  const _ConfigStepperTile({
    required this.label,
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
              label,
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
