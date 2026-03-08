import 'dart:convert';

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/game_config.dart';

/// デバッグ用のゲーム設定オーバーレイ。
/// [Stack] の子として配置すること。リリースビルドでは非表示。
class DebugConfigOverlay extends StatefulWidget {
  final GameConfig initialConfig;
  final ValueChanged<GameConfig> onConfigChanged;
  final VoidCallback onClose;

  const DebugConfigOverlay({
    super.key,
    required this.initialConfig,
    required this.onConfigChanged,
    required this.onClose,
  });

  @override
  State<DebugConfigOverlay> createState() => _DebugConfigOverlayState();
}

class _DebugConfigOverlayState extends State<DebugConfigOverlay> {
  late GameConfig _config = widget.initialConfig;

  void _updateConfig(GameConfig Function(GameConfig) updater) {
    setState(() {
      _config = updater(_config);
    });
    widget.onConfigChanged(_config);
  }

  Future<void> _export() async {
    final json = const JsonEncoder.withIndent('  ').convert(_config.toJson());
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
    setState(() {
      _config = defaultConfig;
    });
    widget.onConfigChanged(defaultConfig);
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      width: 320,
      child: Material(
        color: Colors.black.withValues(alpha: 0.85),
        child: Column(
          children: [
            _ConfigHeader(
              onReset: _reset,
              onExport: _export,
              onClose: widget.onClose,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _ConfigSliderTile(
                    label: 'gravity.y',
                    value: _config.gravity.y,
                    min: 0,
                    max: 50,
                    step: 0.5,
                    onChanged: (v) => _updateConfig(
                      (c) => c.copyWith(gravity: Vector2(c.gravity.x, v)),
                    ),
                  ),
                  _ConfigSliderTile(
                    label: 'zoom',
                    value: _config.zoom,
                    min: 5,
                    max: 50,
                    step: 1,
                    onChanged: (v) => _updateConfig((c) => c.copyWith(zoom: v)),
                  ),
                  _ConfigSliderTile(
                    label: 'shoulderTorque',
                    value: _config.shoulderTorque,
                    min: 1000,
                    max: 30000,
                    step: 500,
                    onChanged: (v) =>
                        _updateConfig((c) => c.copyWith(shoulderTorque: v)),
                  ),
                  _ConfigSliderTile(
                    label: 'elbowTorque',
                    value: _config.elbowTorque,
                    min: 1000,
                    max: 50000,
                    step: 500,
                    onChanged: (v) =>
                        _updateConfig((c) => c.copyWith(elbowTorque: v)),
                  ),
                  _ConfigSliderTile(
                    label: 'armLength',
                    value: _config.armLength,
                    min: 5,
                    max: 30,
                    step: 0.5,
                    onChanged: (v) =>
                        _updateConfig((c) => c.copyWith(armLength: v)),
                  ),
                  _ConfigSliderTile(
                    label: 'tipRadius',
                    value: _config.tipRadius,
                    min: 0.1,
                    max: 3.0,
                    step: 0.1,
                    onChanged: (v) =>
                        _updateConfig((c) => c.copyWith(tipRadius: v)),
                  ),
                  _ConfigSliderTile(
                    label: 'enemyRadius',
                    value: _config.enemyRadius,
                    min: 1,
                    max: 15,
                    step: 0.5,
                    onChanged: (v) =>
                        _updateConfig((c) => c.copyWith(enemyRadius: v)),
                  ),
                  _ConfigSliderTile(
                    label: 'straighteningDuration',
                    value: _config.straighteningDuration,
                    min: 0.05,
                    max: 1.0,
                    step: 0.05,
                    onChanged: (v) => _updateConfig(
                      (c) => c.copyWith(straighteningDuration: v),
                    ),
                  ),
                  _ConfigSliderTile(
                    label: 'randomChangeInterval',
                    value: _config.randomChangeInterval,
                    min: 0.1,
                    max: 2.0,
                    step: 0.05,
                    onChanged: (v) => _updateConfig(
                      (c) => c.copyWith(randomChangeInterval: v),
                    ),
                  ),
                  _ConfigSliderTile(
                    label: 'shoulderSpeedRange',
                    value: _config.shoulderSpeedRange,
                    min: 5,
                    max: 60,
                    step: 1,
                    onChanged: (v) =>
                        _updateConfig((c) => c.copyWith(shoulderSpeedRange: v)),
                  ),
                  _ConfigSliderTile(
                    label: 'elbowSpeedRange',
                    value: _config.elbowSpeedRange,
                    min: 5,
                    max: 80,
                    step: 1,
                    onChanged: (v) =>
                        _updateConfig((c) => c.copyWith(elbowSpeedRange: v)),
                  ),
                ],
              ),
            ),
          ],
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

class _ConfigSliderTile extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;

  const _ConfigSliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final divisions = ((max - min) / step).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
              Text(
                value.toStringAsFixed(step < 1 ? 2 : 0),
                style: const TextStyle(color: Colors.cyanAccent, fontSize: 11),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: Colors.cyanAccent,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.cyan,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
