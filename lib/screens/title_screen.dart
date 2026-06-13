import 'dart:async';

import 'package:flutter/material.dart';

import '../interfaces/ble_service.dart';
import '../models/ble_device_role.dart';
import '../widgets/connect_button.dart';
import '../widgets/start_button.dart';

enum _ConnectionUiState { idle, connecting, connected, disconnecting }

class TitleScreen extends StatefulWidget {
  final VoidCallback onStart;
  final BleService bleService;

  const TitleScreen({
    super.key,
    required this.onStart,
    required this.bleService,
  });

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  BleService get _bleService => widget.bleService;

  _ConnectionUiState _blueState = _ConnectionUiState.idle;
  _ConnectionUiState _redState = _ConnectionUiState.idle;

  StreamSubscription<Set<BleDeviceRole>>? _rolesSub;

  @override
  void initState() {
    super.initState();

    final connectedRoles = _bleService.connectedRoles;
    _blueState = connectedRoles.contains(BleDeviceRole.blue)
        ? _ConnectionUiState.connected
        : _ConnectionUiState.idle;
    _redState = connectedRoles.contains(BleDeviceRole.red)
        ? _ConnectionUiState.connected
        : _ConnectionUiState.idle;

    _rolesSub = _bleService.connectedRolesStream.listen((roles) {
      if (!mounted) return;
      setState(() {
        if (roles.contains(BleDeviceRole.blue)) {
          _blueState = _ConnectionUiState.connected;
        } else if (_blueState == _ConnectionUiState.connected) {
          _blueState = _ConnectionUiState.idle;
        }
        if (roles.contains(BleDeviceRole.red)) {
          _redState = _ConnectionUiState.connected;
        } else if (_redState == _ConnectionUiState.connected) {
          _redState = _ConnectionUiState.idle;
        }
      });
    });
  }

  void _setStateFor(BleDeviceRole role, _ConnectionUiState state) {
    setState(() {
      if (role == BleDeviceRole.blue) {
        _blueState = state;
      } else {
        _redState = state;
      }
    });
  }

  Future<void> _connect(BleDeviceRole role) async {
    _setStateFor(role, _ConnectionUiState.connecting);

    try {
      await _bleService.connectDevice(role);
      _setStateFor(role, _ConnectionUiState.connected);
    } catch (e) {
      debugPrint('接続エラー: $e');
      _setStateFor(role, _ConnectionUiState.idle);
    }
  }

  Future<void> _disconnect(BleDeviceRole role) async {
    _setStateFor(role, _ConnectionUiState.disconnecting);

    try {
      await _bleService.disconnectDevice(role);
    } catch (e) {
      debugPrint('切断エラー: $e');
    }

    _setStateFor(role, _ConnectionUiState.idle);
  }

  String _labelFor(_ConnectionUiState state) {
    switch (state) {
      case _ConnectionUiState.idle:
        return '接続';
      case _ConnectionUiState.connecting:
        return '接続中...';
      case _ConnectionUiState.connected:
        return '切断';
      case _ConnectionUiState.disconnecting:
        return '切断中...';
    }
  }

  bool _isDisabled(_ConnectionUiState state) {
    return state == _ConnectionUiState.connecting ||
        state == _ConnectionUiState.disconnecting;
  }

  VoidCallback? _onTapFor(BleDeviceRole role, _ConnectionUiState state) {
    switch (state) {
      case _ConnectionUiState.idle:
        return () => _connect(role);
      case _ConnectionUiState.connected:
        return () => _disconnect(role);
      case _ConnectionUiState.connecting:
      case _ConnectionUiState.disconnecting:
        return null;
    }
  }

  bool get _canStart =>
      _blueState == _ConnectionUiState.connected &&
      _redState == _ConnectionUiState.connected;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/title_screen_background.png',
            fit: BoxFit.cover,
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/title.png',
                width: 500,
                height: 230,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Text(
                    'ROBOT ARM',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.blueAccent,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                  );
                },
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ConnectButton(
                      label: _labelFor(_blueState),
                      color: ConnectButtonColor.blue,
                      disabled: _isDisabled(_blueState),
                      onTap: _onTapFor(BleDeviceRole.blue, _blueState),
                    ),
                    StartButton(
                      label: '出動',
                      disabled: !_canStart,
                      onTap: widget.onStart,
                    ),
                    ConnectButton(
                      label: _labelFor(_redState),
                      color: ConnectButtonColor.red,
                      disabled: _isDisabled(_redState),
                      onTap: _onTapFor(BleDeviceRole.red, _redState),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _rolesSub?.cancel();
    super.dispose();
  }
}
