import 'package:flutter/material.dart';

import '../game/combat/player_action_detector.dart';

class ThresholdEditDialog extends StatefulWidget {
  const ThresholdEditDialog({super.key});

  @override
  State<ThresholdEditDialog> createState() => _ThresholdEditDialogState();
}

class _ThresholdEditDialogState extends State<ThresholdEditDialog> {
  late final TextEditingController _xController;
  late final TextEditingController _yController;
  late final TextEditingController _zController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _xController = TextEditingController(
      text: PlayerActionDetector.thresholdX.toString(),
    );
    _yController = TextEditingController(
      text: PlayerActionDetector.thresholdY.toString(),
    );
    _zController = TextEditingController(
      text: PlayerActionDetector.thresholdZ.toString(),
    );
  }

  @override
  void dispose() {
    _xController.dispose();
    _yController.dispose();
    _zController.dispose();
    super.dispose();
  }

  String? _validateDouble(String? value) {
    if (value == null || value.isEmpty) return '値を入力してください';
    if (double.tryParse(value) == null) return '数値を入力してください';
    return null;
  }

  void _apply() {
    if (!_formKey.currentState!.validate()) return;
    PlayerActionDetector.thresholdX = double.parse(_xController.text);
    PlayerActionDetector.thresholdY = double.parse(_yController.text);
    PlayerActionDetector.thresholdZ = double.parse(_zController.text);
    Navigator.of(context).pop();
  }

  void _reset() {
    setState(() {
      _xController.text = '0.77';
      _yController.text = '1.17';
      _zController.text = '1.65';
    });
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: _validateDouble,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('閾値設定'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 260,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField(label: 'X軸 (攻撃)', controller: _xController),
              _buildField(label: 'Y軸 (ガード)', controller: _yController),
              _buildField(label: 'Z軸 (チャージ)', controller: _zController),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _reset, child: const Text('リセット')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(onPressed: _apply, child: const Text('適用')),
      ],
    );
  }
}
