import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/game_config.dart';

/// デバッグ用のゲーム設定オーバーレイ。
/// [Stack] の子として配置すること。リリースビルドでは非表示。
class DebugConfigOverlay extends StatefulWidget {
  final VoidCallback onClose;

  const DebugConfigOverlay({super.key, required this.onClose});

  @override
  State<DebugConfigOverlay> createState() => _DebugConfigOverlayState();
}

class _DebugConfigOverlayState extends State<DebugConfigOverlay> {
  GameConfig get _config => GameConfig.instance;

  void _export() {
    final json = const JsonEncoder.withIndent('  ').convert(_config.toJson());
    Clipboard.setData(ClipboardData(text: json));
    if (mounted) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('JSONをクリップボードにコピーしました'),
            duration: Duration(seconds: 2),
          ),
        );
      } catch (_) {
        // Scaffold不在の場合はクリップボードコピーのみ
      }
    }
  }

  void _reset() {
    setState(() {
      _config.reset();
    });
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
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _buildSlider('gravity.y', _config.gravity.y, 0, 50, 0.5,
                      (v) => _config.gravity.y = v),
                  _buildSlider('zoom', _config.zoom, 5, 50, 1,
                      (v) => _config.zoom = v),
                  _buildSlider(
                      'shoulderTorque',
                      _config.shoulderTorque,
                      1000,
                      30000,
                      500,
                      (v) => _config.shoulderTorque = v),
                  _buildSlider('elbowTorque', _config.elbowTorque, 1000, 50000,
                      500, (v) => _config.elbowTorque = v),
                  _buildSlider('armLength', _config.armLength, 5, 30, 0.5,
                      (v) => _config.armLength = v),
                  _buildSlider('tipRadius', _config.tipRadius, 0.1, 3.0, 0.1,
                      (v) => _config.tipRadius = v),
                  _buildSlider('enemyRadius', _config.enemyRadius, 1, 15, 0.5,
                      (v) => _config.enemyRadius = v),
                  _buildSlider(
                      'straighteningDuration',
                      _config.straighteningDuration,
                      0.05,
                      1.0,
                      0.05,
                      (v) => _config.straighteningDuration = v),
                  _buildSlider(
                      'randomChangeInterval',
                      _config.randomChangeInterval,
                      0.1,
                      2.0,
                      0.05,
                      (v) => _config.randomChangeInterval = v),
                  _buildSlider(
                      'shoulderSpeedRange',
                      _config.shoulderSpeedRange,
                      5,
                      60,
                      1,
                      (v) => _config.shoulderSpeedRange = v),
                  _buildSlider(
                      'elbowSpeedRange',
                      _config.elbowSpeedRange,
                      5,
                      80,
                      1,
                      (v) => _config.elbowSpeedRange = v),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
            onPressed: _reset,
            tooltip: 'Reset',
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.cyan, size: 20),
            onPressed: _export,
            tooltip: 'Export JSON',
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    double step,
    ValueChanged<double> onChanged,
  ) {
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
              onChanged: (v) {
                setState(() {
                  onChanged(v);
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
